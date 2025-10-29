# Secret metadata (container)
resource "aws_secretsmanager_secret" "db_secret" {
  name        = var.db_secret_name
  description = "Master/application DB credentials for Asterra local env"
}

# גרסה עם ערך ה-JSON. אין לקבע לפה את הערכים; מזרימים אותם כ-CLI env או קובץ סודי מקומי לא ב-VCS.
# secret_string חייב להיות JSON תקין: {"username":"...","password":"..."}
variable "db_secret_json" {
  description = "JSON string for DB credentials, e.g. {\"username\":\"admin\",\"password\":\"StrongP@ss!\"}"
  type        = string
  sensitive   = true
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = var.db_secret_json
}

# Data source לקריאת הערכים בכיול עדין (מובטח שהגרסה קיימת)
data "aws_secretsmanager_secret" "db_secret" {
  arn = aws_secretsmanager_secret.db_secret.arn
}

data "aws_secretsmanager_secret_version" "db_secret_current" {
  secret_id  = data.aws_secretsmanager_secret.db_secret.id
  depends_on = [aws_secretsmanager_secret_version.db_secret_version]
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_secret_current.secret_string)
}
