########################################
# Terraform AWS VPC + EC2 Demo
# Author: Shaik Ummar Farooq
# Description: Infrastructure as Code Example
########################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

########################################
# VPC
########################################
resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "demo-vpc"
  }
}

########################################
# Internet Gateway
########################################
resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "demo-igw"
  }
}

########################################
# Public Subnet
########################################
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "demo-public-subnet"
  }
}

########################################
# Route Table
########################################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }

  tags = {
    Name = "demo-public-rt"
  }
}

########################################
# Associate Route Table
########################################
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

########################################
# Security Group
########################################
resource "aws_security_group" "demo_sg" {
  name        = "demo-sg"
  description = "Allow SSH & HTTP"
  vpc_id      = aws_vpc.demo_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo-sg"
  }
}

########################################
# EC2 Instance
########################################
resource "aws_instance" "demo_ec2" {
  ami                         = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.demo_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_pair

  tags = {
    Name = "demo-ec2"
  }
}

########################################
# Outputs
########################################
output "instance_public_ip" {
  value = aws_instance.demo_ec2.public_ip
}

output "vpc_id" {
  value = aws_vpc.demo_vpc.id
}

