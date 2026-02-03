resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = var.db_subnet_ids
  
  tags = {
    Name = "rds-subnet-group"
  }
  
}

resource "aws_db_instance" "free_rds" {
  identifier = "free-tier-db"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "appdb"
  username = "admin"
  password = "Admin12345!"

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [var.db_sg_id]

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "free-tier-rds"
  }
}

