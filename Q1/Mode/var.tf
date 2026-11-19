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

variable "cluster_version" {
  type        = string
  description = "Kubernetes version. Verify it is currently supported by EKS."
  default     = "1.35"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ami" {
  type        = string
  description = "EKS managed node group AMI type"
  default     = "AL2023_x86_64_STANDARD"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "private_subnets_range" {
  type        = list(string)
  description = "IP ranges for private subnets (nodes and pods). /20 leaves room for pod IPs."
  default     = ["10.0.16.0/20", "10.0.32.0/20"]
}

variable "public_subnets_range" {
  type        = list(string)
  description = "IP ranges for public subnets (load balancers only)"
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the public EKS API endpoint. Restrict when possible."
  default     = ["0.0.0.0/0"]
}

variable "pipeline_role_arn" {
  type        = string
  description = "IAM role of the CI/CD pipeline; receives cluster-admin on the EKS API."
  default     = null
}