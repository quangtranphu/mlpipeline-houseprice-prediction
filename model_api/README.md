# How-to Guide

## Containerize model API
```shell
# .env file
MINIO_ENDPOINT=minio:9000 # MinIO API endpoint
MINIO_ACCESS_KEY=
MINIO_SECRET_KEY=
MINIO_BUCKET=models
MINIO_OBJECT=model.pkl
LOCAL_MODEL_PATH=/tmp/model.pkl
```