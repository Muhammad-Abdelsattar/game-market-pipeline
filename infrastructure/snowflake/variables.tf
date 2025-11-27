variable "snowflake_account" {
  description = "Snowflake Account ID"
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake User"
  type        = string
}

variable "snowflake_password" {
  description = "Snowflake Password"
  type        = string
  sensitive   = true
}

variable "snowflake_role" {
  description = "Snowflake Role"
  type        = string
  default     = "ACCOUNTADMIN"
}

# ------------------------------------------------------------------------------
# VARIABLES FROM AWS INFRASTRUCTURE
# ------------------------------------------------------------------------------
variable "s3_bucket_name" {
  description = "Name of the S3 bucket (Output from AWS Stack)"
  type        = string
}

variable "aws_role_arn" {
  description = "ARN of the IAM Role created in AWS Stack for Snowflake"
  type        = string
}
