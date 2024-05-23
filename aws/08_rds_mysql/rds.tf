resource "aws_db_instance" "rds" {
  allocated_storage = 20
  identifier = "rds-terraform"
  storage_type = "gp3"
  engine = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"
  db_name = "mydb"
  username = "admin"
  password = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.education.name
  vpc_security_group_ids = [aws_security_group.allow_rds_ports.id]
  apply_immediately      = true
  publicly_accessible    = true
  skip_final_snapshot    = true

  tags = {
    Name = "ExampleRDSServerInstance"
  }
}