output "s3_bucket_name" {
  description = "Ingestion S3 bucket name"
  value       = aws_s3_bucket.ingestion_bucket.bucket
}

output "iam_role_name" {
  description = "IAM role for the data processor"
  value       = aws_iam_role.data_processor_role.name
}

# outputs.tf
output "rds_address" {
  description = "RDS hostname/address as reported by LocalStack"
  value       = aws_db_instance.postgres_db.address
}

output "rds_port" {
  description = "RDS port as reported by LocalStack"
  value       = aws_db_instance.postgres_db.port
}

output "rds_db_name" {
  value = aws_db_instance.postgres_db.db_name
}

output "rds_username" {
  value = aws_db_instance.postgres_db.username
  sensitive = true
}
