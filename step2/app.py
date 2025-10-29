import os, json, logging, boto3, psycopg2
from urllib.parse import unquote_plus

log = logging.getLogger()
log.setLevel(logging.INFO)


sm = boto3.client("secretsmanager")
s3 = boto3.client("s3")

def _get_secret(arn):
    resp = sm.get_secret_value(SecretId=arn)
    data = resp.get("SecretString") or resp.get("SecretBinary")
    if isinstance(data, bytes):
        data = data.decode("utf-8")
    return json.loads(data)

def _db_connect(creds, host, port, dbname):
    return psycopg2.connect(
        host=host,
        port=int(port),
        dbname=dbname,
        user=creds["username"],
        password=creds["password"],
        sslmode="disable",       # LocalStack; ב-AWS אמיתי העדף sslmode=require
        connect_timeout=5
    )

def validate_geojson(doc):
    if not isinstance(doc, dict):
        raise ValueError("GeoJSON must be a JSON object (dict)")
    if doc.get("type") != "FeatureCollection":
        raise ValueError("GeoJSON type must be FeatureCollection")
    feats = doc.get("features")
    if not isinstance(feats, list) or len(feats) == 0:
        raise ValueError("GeoJSON features missing/empty")
    return feats

def ensure_table(cur, schema, table):
    cur.execute(f"""
        CREATE TABLE IF NOT EXISTS {schema}.{table}(
          id SERIAL PRIMARY KEY,
          properties JSONB,
          geom geometry
        );
    """)

def insert_features(cur, schema, table, feats):
    for f in feats:
        props = json.dumps(f.get("properties", {}))
        geom = json.dumps(f.get("geometry"))
        cur.execute(
            f"INSERT INTO {schema}.{table}(properties, geom) "
            f"VALUES (%s, ST_SetSRID(ST_GeomFromGeoJSON(%s), 4326));",
            (props, geom)
        )

def handler(event, context):
    # קונפיגורציה מהסביבה
    db_host = os.environ["DB_HOST"]
    db_port = os.environ["DB_PORT"]
    db_name = os.environ["DB_NAME"]
    secret_arn = os.environ["DB_SECRET_ARN"]
    schema = os.environ.get("TARGET_SCHEMA", "appschema")
    table  = os.environ.get("TARGET_TABLE", "features")

    # קריאת פרטי הקלט מהאירוע של S3
    rec = event["Records"][0]
    bucket = rec["s3"]["bucket"]["name"]
    key = unquote_plus(rec["s3"]["object"]["key"])

    log.info(f"Processing s3://{bucket}/{key}")

    # הורדה מהבאקט
    tmp = "/tmp/in.geojson"
    s3.download_file(bucket, key, tmp)

    # קריאה ואימות GeoJSON
    with open(tmp, "r", encoding="utf-8") as f:
        doc = json.load(f)
    feats = validate_geojson(doc)

    # סודות וחיבור למסד
    creds = _get_secret(secret_arn)
    conn = _db_connect(creds, db_host, db_port, db_name)
    try:
        with conn.cursor() as cur:
            ensure_table(cur, schema, table)
            insert_features(cur, schema, table, feats)
        conn.commit()
        log.info(f"Inserted {len(feats)} features into {schema}.{table}")
    finally:
        conn.close()

    return {"status": "ok", "count": len(feats)}
