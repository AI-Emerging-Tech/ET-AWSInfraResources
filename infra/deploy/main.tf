terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0"
    }
    ec = {
      source  = "elastic/ec"
      version = "0.12.2"
    }
  }
  backend "s3" {
    bucket               = "devops-et-ai-tf-state"
    key                  = "tf-state-deploy"
    workspace_key_prefix = "tf-state-deploy-env"
    region               = "us-east-1"
    encrypt              = true
    dynamodb_table       = "devops-et-ai-tf-lock"
  }
}
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project
      contact     = var.contact
      ManageBy    = "Terraform/deploy"
    }
  }
}

locals {
  prefix = "${var.prefix}-${terraform.workspace}"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}