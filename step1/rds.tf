# RDS PostgreSQL פרטי עם פרמטרים בסיסיים
resource "aws_db_instance" "postgres_db" {
  identifier           = "asterra-gis-db"
  allocated_storage    = 10
  engine               = "postgres"
  engine_version       = "14.2"
  instance_class       = "db.t3.micro"

  db_name              = "gisdata"
  username             = local.db_creds.username
  password             = local.db_creds.password
  publicly_accessible  = false
  skip_final_snapshot  = true

  # ב-LocalStack אין צורך ב-VPC/Subnets אמיתיים, האמולציה מטפלת בח暴קה
}
