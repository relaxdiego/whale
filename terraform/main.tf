terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.44"
    }
  }

  required_version = ">= 0.15.5"
}

provider "aws" {
  profile = var.profile
  region  = var.region
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_caller_identity" "current" {}

resource "aws_key_pair" "authorized_key" {
  key_name   = var.authorized_key_name
  public_key = var.authorized_key
}


resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = var.vpc_instance_tenancy

  tags = {
    Name = "${var.env_name}-vpc"
  }
}

resource "aws_route" "egress" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env_name}-gw"
  }
}

resource "aws_security_group" "bastion" {
  name   = "${var.env_name}-sg-bastion"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH from the Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "SSH to VPC instances"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = {
    Name = "${var.env_name}-sg-bastion"
  }
}

resource "aws_security_group" "common_egress" {
  name   = "${var.env_name}-sg-common-egress"
  vpc_id = aws_vpc.main.id

  egress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_name}-sg-common-egress"
  }
}

resource "aws_security_group" "allow_ssh_within_vpc" {
  name   = "${var.env_name}-sg-allow-ssh-within-vpc"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH from inside VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }

  tags = {
    Name = "${var.env_name}-sg-allow-ssh-within-vpc"
  }
}


resource "aws_security_group" "allow_db_access_within_vpc" {
  name   = "${var.env_name}-sg-allow-db-access-within-vpc"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "DB access from inside VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "DB access from inside VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
  }

  tags = {
    Name = "${var.env_name}-sg-allow-db-access-within-vpc"
  }
}
#
# PUBLIC SUBNET 1 RESOURCES
#

resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet1_cidr_block
  availability_zone       = var.public_subnet1_availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env_name}-public-subnet1"
    # https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/deploy/subnet_discovery/
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_eip" "nat_gw1" {
  vpc        = true
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat_gw1" {
  allocation_id = aws_eip.nat_gw1.id
  subnet_id     = aws_subnet.public_subnet1.id
  depends_on    = [aws_internet_gateway.gw]

  tags = {
    Name = "${var.env_name}-nat-gw1"
  }
}

resource "aws_instance" "bastion1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet1.id
  key_name      = var.authorized_key_name
  vpc_security_group_ids = [
    aws_security_group.bastion.id,
    aws_security_group.common_egress.id,
    aws_security_group.allow_ssh_within_vpc.id,
    aws_security_group.allow_db_access_within_vpc.id
  ]

  tags = {
    Name = "${var.env_name}-bastion1"
  }
}


#
# PUBLIC SUBNET 2 RESOURCES
#

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet2_cidr_block
  availability_zone       = var.public_subnet2_availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env_name}-public-subnet2"
    # https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/deploy/subnet_discovery/
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_eip" "nat_gw2" {
  vpc        = true
  depends_on = [aws_internet_gateway.gw]
}


resource "aws_nat_gateway" "nat_gw2" {
  allocation_id = aws_eip.nat_gw2.id
  subnet_id     = aws_subnet.public_subnet2.id
  depends_on    = [aws_internet_gateway.gw]

  tags = {
    Name = "${var.env_name}-nat-gw2"
  }
}


#
# PRIVATE SUBNET 1 RESOURCES
#

resource "aws_subnet" "private_subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet1_cidr_block
  availability_zone       = var.public_subnet1_availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.env_name}-private-subnet1"
    # https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/deploy/subnet_discovery/
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_route_table" "private_subnet1_egress" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw1.id
  }

  tags = {
    Name = "${var.env_name}-private-subnet1-egress"
  }
}

resource "aws_route_table_association" "private_subnet1_egress" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_subnet1_egress.id
}

# resource "aws_instance" "test" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.private_subnet1.id
#   key_name      = var.authorized_key_name
#   vpc_security_group_ids = [
#     aws_security_group.allow_ssh_within_vpc.id,
#     aws_security_group.common_egress.id,
#     aws_security_group.allow_db_access_within_vpc.id
#   ]
#
#   tags = {
#     Name = "${var.env_name}-test"
#   }
# }

#
# PRIVATE SUBNET 2 RESOURCES
#

resource "aws_subnet" "private_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet2_cidr_block
  availability_zone       = var.public_subnet2_availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.env_name}-private-subnet2"
    # https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/deploy/subnet_discovery/
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_route_table" "private_subnet2_egress" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw2.id
  }

  tags = {
    Name = "${var.env_name}-private-subnet2-egress"
  }
}

resource "aws_route_table_association" "private_subnet2_egress" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_subnet2_egress.id
}
