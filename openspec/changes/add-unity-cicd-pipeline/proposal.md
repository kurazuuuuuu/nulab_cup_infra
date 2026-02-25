# Proposal: Unity CI/CD パイプライン構築

## Change ID
`add-unity-cicd-pipeline`

## 概要
AWS上でUnityプロジェクトのCI/CDパイプラインを構築する。
手動セットアップ済みのEC2 AMIをベースに、AWS CodeBuildを用いてAndroid (.apk) ビルドを自動化し、成果物をGitHub Releasesへアップロードする。

## Why
- Unityのビルドは実行時間が長く、ライセンス認証が必要なため、通常のCI環境では直接実行が難しい
- Unity 6000.3.9f1をインストール・ライセンス認証済みのEC2 AMIを一度手動で作成し、以降のビルドはCodeBuildで自動実行することでコストと運用負担を削減する
- ビルド成果物 (.apk) をGitHub Releasesに自動アップロードすることで、リリースフローを標準化する

## スコープ

### フェーズ 1: Unity AMI ビルダー (unity-ami-builder)
- Terraform でGUIアクセス可能なEC2 Spotインスタンスを作成
- SSM Session Manager + VNCによるGUIログインを可能にする
- 手動作業: Unityインストール・ライセンス認証後、AMIを作成
- 作成したAMI IDをTerraform変数として管理

### フェーズ 2: Unity CodeBuild パイプライン (unity-codebuild-pipeline)
- Terraform で CodeBuildプロジェクトおよびEC2フリートを作成
- EC2フリートにフェーズ1で作成したカスタムAMIを指定
- GitHub ActionsからCodeBuildをトリガーする連携を設定
- ビルド完了後、`gh` CLIを使って .apk を GitHub Releasesにアップロード

## 対象外
- Unityのインストール自動化 (Packerによる完全自動化) — 将来の改善として検討
- Unityライセンスサーバーの構築 — 現時点では個人ライセンスの手動認証を前提とする
- iOS (.ipa) ビルド — macOS環境が必要なため別提案とする

## 技術選定

| 要素 | 選定 | 理由 |
|------|------|------|
| EC2 GUIアクセス | SSM Fleet Manager (VNC) | SSHキー不要、セキュアなアクセス |
| AMI管理 | Terraform data source | AMI IDを変数化して管理 |
| ビルド基盤 | AWS CodeBuild EC2フリート | カスタムAMI指定が可能 |
| ビルドトリガー | GitHub Actions → CodeBuild | 既存のGitHubワークフローと統合 |
| 成果物配布 | GitHub Releases (gh CLI) | GitHubとの親和性が高い |

## リスクと注意事項
1. **Unityライセンス**: AMIにライセンス認証情報を含めることはUnity利用規約の観点から注意が必要。シート数や同時実行数の制限を遵守すること
2. **Spotインスタンス**: 中断リスクがあるため、AMIビルド用インスタンスのみSpotを使用し、中断された場合は再実行する
3. **AMIのコスト**: 不要になったAMIとEBSスナップショットは適宜削除すること
4. **GitHubトークン**: CodeBuildからGitHub Releasesへアップロードするため、Personal Access Token (classic) または Fine-grained PAT が必要

## 関連する既存リソース
- `terraform/ec2_base/`: EC2スポットインスタンスのベースコード（未完成、今回拡張する）
- `terraform/terraform-vpc-example/`: VPC設定（サブネット設計の参考）
- `terraform/terraform-aws-github-runner/`: GitHub Runnerモジュール（参考、今回は使わない）
