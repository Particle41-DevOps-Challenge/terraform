terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "6.23.0"
    }
  }

  backend "s3" {
    bucket = "mybucket-for-terraform-statefile-dev"
    key = "Particle41"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
    
  }
}

provider "aws" {
    #configuration options
    region = "us-east-1"
  
}