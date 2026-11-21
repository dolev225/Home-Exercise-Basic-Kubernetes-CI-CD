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
  description = "size of block for the VPC"
  default     = "10.0.0.0/16"
}

variable "private_subnets_range" {
  type        = list(string)
  description = "IP ranges for private subnets "
  default     = ["10.0.16.0/20", "10.0.32.0/20"]
}

variable "public_subnets_range" {
  type        = list(string)
  description = "IP ranges for public subnets "
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "domain_name" {
  description = "Root domain name (must be registered in Route 53)"
  type        = string
  default     = "dolev-demoapp.com"
}

variable "enable_dns_tls" {
  description = "Create ACM certificate and Route53 records"
  type        = bool
  default     = false
}


variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "cluster endpoint open."
  default     = ["0.0.0.0/0"]
}

variable "pipeline_role_arn" {
  type        = string
  description = " role of the CI/CD pipeline"
  default     = null
}