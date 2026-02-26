resource "aws_secretsmanager_secret" "github_token" {
  name_prefix = "unity-cicd/github-token-"
  description = "GitHub Personal Access Token for uploading Unity build artifacts"

  tags = {
    Name = "unity-cicd-github-token"
  }
}
