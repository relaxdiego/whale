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

resource "aws_key_pair" "authorized_key" {
  key_name   = var.authorized_key_name
  public_key = var.authorized_key
}


resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = var.vpc_instance_tenancy

  tags = {
    Name = var.vpc_name
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
    Name = "${var.vpc_name}-gw"
  }
}

resource "aws_security_group" "bastion" {
  name   = "${var.vpc_name}-sg-bastion"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH from the Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-sg-bastion"
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
    Name = "${var.vpc_name}-public-subnet1"
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
    Name = "${var.vpc_name}-nat-gw1"
  }
}

resource "aws_instance" "bastion1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet1.id
  key_name               = var.authorized_key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = {
    Name = "${var.vpc_name}-bastion1"
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
    Name = "${var.vpc_name}-public-subnet2"
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
    Name = "${var.vpc_name}-nat-gw2"
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
    Name = "${var.vpc_name}-private-subnet1"
  }
}

resource "aws_route_table" "private_subnet1_egress" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw1.id
  }

  tags = {
    Name = "${var.vpc_name}-private-subnet1-egress"
  }
}

resource "aws_route_table_association" "private_subnet1_egress" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_subnet1_egress.id
}

#
# PRIVATE SUBNET 2 RESOURCES
#

resource "aws_subnet" "private_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet2_cidr_block
  availability_zone       = var.public_subnet2_availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.vpc_name}-private-subnet2"
  }
}

resource "aws_route_table" "private_subnet2_egress" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw2.id
  }

  tags = {
    Name = "${var.vpc_name}-private-subnet2-egress"
  }
}

resource "aws_route_table_association" "private_subnet2_egress" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_subnet2_egress.id
}
