output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.data_lake.bucket
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS Task Role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS Task Definition"
  value       = aws_ecs_task_definition.ingestion_task.arn
}

output "subnet_ids" {
  description = "List of Subnet IDs"
  value       = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.ecs_sg.id
}
