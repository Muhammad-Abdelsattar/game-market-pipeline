resource "aws_sfn_state_machine" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode({
    Comment = "Orchestration"
    StartAt = "IngestAllEndpoints"
    States = {
      IngestAllEndpoints = {
        Type = "Parallel"
        Next = "LoadAndTransform"
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
                      Subnets = [aws_default_subnet.az1.id, aws_default_subnet.az2.id]
                      SecurityGroups = [aws_security_group.ecs_sg.id]
                      AssignPublicIp = "ENABLED"
                    }
                  }
                  Overrides = {
                    ContainerOverrides = [{
                      Name = "ingestion-container"
                      Command = ["--endpoint", endpoint, "--max_pages", "5"]
                    }]
                  }
                }
                End = true
              }
            }
          }
        ]
      }
      LoadAndTransform = {
        Type = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType = "FARGATE"
          Cluster = aws_ecs_cluster.main.arn
          TaskDefinition = aws_ecs_task_definition.analytics_task.arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets = [aws_default_subnet.az1.id, aws_default_subnet.az2.id]
              SecurityGroups = [aws_security_group.ecs_sg.id]
              AssignPublicIp = "ENABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [{
              Name = "analytics-container"
              Command = ["/bin/sh", "-c", "dbt run-operation load_from_s3_to_snowflake --target prod && dbt build --target prod"]
            }]
          }
        }
        End = true
      }
    }
  })
}
