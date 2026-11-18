terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
# connect to the provide cloud
provider "aws" {
  region = "us-east-1"
  }


provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop" 
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "docker-desktop"
  }
}