terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      environment = var.environment
      owner       = var.owner
      cost_center = var.cost_center
    }
  }
}

provider "kubernetes" {
  host                   = module.my_infrastructure.cluster_endpoint
  cluster_ca_certificate = base64decode(module.my_infrastructure.cluster_ca_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.my_infrastructure.cluster_name, "--region", var.aws_region]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.my_infrastructure.cluster_endpoint
    cluster_ca_certificate = base64decode(module.my_infrastructure.cluster_ca_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.my_infrastructure.cluster_name, "--region", var.aws_region]
    }
  }
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

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

variable "pipeline_role_arn" {
  type        = string
  description = "IAM role the CI/CD pipeline assumes. Gets cluster-admin access to the EKS API. Leave null if not used yet."
  default     = null
}

variable "domain_name" {
  type        = string
  description = "Application DNS name"
  default     = "demoapp.com"
}

variable "enable_dns_tls" {
  type        = bool
  description = "Create ACM certificate + Route53 records. Requires a PUBLIC Route53 zone for domain_name that you control. Keep false to test with a hosts file."
  default     = false
}

variable "image_repository" {
  type    = string
  default = "dolev1234/node-demo-local"
}

variable "image_tag" {
  type        = string
  description = "Image tag. The app pipeline should override this with the commit SHA."
  default     = "latest"
}

variable "deploy_apps" {
  type        = bool
  description = "Deploy Helm releases and Ingress. Set to false on first apply (or after destroy)."
  default     = false
}