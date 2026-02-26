resource "aws_secretsmanager_secret" "github_token" {
  name_prefix = "unity-cicd/github-token-"
  description = "GitHub Personal Access Token for uploading Unity build artifacts"

  tags = {
    Name = "unity-cicd-github-token"
  }
}

resource "aws_secretsmanager_secret" "wit_client_token" {
  name_prefix = "unity-cicd/wit-client-token-"
  description = "Wit token for Unity CI build (-witToken)"

  tags = {
    Name = "unity-cicd-wit-client-token"
  }
}

resource "aws_secretsmanager_secret" "wit_server_token" {
  name_prefix = "unity-cicd/wit-server-token-"
  description = "Wit server token for Unity CI build (-witServerToken)"

  tags = {
    Name = "unity-cicd-wit-server-token"
  }
}
