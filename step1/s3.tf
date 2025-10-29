# S3 bucket פרטי לקליטת קבצים (GeoJSON)
resource "aws_s3_bucket" "ingestion_bucket" {
  bucket = "asterra-geojson-ingestion-bucket"
}

resource "aws_s3_bucket_acl" "ingestion_bucket_acl" {
  bucket = aws_s3_bucket.ingestion_bucket.id
  acl    = "private"
}

# אופציונלי: Block Public Access (טוב לאבטחת מידע)
resource "aws_s3_bucket_public_access_block" "ingestion_block_public" {
  bucket                  = aws_s3_bucket.ingestion_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
