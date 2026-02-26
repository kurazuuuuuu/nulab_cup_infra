output "instance_id" {
  description = "EC2 instance ID for the Unity AMI builder"
  value       = aws_instance.unity_ami_builder.id
}

output "instance_public_dns" {
  description = "Public DNS of the Unity AMI builder instance"
  value       = aws_instance.unity_ami_builder.public_dns
}

output "instance_az" {
  description = "Availability Zone of the Unity AMI builder instance"
  value       = aws_instance.unity_ami_builder.availability_zone
}

output "vpc_id" {
  description = "VPC ID created for the Unity AMI builder"
  value       = aws_vpc.unity_ami_builder.id
}

output "subnet_id" {
  description = "Subnet ID created for the Unity AMI builder"
  value       = aws_subnet.unity_ami_builder.id
}
