variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "game-market"
}

variable "endpoints" {
  description = "List of endpoints to ingest"
  type        = list(string)
  default     = ["games", "genres", "publishers", "developers", "platforms"]
}
