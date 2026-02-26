resource "aws_security_group" "unity_ami_builder" {
  name        = "unity-ami-builder-sg"
  description = "Security group for Unity AMI builder instance"
  vpc_id      = aws_vpc.unity_ami_builder.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "unity-ami-builder-sg"
  }
}
