resource "aws_s3_bucket" "codebuild_artifacts" {
  bucket_prefix = "unity-codebuild-artifacts-"
  force_destroy = true

  tags = {
    Name = "unity-codebuild-artifacts"
  }
}

data "aws_region" "current" {}

locals {
  # Source: AWS CodeBuild docs (custom AMI sharing for reserved fleets), mapped by region.
  codebuild_org_arn_by_region = {
    "ap-northeast-1" = "arn:aws:organizations::891376993293:organization/o-b6k3sjqavm"
    "ap-south-1"     = "arn:aws:organizations::446018330677:organization/o-r7m1es80mv"
    "ap-southeast-1" = "arn:aws:organizations::590183934060:organization/o-54ch8e7ktf"
    "ap-southeast-2" = "arn:aws:organizations::891014815671:organization/o-4s9h7jcrcs"
    "eu-central-1"   = "arn:aws:organizations::871362719292:organization/o-x66o53sap8"
    "eu-west-1"      = "arn:aws:organizations::804197375199:organization/o-51j7jemy8b"
    "sa-east-1"      = "arn:aws:organizations::077055228059:organization/o-1xat6s2y8k"
    "us-east-1"      = "arn:aws:organizations::529387436163:organization/o-zhlf7g7qag"
    "us-east-2"      = "arn:aws:organizations::731142117874:organization/o-fk8hyga0ha"
    "us-west-2"      = "arn:aws:organizations::308613877161:organization/o-ziqlyl8a9x"
  }
  codebuild_organization_arn = coalesce(
    var.codebuild_organization_arn,
    lookup(local.codebuild_org_arn_by_region, data.aws_region.current.region, null)
  )

  github_repo_normalized = trimsuffix(
    trimprefix(
      trimprefix(var.github_repo, "https://github.com/"),
      "http://github.com/"
    ),
    ".git"
  )
  github_repo_clone_url    = "https://github.com/${local.github_repo_normalized}.git"
  codebuild_cache_location = "${aws_s3_bucket.codebuild_artifacts.bucket}/${var.codebuild_cache_prefix}/${var.codebuild_project_name}/${var.cache_namespace}"
}

resource "aws_ami_launch_permission" "codebuild_org" {
  image_id         = var.unity_ami_id
  organization_arn = local.codebuild_organization_arn

  lifecycle {
    precondition {
      condition     = local.codebuild_organization_arn != null
      error_message = "No default CodeBuild organization ARN is configured for region ${data.aws_region.current.region}. Set var.codebuild_organization_arn."
    }
  }
}

resource "aws_codebuild_fleet" "unity" {
  name               = var.codebuild_fleet_name
  base_capacity      = 1
  compute_type       = "BUILD_GENERAL1_LARGE"
  environment_type   = "LINUX_EC2"
  fleet_service_role = aws_iam_role.codebuild_fleet_service.arn
  image_id           = var.unity_ami_id
  overflow_behavior  = "QUEUE"
  depends_on         = [aws_ami_launch_permission.codebuild_org]

  scaling_configuration {
    max_capacity = 2
    scaling_type = "TARGET_TRACKING_SCALING"

    target_tracking_scaling_configs {
      metric_type  = "FLEET_UTILIZATION_RATE"
      target_value = 0.7
    }
  }

  tags = {
    Name = var.codebuild_fleet_name
  }
}

resource "aws_codebuild_project" "unity_android" {
  name           = var.codebuild_project_name
  description    = "Unity Android build pipeline using CodeBuild EC2 Fleet"
  service_role   = aws_iam_role.codebuild_service.arn
  build_timeout  = 120
  queued_timeout = 480

  artifacts {
    type      = "S3"
    location  = aws_s3_bucket.codebuild_artifacts.bucket
    packaging = "NONE"
  }

  cache {
    type     = "S3"
    location = local.codebuild_cache_location
  }

  environment {
    compute_type = "BUILD_GENERAL1_LARGE"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_EC2"

    fleet {
      fleet_arn = aws_codebuild_fleet.unity.arn
    }

    environment_variable {
      name  = "GITHUB_REPO"
      value = local.github_repo_normalized
    }

    environment_variable {
      name  = "UNITY_PATH"
      value = var.unity_path
    }

    environment_variable {
      name  = "GITHUB_TOKEN"
      type  = "SECRETS_MANAGER"
      value = "${aws_secretsmanager_secret.github_token.arn}:token"
    }

    environment_variable {
      name  = "witToken"
      type  = "SECRETS_MANAGER"
      value = "${aws_secretsmanager_secret.wit_client_token.arn}:token"
    }

    environment_variable {
      name  = "witServerToken"
      type  = "SECRETS_MANAGER"
      value = "${aws_secretsmanager_secret.wit_server_token.arn}:token"
    }

    environment_variable {
      name  = "photonAppId"
      value = var.photon_app_id
    }

    environment_variable {
      name  = "CACHE_NAMESPACE"
      value = var.cache_namespace
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/${var.codebuild_project_name}"
      status     = "ENABLED"
    }
  }

  source {
    type            = "GITHUB"
    location        = local.github_repo_clone_url
    git_clone_depth = 1
    buildspec       = file("${path.module}/buildspec.yml")
  }

  source_version = "main"

  tags = {
    Name = var.codebuild_project_name
  }
}

resource "aws_codebuild_webhook" "unity_android" {
  count        = var.enable_webhook ? 1 : 0
  project_name = aws_codebuild_project.unity_android.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = var.tag_regex
    }
  }
}
