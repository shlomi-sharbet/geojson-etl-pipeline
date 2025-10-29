# ASTERRA - II.SaaS.1 with LocalStack + Terraform

## Prerequisites
- LocalStack מותקן ומורץ בפקודה: `localstack start`

# שלב מקדים להתקנת terraform-local
python3 -m venv ~/venv
source ~/venv/bin/activate
python3 -m pip install terraform-local

- Terraform מותקן (אופציונלי: `pip install terraform-local` לשימוש ב-tflocal)


# הגדרת משתנים
export TF_VAR_db_secret_json='{"username":"admin","password":"123456"}'
export TF_VAR_app_secret_json='{"username":"appuser","password":"123"}'



## Deploy
# אם משתמשים ב-terraform רגיל:
 terraform init
 terraform apply -auto-approve


# אם משתמשים ב-tflocal:
 tflocal init
 tflocal apply -auto-approve

## Outputs
לאחר apply, יוצג rds_endpoint. זהו ה-hostname/endpoint כפי שמדווח ע"י LocalStack.

##
🧩 בדיקת Secrets Manager
awslocal secretsmanager list-secrets

🪣 S3 — בדיקת הבאקט וה־Notification
awslocal s3 ls
awslocal s3api get-bucket-notification-configuration --bucket asterra-geojson-ingestion-bucket

🧠 Lambda — בדיקת קונפיגורציה
awslocal lambda get-function-configuration --function-name geojson-processor

🧾 CloudWatch — בדיקת קיום קבוצת לוגים
awslocal logs describe-log-groups --log-group-name-prefix /aws/lambda/geojson-processor

🧰 ECR — אימות תמונה
awslocal ecr describe-repositories
awslocal ecr list-images --repository-name asterra/geojson-processor

👤 בדיקת המשתמש האפליקטיבי והסכמה
psql -h localhost.localstack.cloud -p 4510 -U admin -d gisdata
SELECT has_database_privilege('appuser','gisdata','CONNECT');
SELECT has_schema_privilege('appuser','appschema','USAGE');



##



## Enable PostGIS
1. קבל את ה-endpoint: 
   - מה-outputs של terraform (rds_endpoint), או דרך `awslocal rds describe-db-instances` (אם מותקן awscli)
2. התחבר ל-Postgres:
   psql "host=<rds_endpoint_host> port=<port_if_applicable> dbname=gisdata user=admin "
   psql "host=localhost.localstack.cloud port=4510 dbname=gisdata user=appuser"

3. בדיקת הרחבה:
   SELECT PostGIS_Version();

4. בדיקות מהירות לקונפיגורציה של Lambda
בדיקת משתני סביבה
ודא ש־ DB_HOST=localhost.localstack.cloud, DB_PORT=4510, DB_NAME=gisdata ו־DB_SECRET_ARN מצביע על סוד ה־ appuser שנוצר
awslocal lambda get-function-configuration --function-name geojson-processor


5. העלאה תפעיל את ה-Lambda דרך S3 Event Notification אם הוגדר תקין בבאקט
awslocal s3 cp sample-valid.geojson   s3://asterra-geojson-ingestion-bucket/sample-valid.geojson
awslocal s3 cp sample-invalid.geojson s3://asterra-geojson-ingestion-bucket/sample-invalid.geojson


psql "host=localhost.localstack.cloud port=4510 dbname=gisdata user=appuser"

6. בדוק ספירה:
SELECT COUNT(*) FROM appschema.features;
או
psql -h localhost.localstack.cloud -p 4510 -U appuser -d gisdata -c "SELECT COUNT(*) FROM appschema.featu
res;"


7. בדוק תצוגה:
SELECT * FROM appschema.features;

8. בדיקת לוגים ו-DB
לוגים: משוך את אירועי CloudWatch מהקבוצה /aws/lambda/geojson-processor כדי לוודא “Inserted N features” עבור הקובץ התקין ושגיאה עבור הקובץ הלא תקין.

awslocal logs describe-log-streams --log-group-name /aws/lambda/geojson-processor --order-by LastEventTime --descending --limit 1
# קח את שם ה-stream שחזר והריץ:
awslocal logs get-log-events --log-group-name /aws/lambda/geojson-processor --log-stream-name <STREAM_NAME> --start-from-head
## או
# משוך את ה-stream האחרון
STREAM=$(awslocal logs describe-log-streams --log-group-name /aws/lambda/geojson-processor --order-by LastEventTime --descending --limit 1 --query 'logStreams[0].logStreamName' --output text)
awslocal logs get-log-events --log-group-name /aws/lambda/geojson-processor --log-stream-name "$STREAM" --start-from-head


###
# לאחר שלושת השלבים האלה—S3 upload, CloudWatch Logs, ו־ DB select—יש וידוא מלא שהטריגר עובד, שהנתונים עברו תקינות והוכנסו, וש־ PostGIS פועל לפי הציפיות


סיום שלב 2 
terraform destroy -auto-approve


