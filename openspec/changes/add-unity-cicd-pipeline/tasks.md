# Tasks: Unity CI/CD パイプライン構築

## フェーズ 1: Unity AMI ビルダー

### Terraform実装

- [x] **T01**: `terraform/ec2_base/main.tf` を修正する
  - インスタンスタイプを `t3.large` (x86_64) に変更 (`t4g.nano` はARM、Unity非対応のため)
  - AMIを Ubuntu 22.04 LTS に変更
  - SSM用インスタンスロールをアタッチ
  - EBSボリュームを 50GB gp3 に設定
  - `data.aws_ami.example.id` の参照エラーを修正
  - UserDataでSSMエージェント・tigervnc・xfce4をインストール

- [x] **T02**: `terraform/ec2_base/iam.tf` を作成する
  - EC2インスタンスロール (`AmazonSSMManagedInstanceCore` ポリシーアタッチ)
  - インスタンスプロファイルを作成

- [x] **T03**: `terraform/ec2_base/security_group.tf` を作成する
  - インバウンドルールなし (SSM経由でアクセスするため不要)
  - アウトバウンドは全許可 (Unity・Unityライセンスサーバーへのアクセス)

- [x] **T04**: `terraform/ec2_base/variables.tf` と `outputs.tf` を作成する
  - 変数: `vpc_id`, `subnet_id`, `spot_max_price`
  - 出力: `instance_id`, `instance_public_dns`

- [ ] **T05**: `terraform/ec2_base/` に対して `terraform validate` と `terraform plan` を実行し、エラーがないことを確認する
  - `terraform validate` は成功、`terraform plan` は AWS 認証期限切れ (`No valid credential sources found`) のため未完了

### 手動作業 (Runbook)

- [ ] **T06**: `terraform apply` でEC2インスタンスを起動する

- [ ] **T07**: AWS Console → Systems Manager → Fleet Manager でインスタンスを確認し、Remote Desktop (VNC) で接続する

- [ ] **T08**: Unity Hub をインストールする
  ```bash
  # 接続後のターミナルで実行
  wget -qO- https://hub-dist.unity3d.com/artifactory/hub-debian-prod-local/public.gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/Unity_Technologies_ApS.gpg > /dev/null
  sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/Unity_Technologies_ApS.gpg] https://hub-dist.unity3d.com/artifactory/hub-debian-prod-local stable main" > /etc/apt/sources.list.d/unityhub.list'
  sudo apt update && sudo apt install unityhub -y
  ```

- [ ] **T09**: Unity Hub GUI で Unity 6000.3.9f1 + Android Build Support をインストールする
  - Unity Hub を起動
  - Installs → Add → Unity 6000.3.9f1 を選択
  - Modules: Android Build Support (Android SDK, NDK, OpenJDK) を追加

- [ ] **T10**: Unity Hub GUI でライセンス認証を行う
  - Preferences → Licenses → Add license

- [ ] **T11**: インスタンスを停止 (Stop) する
  ```bash
  aws ec2 stop-instances --instance-ids <instance-id>
  ```

- [ ] **T12**: AWS Console → EC2 → Instances → Actions → Image and Templates → Create Image で AMI を作成する
  - Image name: `unity-6000.3.9f1-licensed-<YYYYMMDD>`
  - No reboot: チェックしない (クリーンなAMIのため)

- [ ] **T13**: 作成したAMI IDを `terraform/unity_cicd/terraform.tfvars` に記録する
  ```hcl
  unity_ami_id = "ami-xxxxxxxxxxxxxxxxx"
  ```

## フェーズ 2: CodeBuild パイプライン

### Terraform実装

- [x] **T14**: `terraform/unity_cicd/` ディレクトリを作成し、`provider.tf` を作成する
  - プロバイダーは `ec2_base` と同様の設定

- [x] **T15**: `terraform/unity_cicd/main.tf` を作成する
  - `aws_codebuild_fleet` リソース (EC2フリート、カスタムAMI指定)
  - `aws_codebuild_project` リソース
  - S3バケット (ソース・アーティファクト用)

- [x] **T16**: `terraform/unity_cicd/iam.tf` を作成する
  - CodeBuildサービスロール
  - CodeBuildフリートサービスロール
  - 必要なポリシーのアタッチ

- [x] **T17**: `terraform/unity_cicd/secrets.tf` を作成する
  - `aws_secretsmanager_secret` リソース (GitHubトークン用)
  - 値は `terraform apply` 後に手動で設定するか、`terraform.tfvars` で指定

- [x] **T18**: `terraform/unity_cicd/variables.tf` と `outputs.tf` を作成する
  - 変数: `unity_ami_id`, `github_token`, `github_repo`
  - 出力: `codebuild_project_name`, `codebuild_fleet_arn`

- [x] **T19**: `buildspec.yml` を作成する (ゲームリポジトリのルート、または `terraform/unity_cicd/` に配置)
  - Unityバッチビルドコマンド
  - `gh` CLIによるGitHub Releasesへのアップロード

- [ ] **T20**: `terraform/unity_cicd/` に対して `terraform validate` と `terraform plan` を実行し、エラーがないことを確認する
  - `terraform validate` は成功、`terraform plan` は AWS 認証期限切れ (`No valid credential sources found`) のため未完了

- [ ] **T21**: `terraform apply` で CodeBuildリソースをデプロイする

### GitHub ActionsワークフローとE2Eテスト

- [ ] **T22**: AWS Secrets Manager にGitHub Personal Access Tokenを設定する
  ```bash
  aws secretsmanager put-secret-value \
    --secret-id unity-cicd/github-token \
    --secret-string '{"token":"ghp_xxxxxxxx"}'
  ```

- [ ] **T23**: ゲームリポジトリに `.github/workflows/build-android.yml` を作成する (設計書参照)
  - この infra リポジトリにはテンプレートとして `.github/workflows/build-android.yml` を追加済み

- [ ] **T24**: テストリリースタグをプッシュして、E2Eビルドを検証する
  ```bash
  git tag v0.0.1-test && git push origin v0.0.1-test
  ```

- [ ] **T25**: CodeBuildのビルドログを確認し、.apk が GitHub Releases にアップロードされていることを確認する

## 検証チェックリスト

- [ ] EC2 Spotインスタンスが正常に起動する
- [ ] SSM Fleet Manager でGUI接続できる
- [ ] Unityが正常に動作する (ライセンス認証済み)
- [ ] AMIが正常に作成される
- [ ] CodeBuildがカスタムAMIを使用してビルドできる
- [ ] .apk ファイルが生成される
- [ ] GitHub Releases に .apk がアップロードされる
- [ ] `terraform destroy` で全リソースが削除できる (AMIとスナップショットは手動削除)
