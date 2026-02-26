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
  github_repo_clone_url     = "https://github.com/${local.github_repo_normalized}.git"
  codebuild_cache_location  = "${aws_s3_bucket.codebuild_artifacts.bucket}/${var.codebuild_cache_prefix}/${var.codebuild_project_name}/${var.cache_namespace}"
  unity_s3_cache_bucket     = coalesce(var.unity_s3_cache_bucket, aws_s3_bucket.codebuild_artifacts.bucket)
  unity_s3_cache_prefix     = trim(var.unity_s3_cache_prefix, "/")
  unity_s3_cache_bucket_arn = "arn:aws:s3:::${local.unity_s3_cache_bucket}"
  codeconnections_arns = var.codeconnections_connection_arn == null ? [] : distinct([
    var.codeconnections_connection_arn,
    replace(var.codeconnections_connection_arn, ":codestar-connections:", ":codeconnections:"),
    replace(var.codeconnections_connection_arn, ":codeconnections:", ":codestar-connections:"),
  ])
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
  compute_type       = var.codebuild_fleet_compute_type
  environment_type   = "LINUX_EC2"
  fleet_service_role = aws_iam_role.codebuild_fleet_service.arn
  image_id           = var.unity_ami_id
  overflow_behavior  = "QUEUE"
  depends_on = [
    aws_ami_launch_permission.codebuild_org,
    aws_iam_role_policy.codebuild_fleet_permissions,
  ]

  dynamic "compute_configuration" {
    for_each = contains(["CUSTOM_INSTANCE_TYPE", "ATTRIBUTE_BASED_COMPUTE"], var.codebuild_fleet_compute_type) ? [1] : []

    content {
      instance_type = var.codebuild_fleet_instance_type
      machine_type  = var.codebuild_fleet_machine_type
      vcpu          = var.codebuild_fleet_vcpu
      memory        = var.codebuild_fleet_memory
    }
  }

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

  lifecycle {
    precondition {
      condition     = !contains(["BUILD_GENERAL1_XLARGE", "BUILD_GENERAL1_2XLARGE"], var.codebuild_fleet_compute_type)
      error_message = "LINUX_EC2 fleet does not support BUILD_GENERAL1_XLARGE/BUILD_GENERAL1_2XLARGE. Use CUSTOM_INSTANCE_TYPE with compute_configuration.instance_type instead."
    }

    precondition {
      condition = var.codebuild_fleet_compute_type != "ATTRIBUTE_BASED_COMPUTE" || length(compact([
        var.codebuild_fleet_machine_type,
        var.codebuild_fleet_vcpu == null ? null : tostring(var.codebuild_fleet_vcpu),
        var.codebuild_fleet_memory == null ? null : tostring(var.codebuild_fleet_memory),
      ])) > 0
      error_message = "When codebuild_fleet_compute_type is ATTRIBUTE_BASED_COMPUTE, set at least one of machine_type, vcpu, or memory."
    }
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
    compute_type = var.codebuild_fleet_compute_type
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
      name  = "CACHE_NAMESPACE"
      value = var.cache_namespace
    }

    environment_variable {
      name  = "UNITY_S3_CACHE_BUCKET"
      value = local.unity_s3_cache_bucket
    }

    environment_variable {
      name  = "UNITY_S3_CACHE_PREFIX"
      value = local.unity_s3_cache_prefix
    }

    environment_variable {
      name  = "UNITY_S3_CACHE_FALLBACK_BRANCH"
      value = var.unity_s3_cache_fallback_branch
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

    dynamic "auth" {
      for_each = var.codeconnections_connection_arn == null ? [] : [1]

      content {
        type     = "CODECONNECTIONS"
        resource = var.codeconnections_connection_arn
      }
    }
  }

  depends_on = [
    aws_iam_role_policy.codebuild_service_permissions,
  ]

  tags = {
    Name = var.codebuild_project_name
  }
}

resource "aws_codebuild_webhook" "unity" {
  count        = var.enable_runner_webhook ? 1 : 0
  project_name = aws_codebuild_project.unity_android.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }

    dynamic "filter" {
      for_each = var.runner_workflow_name_regex != null ? [1] : []

      content {
        type    = "WORKFLOW_NAME"
        pattern = var.runner_workflow_name_regex
      }
    }
  }
}
