resource "aws_ecr_repository" "ingestion_repo" {
  name                 = "game-market-ingestion"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
