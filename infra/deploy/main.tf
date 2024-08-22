terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.0"
    }
  }

  backend "s3" {
    bucket               = "devops-recipe-app-tf-state-mohshire"
    key                  = "tf-state-deploy"
    workspace_key_prefix = "tf-state-deploy-env" # We will seperate the state into seperate workspaces
    # We'll have one for staging and one for production
    # AWS will seperate these workspaces within S3
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "devops-recipe-app-api-tf-lock"
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project
      Contact     = var.contact
      ManageBy    = "Terraform/deploy"
    }
  }
}

locals { # This is a local variable in terraform
  prefix = "${var.prefix}-${terraform.workspace}"
}
# We hard-code things using variables.tf 
# Or we can dynamically generate strings like this

data "aws_region" "current" {}
# A data resource to get info from our AWS account.
# It gets the current region that we are using from the account
# We can then reference the current region when creating new resources