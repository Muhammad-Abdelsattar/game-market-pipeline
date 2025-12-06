terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87"
    }
  }
  required_version = ">= 1.0"

  backend "s3" {
    bucket       = "game-market-pipeline-tf-state" # Change to your unique bucket name
    key          = "prod/snowflake/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "snowflake" {
  account_name      = var.snowflake_account_name
  organization_name = var.snowflake_organization_name
  user              = var.snowflake_user
  password          = var.snowflake_password
  role              = var.snowflake_role
}
