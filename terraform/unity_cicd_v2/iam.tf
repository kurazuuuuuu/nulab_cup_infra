data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_service" {
  name               = "unity-codebuild-service-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

resource "aws_iam_role" "codebuild_fleet_service" {
  name               = "unity-codebuild-fleet-service-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

data "aws_iam_policy_document" "codebuild_service_permissions" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid    = "ArtifactsBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = distinct([
      aws_s3_bucket.codebuild_artifacts.arn,
      "${aws_s3_bucket.codebuild_artifacts.arn}/*",
      local.unity_s3_cache_bucket_arn,
      "${local.unity_s3_cache_bucket_arn}/*"
    ])
  }

  statement {
    sid    = "BuildSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.github_token.arn,
      "${aws_secretsmanager_secret.github_token.arn}*",
    ]
  }

  statement {
    sid    = "CodeConnectionsUseConnection"
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection",
      "codestar-connections:GetConnection",
      "codestar-connections:GetConnectionToken",
      "codeconnections:UseConnection",
      "codeconnections:GetConnection",
      "codeconnections:GetConnectionToken",
    ]
    resources = length(local.codeconnections_arns) > 0 ? local.codeconnections_arns : ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_service_permissions" {
  name   = "unity-codebuild-service-permissions"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_service_permissions.json
}

data "aws_iam_policy_document" "codebuild_fleet_permissions" {
  statement {
    sid    = "EC2FleetOperations"
    effect = "Allow"
    actions = [
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DeletePolicy",
      "autoscaling:PutScalingPolicy",
      "autoscaling:UpdateAutoScalingGroup",
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:CreateTags",
      "ec2:DeleteFleet",
      "ec2:DeleteLaunchTemplate",
      "ec2:DeleteLaunchTemplateVersions",
      "ec2:DeleteTags",
      "ec2:Describe*",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "iam:PassRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_fleet_permissions" {
  name   = "unity-codebuild-fleet-permissions"
  role   = aws_iam_role.codebuild_fleet_service.id
  policy = data.aws_iam_policy_document.codebuild_fleet_permissions.json
}
