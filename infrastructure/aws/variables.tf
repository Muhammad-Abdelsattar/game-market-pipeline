variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "game-market"
}

variable "endpoints" {
  description = "List of endpoints to ingest"
  type        = list(string)
  default     = ["games", "genres", "publishers", "developers", "platforms"]
}

# Snowflake Connection Vars (Passed to ECS)
variable "snowflake_account" {
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
variable "snowflake_warehouse" {
  type    = string
  default = "COMPUTE_WH"
}
variable "snowflake_database" {
  type    = string
  default = "GAME_MARKET_DB"
}
variable "snowflake_schema" {
  type    = string
  default = "ANALYTICS"
}

# Handshake Variables (For IAM Trust Policy)
variable "snowflake_iam_user" {
  description = "The IAM User ARN provided by Snowflake (Empty on first run)"
  type        = string
  default     = ""
}

variable "snowflake_external_id" {
  description = "The External ID provided by Snowflake (Empty on first run)"
  type        = string
  default     = ""
}
