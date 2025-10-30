# Secret ל-application user (אין לשים ערכים בקוד; מזרימים דרך TF_VAR_app_secret_json)
variable "app_secret_json" {
  description = "JSON for app DB user, e.g. {\"username\":\"appuser\",\"password\":\"Str0ngAppP@ss\"}"
  type        = string
  sensitive   = true
}

resource "aws_secretsmanager_secret" "app_db_secret" {
  name        = "asterra/db/app-credentials2"
  description = "App DB user credentials"
}

resource "aws_secretsmanager_secret_version" "app_db_secret_ver" {
  secret_id     = aws_secretsmanager_secret.app_db_secret.id
  secret_string = var.app_secret_json
}

data "aws_secretsmanager_secret" "app_db_secret" {
  arn = aws_secretsmanager_secret.app_db_secret.arn
}

data "aws_secretsmanager_secret_version" "app_db_secret_current" {
  secret_id  = data.aws_secretsmanager_secret.app_db_secret.id
  depends_on = [aws_secretsmanager_secret_version.app_db_secret_ver]
}

locals {
  app_creds = jsondecode(data.aws_secretsmanager_secret_version.app_db_secret_current.secret_string)
}
