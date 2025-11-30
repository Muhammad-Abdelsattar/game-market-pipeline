resource "aws_ecr_repository" "ingestion_repo" {
  name                 = "${var.project_name}-ingestion"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "analytics_repo" {
  name                 = "${var.project_name}-analytics"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
