output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.unity_android.name
}

output "codebuild_fleet_arn" {
  description = "CodeBuild fleet ARN"
  value       = aws_codebuild_fleet.unity.arn
}

output "artifacts_bucket_name" {
  description = "S3 bucket name used for CodeBuild artifacts"
  value       = aws_s3_bucket.codebuild_artifacts.bucket
}

output "codebuild_cache_location" {
  description = "S3 cache location used by CodeBuild project"
  value       = "${aws_s3_bucket.codebuild_artifacts.bucket}/${var.codebuild_cache_prefix}/${var.codebuild_project_name}/${var.cache_namespace}"
}

output "codebuild_webhook_url" {
  description = "CodeBuild webhook URL for GitHub integration (null when disabled)"
  value       = var.enable_webhook ? aws_codebuild_webhook.unity_android[0].url : null
}

output "github_token_secret_arn" {
  description = "Secrets Manager ARN for GitHub token"
  value       = aws_secretsmanager_secret.github_token.arn
}

output "github_token_secret_name" {
  description = "Secrets Manager name for GitHub token"
  value       = aws_secretsmanager_secret.github_token.name
}

output "wit_client_token_secret_arn" {
  description = "Secrets Manager ARN for Wit client token"
  value       = aws_secretsmanager_secret.wit_client_token.arn
}

output "wit_client_token_secret_name" {
  description = "Secrets Manager name for Wit client token"
  value       = aws_secretsmanager_secret.wit_client_token.name
}

output "wit_server_token_secret_arn" {
  description = "Secrets Manager ARN for Wit server token"
  value       = aws_secretsmanager_secret.wit_server_token.arn
}

output "wit_server_token_secret_name" {
  description = "Secrets Manager name for Wit server token"
  value       = aws_secretsmanager_secret.wit_server_token.name
}
