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

variable "codeconnections_connection_arn" {
  description = "Optional CodeConnections ARN used by the CodeBuild source integration. When null, UseConnection is allowed for all connections."
  type        = string
  default     = null
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

variable "codebuild_fleet_compute_type" {
  description = "CodeBuild fleet compute type (for example BUILD_GENERAL1_LARGE, CUSTOM_INSTANCE_TYPE, ATTRIBUTE_BASED_COMPUTE)"
  type        = string
  default     = "BUILD_GENERAL1_LARGE"

  validation {
    condition = contains(
      [
        "BUILD_GENERAL1_SMALL",
        "BUILD_GENERAL1_MEDIUM",
        "BUILD_GENERAL1_LARGE",
        "BUILD_GENERAL1_XLARGE",
        "BUILD_GENERAL1_2XLARGE",
        "CUSTOM_INSTANCE_TYPE",
        "ATTRIBUTE_BASED_COMPUTE",
      ],
      var.codebuild_fleet_compute_type
    )
    error_message = "codebuild_fleet_compute_type must be a supported CodeBuild fleet compute type."
  }
}

variable "codebuild_fleet_instance_type" {
  description = "EC2 instance type when codebuild_fleet_compute_type = CUSTOM_INSTANCE_TYPE (for example c7i.4xlarge)"
  type        = string
  default     = null

  validation {
    condition     = var.codebuild_fleet_compute_type != "CUSTOM_INSTANCE_TYPE" || var.codebuild_fleet_instance_type != null
    error_message = "codebuild_fleet_instance_type is required when codebuild_fleet_compute_type is CUSTOM_INSTANCE_TYPE."
  }
}

variable "codebuild_fleet_machine_type" {
  description = "Machine type when codebuild_fleet_compute_type = ATTRIBUTE_BASED_COMPUTE (GENERAL or NVME)"
  type        = string
  default     = null

  validation {
    condition     = var.codebuild_fleet_machine_type == null || contains(["GENERAL", "NVME"], var.codebuild_fleet_machine_type)
    error_message = "codebuild_fleet_machine_type must be GENERAL, NVME, or null."
  }
}

variable "codebuild_fleet_vcpu" {
  description = "vCPU requirement when codebuild_fleet_compute_type = ATTRIBUTE_BASED_COMPUTE"
  type        = number
  default     = null
}

variable "codebuild_fleet_memory" {
  description = "Memory requirement (GiB) when codebuild_fleet_compute_type = ATTRIBUTE_BASED_COMPUTE"
  type        = number
  default     = null
}

variable "enable_runner_webhook" {
  description = "Whether to create a webhook for GitHub Actions runner jobs (WORKFLOW_JOB_QUEUED)."
  type        = bool
  default     = true
}

variable "runner_workflow_name_regex" {
  description = "Optional regex for WORKFLOW_NAME filter. Null means all workflow jobs are accepted."
  type        = string
  default     = null
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

variable "unity_s3_cache_bucket" {
  description = "S3 bucket name for custom Unity cache archives (commits/ and branches/ objects). If null, artifacts bucket is used."
  type        = string
  default     = null
}

variable "unity_s3_cache_prefix" {
  description = "Optional S3 prefix for custom Unity cache archives"
  type        = string
  default     = ""
}

variable "unity_s3_cache_fallback_branch" {
  description = "Fallback branch name for custom Unity cache restore"
  type        = string
  default     = "main"
}
