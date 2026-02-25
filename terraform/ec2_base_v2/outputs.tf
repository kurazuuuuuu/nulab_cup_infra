output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.ami_maintainer.id
}

output "instance_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.ami_maintainer.public_ip
}

output "instance_private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.ami_maintainer.private_ip
}

output "instance_az" {
  description = "EC2 instance availability zone"
  value       = aws_instance.ami_maintainer.availability_zone
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.main.id
}
