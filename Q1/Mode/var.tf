variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "owner" {
  type    = string
  default = "dolev"
}

variable "cost_center" {
  type    = string
  default = "devops-team"
}

variable "cluster_name" {
  type    = string
  default = "dolev-demo-cluster"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ami" {
  type    = string
  description = "iam version"
  default = "AL2_x86_64"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "private_subnets_range" {
  type    = list(string)
  description = "Ip range for private network"
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets_range" {
  type    = list(string)
  description = "Ip range for public network"
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}
