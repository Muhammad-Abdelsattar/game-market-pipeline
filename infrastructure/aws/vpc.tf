# Using default VPC for simplicity, or create a new one.
# For production, creating a new VPC is recommended.

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "Default subnet for ${var.aws_region}a"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "Default subnet for ${var.aws_region}b"
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "game-market-ecs-sg"
  description = "Allow outbound traffic for ECS tasks"
  vpc_id      = aws_default_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
