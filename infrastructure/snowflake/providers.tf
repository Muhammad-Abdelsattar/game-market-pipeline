terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87"
    }
  }
  required_version = ">= 1.0"
}

provider "snowflake" {
  account_name      = var.snowflake_account
  organization_name = var.snowflake_organization
  user              = var.snowflake_user  
  password          = var.snowflake_password
  role              = var.snowflake_role
}
