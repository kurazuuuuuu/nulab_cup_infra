variable "unity_ami_id" {
  description = "AMI ID for Unity-installed and licensed EC2 image"
  type        = string
}

variable "codebuild_organization_arn" {
  description = "Override for the CodeBuild service organization ARN used for AMI launch permission. If null, it is auto-resolved from region."
  type        = string
  default     = null
}

variable "unity_path" {
  description = "Absolute path to the Unity executable on the build host"
  type        = string
  default     = "/opt/unity/Editor/Unity"
}

variable "photon_app_id" {
  description = "Optional Photon App ID to pass to Unity build (-photonAppId)"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository in owner/repo or https://github.com/owner/repo(.git) format"
  type        = string
}

variable "codebuild_project_name" {
  description = "CodeBuild project name"
  type        = string
  default     = "unity-android-build"
}

variable "codebuild_fleet_name" {
  description = "CodeBuild fleet name"
  type        = string
  default     = "unity-build-fleet-v2"
}

variable "enable_webhook" {
  description = "Whether to create a CodeBuild webhook for tag push events"
  type        = bool
  default     = true
}

variable "tag_regex" {
  description = "Regex for webhook HEAD_REF filter (for example refs/tags/vX.Y.Z)"
  type        = string
  default     = "^refs/tags/v[0-9]+\\.[0-9]+\\.[0-9]+$"
}

variable "codebuild_cache_prefix" {
  description = "S3 prefix for CodeBuild cache objects"
  type        = string
  default     = "codebuild-cache"
}

variable "cache_namespace" {
  description = "Logical namespace for cache segregation"
  type        = string
  default     = "unity-6000.3.9f1"
}
