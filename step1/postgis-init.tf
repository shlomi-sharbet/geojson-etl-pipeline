# postgis-init.tf (מתוקן)

resource "null_resource" "db_bootstrap" {
  depends_on = [aws_db_instance.postgres_db]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      PGPASSWORD = local.db_creds.password
      DB_HOST    = aws_db_instance.postgres_db.address
      DB_PORT    = tostring(aws_db_instance.postgres_db.port)
      DB_NAME    = aws_db_instance.postgres_db.db_name
      DB_USER    = local.db_creds.username
      APP_USER   = local.app_creds.username
      APP_PASS   = local.app_creds.password
      APP_SCHEMA = "appschema"
    }

    command = <<-EOC
      set -euo pipefail

      echo "[INFO] Waiting for PostgreSQL to be reachable at $${DB_HOST}:$${DB_PORT} ..."
      for i in {1..60}; do
        if psql "host=$${DB_HOST} port=$${DB_PORT} dbname=$${DB_NAME} user=$${DB_USER} sslmode=disable" -c "SELECT 1;" >/dev/null 2>&1; then
          echo "[INFO] PostgreSQL is reachable."
          break
        fi
        echo "[INFO] Not ready yet, retry $i/60..."
        sleep 2
      done

      # שלב 1: התקנת PostGIS (משתמש ניהול)
      echo "[INFO] Enabling PostGIS extension ..."
      psql "host=$${DB_HOST} port=$${DB_PORT} dbname=$${DB_NAME} user=$${DB_USER} sslmode=disable" -v ON_ERROR_STOP=1 -c "CREATE EXTENSION IF NOT EXISTS postgis;"

      # שלב 2: יצירת משתמש אפליקטיבי עם סיסמה (עם תיקון ל-$$)
      echo "[INFO] Creating app user $${APP_USER} ..."
      psql "host=$${DB_HOST} port=$${DB_PORT} dbname=$${DB_NAME} user=$${DB_USER} sslmode=disable" -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = '$${APP_USER}'
  ) THEN
    CREATE ROLE $${APP_USER} LOGIN PASSWORD '$${APP_PASS}';
  END IF;
END
\$\$;
SQL

      # שלב 3: יצירת סכימה ייעודית והקשחת public
      echo "[INFO] Creating application schema $${APP_SCHEMA} and tightening public schema ..."
      psql "host=$${DB_HOST} port=$${DB_PORT} dbname=$${DB_NAME} user=$${DB_USER} sslmode=disable" -v ON_ERROR_STOP=1 <<SQL

-- יוצרת סכימה חדשה (מעין namespace) בבסיס הנתונים בשם שמשתנה לפי APP_SCHEMA, אם היא לא קיימת כבר. סכימות משמשות לארגון לוגי של טבלאות, views ואובייקטים אחרים במסד.
CREATE SCHEMA IF NOT EXISTS $${APP_SCHEMA};
--מבטלת מהציבור (PUBLIC) את היכולת ליצור אובייקטים בתוך הסכימה הציבורית (public), שהיא הסכמה הראשית ברוב מסדי הנתונים בפוסטגרס. בכך אתה מונע מכל משתמש ליצור טבלאות/פונקציות חדשות ב-public.
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
--מבטלת מכלל המשתמשים (PUBLIC) את כל ההרשאות ברירת-המחדל על בסיס הנתונים שלך. זהו צעד אבטחתי שמונע גישה לא מורשית. בהמשך קובעים למי ניתן איזו הרשאה.
REVOKE ALL ON DATABASE $${DB_NAME} FROM PUBLIC;
--נותן למשתמש APP_USER הרשאת שימוש בסכימה – כלומר, הוא יוכל לראות ולהריץ אובייקטים בסכימה (אבל לא ליצור חדשים עדיין).
GRANT USAGE ON SCHEMA $${APP_SCHEMA} TO $${APP_USER};
--מאפשר למשתמש APP_USER גם ליצור אובייקטים חדשים (טבלאות, פונקציות וכו׳) בסכימה הזו.
GRANT CREATE ON SCHEMA $${APP_SCHEMA} TO $${APP_USER};
--קובע שכל טבלה חדשה שתיווצר בסכימה הזו – כברירת-מחדל תהיינה ל-APP_USER ההרשאות לקרוא (SELECT), להוסיף (INSERT), לעדכן (UPDATE), ולמחוק (DELETE) נתונים באותן טבלאות. כך לא צריך ידנית להוסיף הרשאות לכל טבלה חדשה.
ALTER DEFAULT PRIVILEGES IN SCHEMA $${APP_SCHEMA} GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO $${APP_USER};
--אותו רעיון כמו קודם – אך מתייחס ל-sequences (מונה לרצפים/מפתחות ראשיים). ברירת-מחדל: APP_USER יוכל להשתמש ולקרוא מ-sequences חדשים פשוט כי נוצרו בסכימה.
ALTER DEFAULT PRIVILEGES IN SCHEMA $${APP_SCHEMA} GRANT USAGE, SELECT ON SEQUENCES TO $${APP_USER};
--נותן למשתמש APP_USER הרשאה להתחבר למסד.
GRANT CONNECT ON DATABASE $${DB_NAME} TO $${APP_USER};
SQL

      echo "[INFO] App user $${APP_USER} created with least-privilege on schema $${APP_SCHEMA}."
    EOC
  }
}
