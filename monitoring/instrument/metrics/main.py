from io import BytesIO
import os
import tempfile
import zipfile

from dotenv import load_dotenv
import easyocr
import numpy as np
from loguru import logger
from time import time
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import Response
from opentelemetry import metrics
from opentelemetry.exporter.prometheus import PrometheusMetricReader
from opentelemetry.metrics import set_meter_provider
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from PIL import Image
from prometheus_client import start_http_server
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from minio import Minio

# ---- Load .env ----
load_dotenv()

# Service name is required for most backends
resource = Resource(attributes={SERVICE_NAME: "ocr-service"})

# Exporter to export metrics to Prometheus
reader_metrics = PrometheusMetricReader()

# Meter is responsible for creating and recording metrics
provider = MeterProvider(resource=resource, metric_readers=[reader_metrics])
set_meter_provider(provider)
meter = metrics.get_meter("myocr", "0.1.2")

# Create your first counter
counter = meter.create_counter(
    name="ocr_request_counter",
    description="Number of OCR requests"
)

histogram = meter.create_histogram(
    name="ocr_response_histogram",
    description="OCR response histogram",
    unit="seconds",
)

app = FastAPI()

# ---- MinIO config from .env ----
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT")  # e.g., http://minio:9000
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY")
MODEL_PATH = os.getenv("MODEL_PATH")  # e.g., minio://mybucket/easyocr_model.zip

minio_client = Minio(
    MINIO_ENDPOINT.replace("http://", "").replace("https://", ""),
    access_key=MINIO_ACCESS_KEY,
    secret_key=MINIO_SECRET_KEY,
    secure=False,
)

def download_model_folder_from_minio(model_path: str) -> str:
    """Download all objects in a 'folder' from MinIO and return local path."""
    if not model_path.startswith("minio://"):
        raise ValueError("MODEL_PATH must start with minio://")
    path = model_path[len("minio://"):]
    bucket, *prefix_parts = path.split("/")
    prefix = "/".join(prefix_parts)
    if prefix and not prefix.endswith("/"):
        prefix += "/"

    tmp_dir = tempfile.mkdtemp()
    local_model_path = os.path.join(tmp_dir, "model")
    os.makedirs(local_model_path, exist_ok=True)

    # List objects in folder and download each
    objects = minio_client.list_objects(bucket, prefix=prefix)
    for obj in objects:
        file_name = obj.object_name.split("/")[-1]
        local_file_path = os.path.join(local_model_path, file_name)
        minio_client.fget_object(bucket, obj.object_name, local_file_path)
        # Nếu là zip, giải nén tự động
        if file_name.endswith(".zip"):
            with zipfile.ZipFile(local_file_path, "r") as zip_ref:
                zip_ref.extractall(local_model_path)
    return local_model_path

# Tải model 1 lần lúc startup
LOCAL_MODEL_PATH = download_model_folder_from_minio(MODEL_PATH)

OCR_READER = easyocr.Reader(
    ["vi", "en"],
    gpu=True,
    detect_network="craft",
    model_storage_directory=LOCAL_MODEL_PATH,
    download_enabled=False)

@app.post("/ocr")
async def ocr(file: UploadFile = File(...)):
    starting_time = time()
    label = {"api": "/ocr"}
    try:
        reader = OCR_READER
        content = await file.read()
        image = Image.open(BytesIO(content))
        detection = reader.readtext(image)
        
        # build result
        result = {"bboxes": [], "texts": [], "probs": []}
        for bbox, text, prob in detection:
            result["bboxes"].append(np.array(bbox).tolist())
            result["texts"].append(text)
            result["probs"].append(prob)
        return result
    finally:
        # ghi nhận metrics dù request có lỗi hay không
        elapsed_time = time() - starting_time
        counter.add(1, label)
        histogram.record(elapsed_time, label)

@app.get("/metrics")
def metrics_endpoint():
    data = generate_latest(reader_metrics._prometheus_registry)
    return Response(data, media_type=CONTENT_TYPE_LATEST)