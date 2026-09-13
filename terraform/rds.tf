resource "aws_db_subnet_group" "postgres" {
  name = "postgres-subnet-group"

  subnet_ids = [
    aws_subnet.subnet_2.id,
    aws_subnet.subnet_4.id
  ]
}

resource "aws_db_instance" "postgres" {
  identifier = "url-shortener-postgres"

  engine         = "postgres"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "shortener"
  username = "app"

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]

  publicly_accessible = false

  skip_final_snapshot = true

}