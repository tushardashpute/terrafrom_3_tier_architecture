#variables.tf  
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_cidr" {
    default = "10.0.1.0/24"
}

variable "public_cidr1" {
    default = "10.0.2.0/24"
}

variable "private_cidr" { 
  default =  "10.0.3.0/24"
}

variable "private_cidr1" {
    default = "10.0.4.0/24"
}

variable "ami" {
  default =  "ami-04d29b6f966df1537"
}

variable "instance_count" {
  default = 1
}

variable "instance_tags" {
  default = ["Terraform-1", "Terraform-2"]
}

variable "instance_type" {
  default = "t2.medium"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "availability_zone" {
    default = "us-east-1a"
}

variable "availability_zone1" {
    default = "us-east-1b"
}

variable "env" {
  default = "TEST"
}

variable "key_name" {
  description = "key name"
  default = "test_ec2"
}
