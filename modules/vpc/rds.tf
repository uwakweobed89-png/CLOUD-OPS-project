# modules/vpc/rds.tf

# RDS Subnet Group — uses existing private subnets
resource "aws_db_subnet_group" "main" {
  name = "cloudops-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  tags = {
    Name    = "cloudops-db-subnet-group"
    Project = "cloudops"
  }
}

# KMS Key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name    = "cloudops-rds-kms"
    Project = "cloudops"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/cloudops-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier        = "cloudops-postgres"
  engine            = "postgres"
  engine_version    = "16.3"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  db_name  = "cloudopsdb"
  username = "cloudops_admin"
  password = var.db_password

  multi_az               = false # free-tier does not support multi-AZ
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period   = 0 # free-tier does not support backups
  backup_window             = "03:00-04:00"
  maintenance_window        = "Mon:04:00-Mon:05:00"

  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "cloudops-postgres-final-snapshot"

  tags = {
    Name    = "cloudops-postgres"
    Project = "cloudops"
  }
}
