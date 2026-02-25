# Design: Unity CI/CD パイプライン

## アーキテクチャ全体図

```
┌─────────────────────────────────────────────────────────────────┐
│                       Phase 1: AMI 作成 (手動)                    │
│                                                                   │
│  Engineer                                                         │
│     │                                                             │
│     │ terraform apply (ec2_base)                                  │
│     ▼                                                             │
│  EC2 Spot Instance (Ubuntu 22.04)                                 │
│  - SSM Agent                                                      │
│  - tigervnc / xfce4 (GUI)                                         │
│     │                                                             │
│     │ SSM Fleet Manager (VNC)                                     │
│     ▼                                                             │
│  GUI Desktop ─── Unity Hub ─── Unity 6000.3.9f1 インストール      │
│                                Unity ライセンス認証                 │
│     │                                                             │
│     │ AWS Console: Create Image (AMI)                             │
│     ▼                                                             │
│  AMI: unity-6000.3.9f1-licensed-YYYYMMDD                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   Phase 2: ビルドパイプライン (自動)               │
│                                                                   │
│  GitHub Repository                                                │
│     │                                                             │
│     │ Push to main / Tag push / PR merge                         │
│     ▼                                                             │
│  GitHub Actions Workflow                                          │
│     │                                                             │
│     │ aws codebuild start-build                                   │
│     ▼                                                             │
│  CodeBuild Project                                                │
│     │                                                             │
│     │ EC2 Fleet (カスタム AMI)                                    │
│     ▼                                                             │
│  EC2 Instance (from AMI)                                          │
│  - Unity 6000.3.9f1 (認証済み)                                    │
│  - buildspec.yml 実行                                             │
│     │ Unity -batchmode -buildTarget Android                       │
│     │ (例: output/build.apk)                                      │
│     │                                                             │
│     │ gh release create / upload                                  │
│     ▼                                                             │
│  GitHub Releases                                                  │
│  - v1.0.0/game.apk                                               │
└─────────────────────────────────────────────────────────────────┘
```

## フェーズ 1: EC2 AMI ビルダー詳細設計

### EC2インスタンス要件

| 項目 | 値 | 理由 |
|------|-----|------|
| OS | Ubuntu 22.04 LTS (x86_64) | Unityの公式Linuxサポート |
| インスタンスタイプ | t3.large (2vCPU, 8GB RAM) | Unity Editor の最低要件を満たす |
| ストレージ | 50GB gp3 | Unity + プロジェクト + ビルドキャッシュ |
| マーケット | Spot | コスト削減 (AMI作成用の短時間利用) |
| GUIスタック | tigervnc + xfce4 | SSM Fleet ManagerのVNCに対応 |

> **注意**: `t4g.nano` (ARM/Graviton) はUnityがサポートしていないため使用不可。
> 既存の `ec2_base` コードの修正が必要。

### GUIアクセス方法: SSM Fleet Manager

AWS Systems Manager Fleet Manager の "Remote Desktop" 機能 (Managed Instance UI) を使う。
- セキュリティグループでインバウンドルールが不要
- SSHキー管理が不要
- IAMポリシーでアクセス制御可能

**必要なIAMポリシー (EC2インスタンスロール)**:
```
AmazonSSMManagedInstanceCore
```

### 手動作業手順 (Runbook として tasks.md に記載)

1. `terraform apply` でEC2インスタンスを起動
2. AWS Console → Systems Manager → Fleet Manager → Remote Desktop で接続
3. Unity Hub をダウンロード・インストール
4. Unity 6000.3.9f1 + Android Build Support をインストール
5. Unity Hub でライセンス認証 (Personal または Pro)
6. インスタンスを停止 (Stop)
7. AWS Console → EC2 → Instances → Actions → Image and Templates → Create Image
   - Image name: `unity-6000.3.9f1-licensed-YYYYMMDD`
8. AMI IDを控える → Terraform変数ファイルに記録

## フェーズ 2: CodeBuild パイプライン詳細設計

### CodeBuild EC2フリートとカスタムAMI

AWS CodeBuildはEC2フリート (`aws_codebuild_fleet`) を使うことで**カスタムAMIを指定できる**。
これによりUnityインストール済みのAMIを直接使用し、毎回のインストール時間を削減できる。

```hcl
resource "aws_codebuild_fleet" "unity" {
  name          = "unity-build-fleet"
  base_capacity = 1
  compute_type  = "BUILD_GENERAL1_LARGE"  # 8vCPU, 15GB RAM
  environment_type = "LINUX_EC2"

  fleet_service_role = aws_iam_role.codebuild_fleet.arn

  image_id = var.unity_ami_id  # フェーズ1で作成したAMI

  scaling_configuration {
    scaling_type   = "TARGET_TRACKING_SCALING"
    target_tracking_scaling_configs {
      metric_type  = "FLEET_UTILIZATION_RATE"
      target_value = 0.7
    }
  }
}
```

### buildspec.yml 設計

```yaml
version: 0.2

env:
  secrets-manager:
    GITHUB_TOKEN: "unity-cicd/github-token"

phases:
  pre_build:
    commands:
      - echo "Unity build starting..."
      - git clone $CODEBUILD_SOURCE_REPO_URL /tmp/project
      - cd /tmp/project && git checkout $CODEBUILD_RESOLVED_SOURCE_VERSION

  build:
    commands:
      - /opt/unity/Editor/Unity
          -batchmode
          -nographics
          -quit
          -projectPath /tmp/project
          -buildTarget Android
          -executeMethod BuildScript.Build
          -logFile /tmp/unity-build.log
          -outputPath /tmp/build/output.apk

  post_build:
    commands:
      - cat /tmp/unity-build.log
      - |
        if [ "$CODEBUILD_BUILD_SUCCEEDING" = "1" ]; then
          gh release upload $RELEASE_TAG /tmp/build/output.apk \
            --repo $GITHUB_REPO \
            --clobber
        fi

artifacts:
  files:
    - /tmp/build/output.apk
  discard-paths: no
```

### GitHub Actions → CodeBuild トリガー

```yaml
# .github/workflows/build-android.yml (ゲームリポジトリ側)
on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
      - name: Start CodeBuild
        run: |
          aws codebuild start-build \
            --project-name unity-android-build \
            --environment-variables-override \
              name=RELEASE_TAG,value=${{ github.ref_name }} \
              name=GITHUB_REPO,value=${{ github.repository }}
```

### IAMロールとセキュリティ設計

**CodeBuildサービスロール**:
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` (CloudWatch Logs)
- `secretsmanager:GetSecretValue` (GitHubトークン取得)
- `s3:GetObject`, `s3:PutObject` (ソースとアーティファクト)

**GitHub Personal Access Token**:
- AWS Secrets Manager に保存 (`unity-cicd/github-token`)
- `Contents: write` 権限が必要 (GitHub Releases へのアップロード)

## Terraformディレクトリ構造 (実装後)

```
terraform/
├── ec2_base/                    # フェーズ1: AMIビルダー用EC2
│   ├── main.tf                  # EC2インスタンス定義 (修正)
│   ├── iam.tf                   # SSM用インスタンスロール
│   ├── security_group.tf        # アウトバウンドのみ
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
└── unity_cicd/                  # フェーズ2: CodeBuildパイプライン (新規)
    ├── main.tf                  # CodeBuildプロジェクト・フリート
    ├── iam.tf                   # CodeBuildサービスロール
    ├── secrets.tf               # Secrets Manager
    ├── variables.tf
    ├── outputs.tf
    └── provider.tf
```

## コスト試算

| リソース | 用途 | 概算コスト |
|---------|------|-----------|
| EC2 t3.large Spot (ap-northeast-1) | AMI作成時のみ | ~$0.04/h × 数時間 |
| AMI (EBSスナップショット 50GB) | 常時 | ~$2/月 |
| CodeBuild EC2 BUILD_GENERAL1_LARGE | ビルド時のみ | ~$0.034/分 |
| CloudWatch Logs | ビルドログ | 無視できる程度 |
| Secrets Manager | GitHubトークン | $0.40/secret/月 |
