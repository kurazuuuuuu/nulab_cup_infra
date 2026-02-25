# unity-ami-builder

Unity Editor インストール済み・ライセンス認証済みの EC2 AMI を手動で作成するための
インフラ基盤（EC2インスタンス）を Terraform で管理する。

## ADDED Requirements

### Requirement: REQ-UAB-001 EC2 Spotインスタンスの作成

Terraform MUST create an EC2 Spot instance in `ap-northeast-1` suitable for Unity installation and license authentication.
Unity のインストールおよびライセンス認証に適した EC2 Spotインスタンスを `ap-northeast-1` リージョンに作成すること。

- インスタンスタイプ: `t3.large` (x86_64, 2vCPU, 8GB RAM)
- OS: Ubuntu 22.04 LTS (x86_64)
- ストレージ: 50GB gp3
- マーケット: Spot

#### Scenario: Terraformでインスタンスが作成される

**Given** `terraform/ec2_base/` に正しい設定がある
**When** `terraform apply` を実行する
**Then** EC2 Spotインスタンスが `ap-northeast-1` に起動し、`instance_id` が出力される

---

### Requirement: REQ-UAB-002 SSM Session Manager によるGUIアクセス

The instance MUST have SSM Agent installed and SHALL support GUI access via AWS Systems Manager Fleet Manager Remote Desktop (VNC).
SSM エージェントがインストールされており、Fleet Manager の Remote Desktop 経由でGUIアクセスできること。

- EC2インスタンスロールに `AmazonSSMManagedInstanceCore` をアタッチ SHALL
- インスタンスに tigervnc と xfce4 をインストール (UserData)
- セキュリティグループにインバウンドルール不要

#### Scenario: Fleet Manager でGUI接続できる

**Given** EC2インスタンスが起動し、SSMエージェントが動作している
**When** AWS Console → Systems Manager → Fleet Manager → Remote Desktop で接続する
**Then** xfce4 デスクトップ環境が表示され、操作できる

---

### Requirement: REQ-UAB-003 セキュリティグループ設定

The security group MUST have no inbound rules and SHALL allow all outbound traffic.
インバウンドルールなし、アウトバウンドは全許可であること。

- インバウンド: なし (SSM経由のためポート開放不要)
- アウトバウンド SHALL: 0.0.0.0/0 (Unityライセンスサーバー・ダウンロードのため必要)

#### Scenario: セキュリティグループにインバウンドルールがない

**Given** Terraformで作成されたセキュリティグループがある
**When** AWS Console でインバウンドルールを確認する
**Then** インバウンドルールが空である

---

### Requirement: REQ-UAB-004 AMI IDの変数管理

手動で作成したAMIのIDは Terraform変数として管理し (MUST)、
後続の CodeBuildパイプラインから参照できなければならない (MUST)。

#### Scenario: AMI IDを変数ファイルに記録する

**Given** Unity インストール・認証済みのAMIが作成されている
**When** AMI IDを `terraform/unity_cicd/terraform.tfvars` の `unity_ami_id` に記録する
**Then** CodeBuildパイプライン側でそのAMI IDを参照できる

---

### Requirement: REQ-UAB-005 Terraform outputs

`ec2_base` モジュールは以下の値を `outputs.tf` で出力しなければならない (MUST)。

| 出力名 | 説明 |
|--------|------|
| `instance_id` | EC2インスタンスID (AMI作成時に参照) |
| `instance_az` | アベイラビリティゾーン |

#### Scenario: terraform apply後にinstance_idが出力される

**Given** `terraform apply` が成功している
**When** `terraform output instance_id` を実行する
**Then** `i-xxxxxxxxxxxxxxxxx` 形式のインスタンスIDが表示される
