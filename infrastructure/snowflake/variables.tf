variable "snowflake_account" {
  type = string
}

variable "snowflake_organization" {
  type = string
}

variable "snowflake_user" {
  type = string
}

variable "snowflake_password" {
  type      = string
  sensitive = true
}

variable "snowflake_role" {
  type    = string
  default = "ACCOUNTADMIN"
}

# Inputs from AWS Stack
variable "s3_bucket_name" {
  type = string
}

variable "aws_role_arn" {
  type = string
}
