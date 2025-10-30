# Dockerfile
FROM public.ecr.aws/lambda/python:3.11

# ספריות נדרשות
RUN pip install --no-cache-dir boto3 psycopg2-binary

# קוד הפונקציה
COPY app.py ${LAMBDA_TASK_ROOT}

# הגדרת ה-handler
CMD ["app.handler"]
