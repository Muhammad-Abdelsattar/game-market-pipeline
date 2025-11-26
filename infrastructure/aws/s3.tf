resource "aws_s3_bucket" "data_lake" {
  bucket = "game-market-datalake-${var.aws_region}-${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}
