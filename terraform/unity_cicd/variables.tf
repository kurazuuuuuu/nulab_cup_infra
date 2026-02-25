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
