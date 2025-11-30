resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.project_name}-datalake-${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}
