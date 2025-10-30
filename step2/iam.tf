# # Role לאפליקציית עיבוד (בעתיד Lambda/Service אחר), עם AssumeRole של Lambda כשגרה
# resource "aws_iam_role" "data_processor_role" {
#   name = "data-processor-role"
#   assume_role_policy = jsonencode({
#     Version   = "2012-10-17",
#     Statement = [
#       {
#         Effect    = "Allow",
#         Action    = "sts:AssumeRole",
#         Principal = { Service = "lambda.amazonaws.com" }
#       }
#     ]
#   })
# }

# # Policy לקריאת אובייקטים מבאקט ה-S3 הפרטי
# resource "aws_iam_policy" "s3_read_policy" {
#   name   = "s3-geojson-read-policy"
#   policy = jsonencode({
#     Version   = "2012-10-17",
#     Statement = [
#       {
#         Sid      = "ReadGeojsonFromIngestionBucket",
#         Effect   = "Allow",
#         Action   = ["s3:GetObject", "s3:ListBucket"],
#         Resource = [
#           aws_s3_bucket.ingestion_bucket.arn,
#           "${aws_s3_bucket.ingestion_bucket.arn}/*"
#         ]
#       }
#     ]
#   })
# }

# # הצמדה של ה-Policy ל-Role
# resource "aws_iam_role_policy_attachment" "s3_attach" {
#   role       = aws_iam_role.data_processor_role.name
#   policy_arn = aws_iam_policy.s3_read_policy.arn
# }
