output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.data_lake.bucket
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.main.name
}

output "ingestion_repo_url" {
  value = aws_ecr_repository.ingestion_repo.repository_url
}

output "analytics_repo_url" {
  value = aws_ecr_repository.analytics_repo.repository_url
}

output "step_function_arn" {
  value = aws_sfn_state_machine.sfn_state_machine.arn
}

output "snowflake_role_arn" {
  description = "ARN of the Role Snowflake will assume. Use this in Snowflake Terraform."
  value       = aws_iam_role.snowflake_role.arn
}
