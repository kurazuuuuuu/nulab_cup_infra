variable "vpc_cidr_block" {
  description = "CIDR block for the VPC where the Unity AMI builder instance is deployed"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  description = "CIDR block for the subnet where the Unity AMI builder instance is deployed"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_availability_zone" {
  description = "Availability zone for the subnet. If empty, the first available AZ is used."
  type        = string
  default     = ""
}

variable "ubuntu_ami_ssm_parameter_name" {
  description = "SSM parameter name for the Ubuntu 22.04 AMI ID"
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

variable "spot_max_price" {
  description = "Maximum hourly bid price for the Spot instance"
  type        = string
  default     = "0.08"
}
