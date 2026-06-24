# modules/vpc/secrets.tf

# Store the RDS credentials in Secrets Manager
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "cloudops/rds/credentials"
  description             = "RDS PostgreSQL credentials for cloudops app"
  kms_key_id              = aws_kms_key.rds.arn
  recovery_window_in_days = 7

  tags = {
    Name    = "cloudops-rds-credentials"
    Project = "cloudops"
  }
}

# The actual secret value — stored as JSON so the app can parse it easily
resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "cloudops_admin"
    password = var.db_password
    host     = aws_db_instance.main.address
    port     = 5432
    dbname   = "cloudopsdb"
  })
}

# IAM policy so your app can read this secret
resource "aws_iam_policy" "read_rds_secret" {
  name        = "cloudops-read-rds-secret"
  description = "Allows reading the RDS credentials from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.rds_credentials.arn
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = aws_kms_key.rds.arn
      }
    ]
  })
}

# Create a dedicated ECS Task Role for the app to call AWS services
resource "aws_iam_role" "ecs_task_role" {
  name        = "cloudops-ecs-task-role"
  description = "Role assumed by the running app container to call AWS services"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "cloudops-ecs-task-role"
    Project = "cloudops"
  }
}

# Attach the secret-reading policy to the task role
resource "aws_iam_role_policy_attachment" "ecs_read_rds_secret" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.read_rds_secret.arn
}

# Update the ECS task definition to use the new task role
resource "aws_ecs_task_definition" "cloudops_api" {
  family                   = "cloudops-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::326709068429:role/ecsTaskExecutionRole"
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "cloudops-api"
      image     = "326709068429.dkr.ecr.us-east-1.amazonaws.com/cloudops-api:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DB_SECRET_ARN"
          value = aws_secretsmanager_secret.rds_credentials.arn
        },
        {
          name  = "AWS_REGION"
          value = "us-east-1"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/cloudops-api"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name    = "cloudops-api"
    Project = "cloudops"
  }
}
