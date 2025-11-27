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

# ------------------------------------------------------------------------------
# SNOWFLAKE CREDENTIALS (passed to ECS for dbt)
# ------------------------------------------------------------------------------
variable "snowflake_account" {
  description = "Snowflake Account identifier (e.g., xy12345.us-east-1)"
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake Username"
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

variable "snowflake_warehouse" {
  description = "Snowflake Warehouse"
  type        = string
  default     = "COMPUTE_WH"
}

variable "snowflake_database" {
  description = "Snowflake Database"
  type        = string
  default     = "GAME_MARKET_DB"
}

variable "snowflake_schema" {
  description = "Snowflake Schema"
  type        = string
  default     = "ANALYTICS"
}
