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


