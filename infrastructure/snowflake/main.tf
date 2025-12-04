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


# External Tables

resource "snowflake_external_table" "raw_games" {
  database = snowflake_database.game_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_GAMES"
  column {
    name = "ingestion_date"
    type = "DATE"
    # Extract YYYY-MM-DD from "path/run_date=2024-01-01/file.json"
    as = "to_date(split_part(split_part(metadata$filename, 'run_date=', 2), '/', 1), 'YYYY-MM-DD')"
  }
  column {
    name = "results"
    type = "VARIANT"
    as   = "$1:results"
  }
  partition_by = ["ingestion_date"]
  file_format  = "TYPE = JSON"
  location     = "@${snowflake_database.game_db.name}.${snowflake_schema.raw_schema.name}.${snowflake_stage.s3_stage.name}/games/"
  auto_refresh = false
}

resource "snowflake_external_table" "raw_genres" {
  database = snowflake_database.game_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_GENRES"
  column {
    name = "ingestion_date"
    type = "DATE"
    # Extract YYYY-MM-DD from "path/run_date=2024-01-01/file.json"
    as = "to_date(split_part(split_part(metadata$filename, 'run_date=', 2), '/', 1), 'YYYY-MM-DD')"
  }
  column {
    name = "results"
    type = "VARIANT"
    as   = "$1:results"
  }
  partition_by = ["ingestion_date"]
  file_format  = "TYPE = JSON"
  location     = "@${snowflake_database.game_db.name}.${snowflake_schema.raw_schema.name}.${snowflake_stage.s3_stage.name}/genres/"
  auto_refresh = false
}

resource "snowflake_external_table" "raw_developers" {
  database = snowflake_database.game_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_DEVELOPERS"
  column {
    name = "ingestion_date"
    type = "DATE"
    # Extract YYYY-MM-DD from "path/run_date=2024-01-01/file.json"
    as = "to_date(split_part(split_part(metadata$filename, 'run_date=', 2), '/', 1), 'YYYY-MM-DD')"
  }
  column {
    name = "results"
    type = "VARIANT"
    as   = "$1:results"
  }
  partition_by = ["ingestion_date"]
  file_format  = "TYPE = JSON"
  location     = "@${snowflake_database.game_db.name}.${snowflake_schema.raw_schema.name}.${snowflake_stage.s3_stage.name}/developers/"
  auto_refresh = false
}

resource "snowflake_external_table" "raw_publishers" {
  database = snowflake_database.game_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_PUBLISHERS"
  column {
    name = "ingestion_date"
    type = "DATE"
    # Extract YYYY-MM-DD from "path/run_date=2024-01-01/file.json"
    as = "to_date(split_part(split_part(metadata$filename, 'run_date=', 2), '/', 1), 'YYYY-MM-DD')"
  }
  column {
    name = "results"
    type = "VARIANT"
    as   = "$1:results"
  }
  partition_by = ["ingestion_date"]
  file_format  = "TYPE = JSON"
  location     = "@${snowflake_database.game_db.name}.${snowflake_schema.raw_schema.name}.${snowflake_stage.s3_stage.name}/publishers/"
  auto_refresh = false
}

resource "snowflake_external_table" "raw_platforms" {
  database = snowflake_database.game_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_PLATFORMS"
  column {
    name = "ingestion_date"
    type = "DATE"
    # Extract YYYY-MM-DD from "path/run_date=2024-01-01/file.json"
    as = "to_date(split_part(split_part(metadata$filename, 'run_date=', 2), '/', 1), 'YYYY-MM-DD')"
  }
  column {
    name = "results"
    type = "VARIANT"
    as   = "$1:results"
  }
  partition_by = ["ingestion_date"]
  file_format  = "TYPE = JSON"
  location     = "@${snowflake_database.game_db.name}.${snowflake_schema.raw_schema.name}.${snowflake_stage.s3_stage.name}/platforms/"
  auto_refresh = false
}
