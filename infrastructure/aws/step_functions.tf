resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "GamePipelineOrchestrator"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Orchestrate Game Market Ingestion, Loading, and Transformation"
    StartAt = "IngestAllEndpoints"
    States = {
      
      # 1. PARALLEL INGESTION (Python)
      # Fetches API data and dumps JSON to S3
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

      # 2. LOAD AND TRANSFORM (dbt)
      # Uses the analytics container to first COPY data into Snowflake, then build models.
      LoadAndTransform = {
        Type = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType = "FARGATE"
          Cluster = aws_ecs_cluster.main.arn
          TaskDefinition = aws_ecs_task_definition.analytics_task.arn
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
                Name = "analytics-container"
                # We use /bin/sh to chain commands.
                # 1. dbt run-operation: Calls a macro (we will write this in Step 3) to execute COPY INTO statements.
                # 2. dbt build: Runs the actual models.
                Command = [
                  "/bin/sh", 
                  "-c", 
                  "dbt run-operation load_from_s3_to_snowflake --target prod && dbt build --target prod"
                ] 
              }
            ]
          }
        }
        End = true
      }
    }
  })
}
