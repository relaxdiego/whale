variable "env_name" {
  description = "The name to give to this environment. Will be used to prefix names of various resources."
  type        = string
}

variable "profile" {
  description = "The AWS CLI profile to use"
  type        = string
}

variable "region" {
  description = "AWS region to use"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "authorized_key_name" {
  description = "The name of the public key to inject to instances launched in the VPC"
  type        = string
}

variable "authorized_key" {
  description = "The public key to inject to instances launched in the VPC"
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

variable "db_creds_secret_name" {
  description = "The name of the AWS Secret containing the database credentials"
  type        = string
}

variable "db_multi_az" {
  description = "Should the database be multi AZ or not?"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Should we skip snapshot creation just before deleting the DB?"
  type        = bool
  default     = false
}
