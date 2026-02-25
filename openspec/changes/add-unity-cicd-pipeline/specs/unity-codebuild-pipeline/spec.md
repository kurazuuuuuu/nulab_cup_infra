# unity-codebuild-pipeline

AWS CodeBuild の EC2 フリートを使用し、Unity カスタム AMI でAndroid (.apk) ビルドを
自動実行し、成果物を GitHub Releases にアップロードするパイプラインを Terraform で管理する。

## ADDED Requirements

### Requirement: REQ-UCP-001 CodeBuild EC2フリートとカスタムAMI

Terraform は `aws_codebuild_fleet` リソースを作成し (MUST)、
フェーズ1で作成した Unity インストール済みカスタム AMI を使用しなければならない (MUST)。

- フリートタイプ: EC2
- コンピュートタイプ SHALL: `BUILD_GENERAL1_LARGE` (8vCPU, 15GB RAM)
- 環境タイプ SHALL: `LINUX_EC2`
- AMI SHALL: `var.unity_ami_id` で指定

#### Scenario: カスタムAMIを使ったフリートが作成される

**Given** `unity_ami_id` 変数にフェーズ1で作成したAMI IDが設定されている
**When** `terraform apply` を `terraform/unity_cicd/` で実行する
**Then** CodeBuild EC2フリートが作成され、そのAMIを使用するよう設定されている

---

### Requirement: REQ-UCP-002 CodeBuildプロジェクトの作成

Terraform は `aws_codebuild_project` リソースを作成しなければならない (MUST)。
プロジェクトは以下の設定を持たなければならない (MUST)。

- ソース SHALL: GitHub リポジトリを参照する
- ビルド仕様 SHALL: `buildspec.yml` を使用する
- 環境 SHALL: REQ-UCP-001 で作成したEC2フリートを使用する
- アーティファクト SHALL: S3バケットに出力する

#### Scenario: CodeBuildプロジェクトが手動ビルドを実行できる

**Given** CodeBuildプロジェクトが作成されており、カスタムAMIフリートが割り当てられている
**When** AWS Consoleまたは `aws codebuild start-build` でビルドを開始する
**Then** EC2インスタンス (カスタムAMI) 上でビルドが開始される

---

### Requirement: REQ-UCP-003 Unityバッチビルド

`buildspec.yml` は Unityを `-batchmode` で実行し (SHALL)、
Android (.apk) をビルドしなければならない (MUST)。

- Unity実行パス SHALL: `/opt/unity/Editor/Unity`
- ビルドターゲット SHALL: `Android`
- ログ出力 SHALL: CloudWatch Logs に記録する

#### Scenario: Unityバッチビルドが成功し.apkが生成される

**Given** ゲームプロジェクトのリポジトリがCodeBuildのソースとして設定されている
**When** CodeBuildビルドが実行される
**Then** Unity が `-batchmode` で起動し、`.apk` ファイルが生成される

#### Scenario: ビルドが失敗した場合にログが確認できる

**Given** Unityビルドがエラーで終了した
**When** CloudWatch Logs または CodeBuildコンソールでログを確認する
**Then** Unity のビルドログ (`-logFile` の出力) が確認できる

---

### Requirement: REQ-UCP-004 GitHub Releases へのアップロード

The pipeline MUST upload the generated `.apk` to GitHub Releases using `gh` CLI after a successful build.
ビルド成功後、`gh` CLI を使って `.apk` を指定の GitHub Release にアップロードすること。

- GitHub PAT SHALL: AWS Secrets Manager から取得する (`unity-cicd/github-token`)
- リリースタグ SHALL: 環境変数 `RELEASE_TAG` で渡される
- アップロード先リポジトリ SHALL: 環境変数 `GITHUB_REPO` で渡される

#### Scenario: ビルド成功後に.apkがGitHub Releasesにアップロードされる

**Given** ビルドが成功し、`.apk` ファイルが生成されている
**And** `RELEASE_TAG` 環境変数にGitHubリリースタグが設定されている
**When** `buildspec.yml` の `post_build` フェーズが実行される
**Then** 該当バージョンの GitHub Release に `.apk` がアップロードされる

#### Scenario: ビルド失敗時はアップロードをスキップする

**Given** Unityビルドが失敗し `CODEBUILD_BUILD_SUCCEEDING` が `0` である
**When** `buildspec.yml` の `post_build` フェーズが実行される
**Then** GitHub Releases へのアップロードは実行されない

---

### Requirement: REQ-UCP-005 GitHub PAT の安全な管理

GitHub Personal Access Token は AWS Secrets Manager に保存しなければならない (MUST)。
ソースコードやTerraformのstateに平文で含まれてはならない (MUST)。

- Secrets Manager シークレット名 SHALL: `unity-cicd/github-token`
- Terraform は `aws_secretsmanager_secret` リソースを作成しなければならない (MUST)
- CodeBuild の `env.secrets-manager` ブロックで参照しなければならない (MUST)

#### Scenario: GitHubトークンがSecretsManagerから取得される

**Given** `unity-cicd/github-token` にトークンが設定されている
**When** CodeBuildビルドが実行される
**Then** 環境変数 `GITHUB_TOKEN` にトークンが設定され、`gh` コマンドが認証される

---

### Requirement: REQ-UCP-006 GitHub Actionsからのトリガー

The GitHub Actions workflow in the game repository MUST be able to trigger CodeBuild builds.
ゲームリポジトリのGitHub Actionsワークフローから CodeBuildビルドを開始できること。

- トリガー SHALL: Gitタグ (`v*`) のプッシュ時に起動する
- AWS認証 SHALL: `aws-actions/configure-aws-credentials` アクションを使用する
- ビルド開始 SHALL: `aws codebuild start-build` コマンドを実行する

#### Scenario: タグプッシュでビルドが自動起動する

**Given** ゲームリポジトリに `v*` 形式のタグがプッシュされた
**When** GitHub Actions ワークフローが実行される
**Then** `aws codebuild start-build` でCodeBuildビルドが開始される

---

### Requirement: REQ-UCP-007 IAMロールと最小権限

CodeBuild サービスロールは最小権限の原則に従わなければならない (MUST)。
必要なAWSサービスへのアクセスのみ許可しなければならない (MUST)。

| 権限 | 用途 |
|------|------|
| `logs:CreateLogGroup` 等 | CloudWatch Logs への書き込み |
| `secretsmanager:GetSecretValue` | GitHubトークンの取得 |
| `s3:GetObject`, `s3:PutObject` | ソースとアーティファクトの読み書き |

#### Scenario: CodeBuildロールが必要最小限の権限を持つ

**Given** CodeBuildプロジェクトが作成されている
**When** IAMロールのポリシーを確認する
**Then** CloudWatch Logs、Secrets Manager、S3への必要最小限の権限のみが付与されている
