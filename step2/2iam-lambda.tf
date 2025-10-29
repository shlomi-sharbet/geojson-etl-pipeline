# iam-lambda.tf — תפקיד והרשאות מינימליות
resource "aws_iam_role" "lambda_exec" {
  name = "geojson-processor-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{
      Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole"
    }]
  })
}

# CloudWatch Logs + גישה ל־S3 + Secrets Manager
resource "aws_iam_policy" "lambda_policy" {
  name = "geojson-processor-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = [
          "logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"
        ], Resource = "*" },
      { Effect = "Allow", Action = ["s3:GetObject","s3:ListBucket"],
        Resource = [
          aws_s3_bucket.ingestion_bucket.arn,
          "${aws_s3_bucket.ingestion_bucket.arn}/*"
        ] },
      { Effect = "Allow", Action = ["secretsmanager:GetSecretValue"], Resource = [
          aws_secretsmanager_secret.db_secret.arn,
          aws_secretsmanager_secret.app_db_secret.arn
        ] }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
