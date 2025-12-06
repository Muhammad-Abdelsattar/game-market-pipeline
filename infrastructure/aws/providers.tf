terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"

  # That's optional but recommended, if you don't want a remote backend, comment the backend section.
  #If you use it, you MUST create the bucket yourself in the console first.
  backend "s3" {
    bucket       = "game-market-pipeline-tf-state" # Change to your unique bucket name
    key          = "prod/aws/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}
