terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "threetierterraformstatebucket" 
    key            = "LockID"
    region         = "us-east-2" 
    dynamodb_table = "terraform-lock-state" 
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-2"
} 