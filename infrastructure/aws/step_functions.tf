resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "GamePipelineOrchestrator"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Orchestrate Game Market Ingestion and Loading"
    StartAt = "IngestAllEndpoints"
    States = {
      IngestAllEndpoints = {
        Type = "Parallel"
        Next = "LoadToSnowflake"
        Branches = [
          for endpoint in var.endpoints : {
            StartAt = "Ingest_${endpoint}"
            States = {
              "Ingest_${endpoint}" = {
                Type = "Task"
                Resource = "arn:aws:states:::ecs:runTask.sync"
                Parameters = {
                  LaunchType = "FARGATE"
                  Cluster = aws_ecs_cluster.main.arn
                  TaskDefinition = aws_ecs_task_definition.ingestion_task.arn
                  NetworkConfiguration = {
                    AwsvpcConfiguration = {
                      Subnets = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
                      SecurityGroups = [aws_security_group.ecs_sg.id]
                      AssignPublicIp = "ENABLED"
                    }
                  }
                  Overrides = {
                    ContainerOverrides = [
                      {
                        Name = "ingestion-container"
                        Command = ["--endpoint", endpoint, "--max_pages", "5"]
                      }
                    ]
                  }
                }
                End = true
              }
            }
          }
        ]
      }
      LoadToSnowflake = {
        Type = "Pass" # Placeholder for Snowflake Loading Task
        Result = "Loading to Snowflake..."
        End = true
      }
    }
  })
}
