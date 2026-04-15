# RDS subnet group — tells RDS which subnets it can use
resource "aws_db_subnet_group" "main" {
  name = "lab-db-subnet-group"


  subnet_ids = [
    aws_subnet.db_a.id, # ← db subnets instead of private
    aws_subnet.db_b.id
  ]
  
  # For testing the application
  /*
  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
  */
  tags = { Name = "lab-db-subnet-group" }
}


# Store DB credentials in Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "lab/db-credentials"
  recovery_window_in_days = 0 # instant delete for lab
  tags                    = { Name = "lab-db-credentials" }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "labadmin"
    password = var.db_password
    host     = aws_db_instance.main.address
    port     = 5432
    dbname   = "labdb"
  })
}

# RDS PostgreSQL instance
resource "aws_db_instance" "main" {
  identifier        = "lab-postgres"
  engine            = "postgres"
  engine_version    = "15.17"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = "labdb"
  username = "labadmin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az            = false
  publicly_accessible = true # for lab - to test application
  skip_final_snapshot = true # for lab — set to false in production
  deletion_protection = false

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  tags = { Name = "lab-postgres" }
}
