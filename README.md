## ハックツハッカソン Nulabカップ
### IaC用リポジトリ

## 技術構成
- Terraform (IaC)
- AWS
    - EC2
        - AMI
    - CodeBuild
    - SecretManager

## CI (apkビルド)
[メインリポジトリ](https://github.com/thirdlf03/nulab_cup_new)がUnityプロジェクトのため、専用のビルド環境が必要になります。Dockerコンテナなどでも可能ですが、Unityの無料ライセンス"Personal"ではビルドサーバーへの一時的なライセンス付与が難しいため、今回のインフラでは**事前構築をしたEC2インスタンスのスナップショットをイメージとして保存し、CodeBuildで動的に使用する**形を採用しました。

- Prepare: (Unity Hub, Unity Editor 6000.3.9f1 --> EC2 Linux Instance) --> EC2 Snapshot --> AMI (Amazon Machine Image)

- Build: AMI --> CodeBuild Compute Fleet (EC2) --> Github Releases (.apk)

