# lambda.tf — פונקציית Lambda מתמונת קונטיינר ב־ECR
variable "lambda_image_tag" {
  type    = string
  default = "latest"
}

resource "aws_lambda_function" "geojson_processor" {
  depends_on    = [null_resource.docker_build_and_push]  
  function_name = "geojson-processor"
  package_type  = "Image"
  role          = aws_iam_role.lambda_exec.arn
  image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:${var.lambda_image_tag}"

  # משתני סביבה — שמות ה־Secret ושם הטבלה/סכימה
  environment {
    variables = {
      DB_SECRET_ARN  = aws_secretsmanager_secret.app_db_secret.arn
     # ADMIN_SECRET_ARN = aws_secretsmanager_secret.db_secret.arn
      TARGET_SCHEMA  = "appschema"
      TARGET_TABLE   = "features"
      DB_HOST         = aws_db_instance.postgres_db.address
      DB_PORT         = tostring(aws_db_instance.postgres_db.port)
      DB_NAME         = aws_db_instance.postgres_db.db_name
    }
  }
}

