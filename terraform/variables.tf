variable "profile" {
  description = "The AWS CLI profile to use"
  type        = string
}

variable "region" {
  description = "AWS region to use"
  type        = string
}

variable "vpc_name" {
  description = "The name to give to this VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "vpc_instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC."
  type        = string
  default     = "default"
}

variable "public_subnet1_cidr_block" {
  description = "The cidr block to use for public-subnet1"
  type        = string
}

variable "public_subnet1_availability_zone" {
  description = "The AZ where public-subnet1 will reside"
  type        = string
}

variable "public_subnet2_cidr_block" {
  description = "The cidr block to use for public-subnet2"
  type        = string
}

variable "public_subnet2_availability_zone" {
  description = "The AZ where public-subnet2 will reside"
  type        = string
}

variable "private_subnet1_cidr_block" {
  description = "The cidr block to use for private-subnet1"
  type        = string
}

variable "private_subnet2_cidr_block" {
  description = "The cidr block to use for private-subnet2"
  type        = string
}
