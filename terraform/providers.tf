terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "hamza-aws-project-url-shortener-terraform-state"
    key = "terraform.tfstate"
    region = "eu-west-2"
    encrypt = "true"
    use_lockfile = "true"
  }
}

#configure the AWS provider
provider "aws" {
  region = "eu-west-2"
}

