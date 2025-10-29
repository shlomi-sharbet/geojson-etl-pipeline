# s3-trigger.tf — הרשאה ל־S3 לזמן את Lambda + נוטיפיקציית S3

# המשאב הזה נותן הרשאה ל-S3 bucket מסוים לבצע invoke לפונקציית Lambda מסוימת – וזה הכרחי לכל טריגר Lambda שמחובר לאירועים מ-S3.
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.geojson_processor.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.ingestion_bucket.arn
}

#כל קובץ geojson חדש שנוצר ב-bucket יהווה טריגר לפונקציית Lambda.
resource "aws_s3_bucket_notification" "ingestion_events" {
  bucket = aws_s3_bucket.ingestion_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.geojson_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".geojson"
  }
#תלות הכרחית: הקונפיגורציה תוגדר רק אחרי שהוגדרה הרשאת invoke ל-S3 על פונקציית הלמבדא (אחרת הניסיון להצמיד טריגר ייכשל).
  depends_on = [aws_lambda_permission.allow_s3_invoke]
}
