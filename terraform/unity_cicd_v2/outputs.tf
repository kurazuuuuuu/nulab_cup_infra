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

output "unity_s3_cache_root" {
  description = "S3 root for custom Unity commit/branch cache archives"
  value       = "s3://${local.unity_s3_cache_bucket}${local.unity_s3_cache_prefix == "" ? "" : "/${local.unity_s3_cache_prefix}"}"
}

output "github_token_secret_arn" {
  description = "Secrets Manager ARN for GitHub token"
  value       = aws_secretsmanager_secret.github_token.arn
}

output "github_token_secret_name" {
  description = "Secrets Manager name for GitHub token"
  value       = aws_secretsmanager_secret.github_token.name
}

output "codebuild_webhook_payload_url" {
  description = "GitHub webhook payload URL to register in the repository settings (CodeBuild GitHub Actions Runner)"
  value       = var.enable_runner_webhook ? aws_codebuild_webhook.unity[0].payload_url : null
}

output "codebuild_webhook_secret" {
  description = "GitHub webhook secret for the CodeBuild GitHub Actions Runner webhook"
  value       = var.enable_runner_webhook ? aws_codebuild_webhook.unity[0].secret : null
  sensitive   = true
}
