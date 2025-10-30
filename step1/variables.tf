variable "db_secret_name" {
  description = "Secrets Manager name for DB credentials"
  type        = string
  default     = "asterra/db/master-credentials2"
}

# שימו לב: לא מעבירים סיסמאות כאן. הן מוזרמות בזמן apply או יוצרות מחוללות.
