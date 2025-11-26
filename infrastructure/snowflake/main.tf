resource "snowflake_database" "game_db" {
  name = "GAME_MARKET_DB"
}

resource "snowflake_schema" "raw_schema" {
  database = snowflake_database.game_db.name
  name     = "RAW"
}

resource "snowflake_file_format" "json_format" {
  database    = snowflake_database.game_db.name
  schema      = snowflake_schema.raw_schema.name
  name        = "JSON_FORMAT"
  format_type = "JSON"
}

# Storage Integration (requires AWS IAM Role ARN)
resource "snowflake_storage_integration" "s3_int" {
  name    = "GAME_MARKET_S3_INT"
  comment = "Integration with S3 for Game Market Data"
  type    = "EXTERNAL_STAGE"

  enabled = true

  storage_provider         = "S3"
  storage_aws_role_arn     = var.aws_role_arn
  storage_allowed_locations = ["s3://${var.s3_bucket_name}/"]
  
  # Note: You need to grant the Snowflake IAM user (storage_aws_iam_user_arn) access to the S3 bucket policy.
}

resource "snowflake_stage" "s3_stage" {
  name                = "GAME_MARKET_STAGE"
  database            = snowflake_database.game_db.name
  schema              = snowflake_schema.raw_schema.name
  url                 = "s3://${var.s3_bucket_name}/raw/"
  storage_integration = snowflake_storage_integration.s3_int.name
  file_format         = snowflake_file_format.json_format.name
}

# Tables for each endpoint
resource "snowflake_table" "raw_games" {
  database = snowflake_database.game_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_GAMES"

  column {
    name = "data"
    type = "VARIANT"
  }
}

# Repeat for other endpoints or use for_each if possible (Terraform for_each with resources)
# For simplicity, just one example here.
