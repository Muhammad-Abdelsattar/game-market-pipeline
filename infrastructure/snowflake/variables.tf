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

# Variables from AWS Stack
variable "s3_bucket_name" {
  description = "Name of the S3 bucket (from AWS stack)"
  type        = string
}

variable "aws_role_arn" {
  description = "ARN of the AWS Role for Snowflake integration (from AWS stack)"
  type        = string
}
