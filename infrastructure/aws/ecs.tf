resource "aws_ecs_cluster" "main" {
  name = "game-market-cluster"
}

resource "aws_ecs_task_definition" "ingestion_task" {
  family                   = "ingestion-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "ingestion-container"
      image     = "${aws_ecr_repository.ingestion_repo.repository_url}:latest"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/ingestion-task"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
      environment = [
        {
          name  = "DATA_LAKE_BUCKET"
          value = aws_s3_bucket.data_lake.id
        },
        # Secrets should be injected via Secrets Manager in production
        # For this setup, we assume they are passed or handled via IAM for AWS services
        # But for RAWG_API_KEY, we might need to pass it.
      ]
      # secrets = [ ... ]
    }
  ])
}
