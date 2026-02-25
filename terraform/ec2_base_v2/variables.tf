variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "profile" {
  description = "AWS profile"
  type        = string
  default     = "nulab-cup"
}

variable "base_ami_id" {
  description = "Base AMI ID to launch the instance from (reuse the first Unity AMI)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 50
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_cidr_block" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.20.1.0/24"
}

variable "subnet_availability_zone" {
  description = "Availability zone for subnet. If empty, the first available AZ is used."
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
  default     = "unity-ami-maintainer-v2"
}
