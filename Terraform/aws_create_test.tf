# Environment variables
# variable "aws_access_key" {}
# variable "aws_secret_key" {}
variable "region" {
  default = "us-east-1"
}

# AMI
variable "images" {
  default = {
    us-east-1      = "ami-0a313d6098716f372"
    ap-northeast-1 = "ami-0eb48a19a8d81e20b"
  }
}

# Config
provider "aws" {
  #    access_key = "${var.aws_access_key}"
  #    secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
}

# VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "false"
  tags = {
    Name   = "dafukui"
    Source = "Terraform"
  }
}

# IG
resource "aws_internet_gateway" "terraform_ig" {
  vpc_id = "${aws_vpc.terraform_vpc.id}" # VPCのIDを参照
  tags = {
    Name   = "dafukui"
    Source = "Terraform"
  }
}

# Subnet
resource "aws_subnet" "terraform-public-a" {
  vpc_id            = "${aws_vpc.terraform_vpc.id}"
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name   = "dafukui"
    Source = "Terraform"
  }
}

# Routetable
resource "aws_route_table" "terraform-public-route" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.terraform_ig.id}"
  }
  tags = {
    Name   = "dafukui"
    Source = "Terraform"
  }
}

# Routetable association
resource "aws_route_table_association" "terraform-public-a" {
  subnet_id      = "${aws_subnet.terraform-public-a.id}"
  route_table_id = "${aws_route_table.terraform-public-route.id}"
}

# Security group
resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "SSH inbound"
  vpc_id      = "${aws_vpc.terraform_vpc.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2
resource "aws_instance" "terraform_bastion" {
  ami           = "${var.images.us-east-1}"
  instance_type = "t2.micro"
  key_name      = "test-dafukui-eb"
  vpc_security_group_ids = [
    "${aws_security_group.bastion.id}"
  ]
  subnet_id                   = "${aws_subnet.terraform-public-a.id}"
  associate_public_ip_address = "true"
  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
  }
  tags = {
    Name   = "dafukui"
    Source = "Terraform"
  }
}

# output
output "public_ip_of_terraform_bastion" {
  value = "${aws_instance.terraform_bastion.public_ip}"
}