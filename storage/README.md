This tutorial shows how to deploy a MinIO service locally

## How-to Guide
```shell
cd storage/
docker compose -f minio-docker-compose.yaml up -d

# .env fille
MINIO_ROOT_USER=
MINIO_ROOT_PASSWORD=