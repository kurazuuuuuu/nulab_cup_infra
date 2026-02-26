data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "unity_ami_builder" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "unity-ami-builder-vpc"
  }
}

resource "aws_subnet" "unity_ami_builder" {
  vpc_id                  = aws_vpc.unity_ami_builder.id
  cidr_block              = var.subnet_cidr_block
  availability_zone       = var.subnet_availability_zone != "" ? var.subnet_availability_zone : data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "unity-ami-builder-subnet"
  }
}

resource "aws_internet_gateway" "unity_ami_builder" {
  vpc_id = aws_vpc.unity_ami_builder.id

  tags = {
    Name = "unity-ami-builder-igw"
  }
}

resource "aws_route_table" "unity_ami_builder_public" {
  vpc_id = aws_vpc.unity_ami_builder.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.unity_ami_builder.id
  }

  tags = {
    Name = "unity-ami-builder-public-rt"
  }
}

resource "aws_route_table_association" "unity_ami_builder_public" {
  subnet_id      = aws_subnet.unity_ami_builder.id
  route_table_id = aws_route_table.unity_ami_builder_public.id
}
