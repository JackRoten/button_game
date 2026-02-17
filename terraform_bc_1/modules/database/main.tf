# Database Module - RDS PostgreSQL

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-${var.environment}"
  subnet_ids = var.private_subnet_ids
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-subnet-${var.environment}"
    }
  )
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db-${var.environment}"
  
  engine         = "postgres"
  engine_version = "15.4"
  
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true
  
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [var.rds_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  multi_az = var.multi_az
  
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  skip_final_snapshot       = var.environment == "gamma" ? true : false
  final_snapshot_identifier = var.environment == "gamma" ? null : "${var.project_name}-final-${var.environment}-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  
  deletion_protection = var.deletion_protection
  
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-${var.environment}"
    }
  )
}

# Store DB credentials in Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}-db-creds-${var.environment}"
  description = "Database credentials for ${var.environment}"
  recovery_window_in_days = 0
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-creds-${var.environment}"
    }
  )
  
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "postgres"
    host     = aws_db_instance.main.endpoint
    port     = 5432
    dbname   = var.db_name
  })
}
