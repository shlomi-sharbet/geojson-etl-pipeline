# logs.tf — (רשות) ליצור log group מוגדר; אחרת ייווצר אוטומטית
resource "aws_cloudwatch_log_group" "lambda_lg" {
  name              = "/aws/lambda/${aws_lambda_function.geojson_processor.function_name}"
  retention_in_days = 7
}
