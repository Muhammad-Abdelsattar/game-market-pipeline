resource "snowflake_database" "game_db" {
  name = "GAME_MARKET_DB"
}

resource "snowflake_schema" "raw_schema" {
  database = snowflake_database.game_db.name
  name     = "RAW"
}

resource "snowflake_schema" "analytics_schema" {
  database = snowflake_database.game_db.name
  name     = "ANALYTICS"
}

resource "snowflake_file_format" "json_format" {
  database    = snowflake_database.game_db.name
  schema      = snowflake_schema.raw_schema.name
  name        = "JSON_FORMAT"
  format_type = "JSON"
}

resource "snowflake_storage_integration" "s3_int" {
  name                      = "GAME_MARKET_S3_INT"
  type                      = "EXTERNAL_STAGE"
  enabled                   = true
  storage_provider          = "S3"
  storage_aws_role_arn      = var.aws_role_arn
  storage_allowed_locations = ["s3://${var.s3_bucket_name}/"]
}

resource "snowflake_stage" "s3_stage" {
  name                = "GAME_MARKET_STAGE"
  database            = snowflake_database.game_db.name
  schema              = snowflake_schema.raw_schema.name
  url                 = "s3://${var.s3_bucket_name}/raw/"
  storage_integration = snowflake_storage_integration.s3_int.name
  
  file_format = "FORMAT_NAME = \"${snowflake_database.game_db.name}\".\"${snowflake_schema.raw_schema.name}\".\"${snowflake_file_format.json_format.name}\""
}

# Raw Tables

resource "snowflake_table" "raw_games" {
  database = snowflake_database.game_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_GAMES"
  column {
    name = "data"
    type = "VARIANT"
  }
}

resource "snowflake_table" "raw_genres" {
  database = snowflake_database.game_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_GENRES"
  column {
    name = "data"
    type = "VARIANT"
  }
}

resource "snowflake_table" "raw_developers" {
  database = snowflake_database.game_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_DEVELOPERS"
  column {
    name = "data"
    type = "VARIANT"
  }
}

resource "snowflake_table" "raw_publishers" {
  database = snowflake_database.game_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_PUBLISHERS"
  column {
    name = "data"
    type = "VARIANT"
  }
}

resource "snowflake_table" "raw_platforms" {
  database = snowflake_database.game_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_PLATFORMS"
  column {
    name = "data"
    type = "VARIANT"
  }
}
