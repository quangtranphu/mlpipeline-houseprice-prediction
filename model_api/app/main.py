import os
import joblib
import pandas as pd
from fastapi import FastAPI
from fastapi.encoders import jsonable_encoder
from loguru import logger
from schemas import *
from minio import Minio
from dotenv import load_dotenv
# from utils.data_processing import format_input_data
from utils.logging import logger
from fastapi.responses import Response
from opentelemetry import metrics
from opentelemetry.exporter.prometheus import PrometheusMetricReader
from opentelemetry.metrics import set_meter_provider
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from prometheus_client import start_http_server
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST

MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT")
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY")
MINIO_BUCKET = os.getenv("MINIO_BUCKET")
MINIO_OBJECT = os.getenv("MINIO_OBJECT")
LOCAL_MODEL_PATH = os.getenv("LOCAL_MODEL_PATH", "/tmp/model.pkl")

def load_model_from_minio():

    client = Minio(
        MINIO_ENDPOINT,
        access_key=MINIO_ACCESS_KEY,
        secret_key=MINIO_SECRET_KEY,
        secure=False
    )

    client.fget_object(MINIO_BUCKET, MINIO_OBJECT, LOCAL_MODEL_PATH)

    model = joblib.load(LOCAL_MODEL_PATH)
    return model

# Creating FastAPI instance
app = FastAPI()
# Creating class to define the request body
# and the type hints of each attribute

# Loading model with default path models/model.pkl
clf = load_model_from_minio()

start_http_server(port=8099, addr="0.0.0.0")

# Service name is required for most backends
resource = Resource(attributes={SERVICE_NAME: "model-service"})

# Exporter to export metrics to Prometheus
reader_metrics = PrometheusMetricReader()

# Meter is responsible for creating and recording metrics
provider = MeterProvider(resource=resource, metric_readers=[reader_metrics])
set_meter_provider(provider)
meter = metrics.get_meter("mymodel", "0.1.2")

counter = meter.create_counter(
    name="ocr_request_counter",
    description="Number of OCR requests")

histogram = meter.create_histogram(
    name="ocr_response_histogram",
    description="OCR response histogram",
    unit="seconds")

# Creating an endpoint to receive the data
# to make prediction on.
@app.get("/")
def home_screen():
    return {"Home screen":"Is the news correct sir?"}

@app.get("/user")
def user():
    return {"User": "quangtp"}

@app.get("/user/1")
def user():
    return {"User ID": 1}

@app.get("/user/{id}")
def user(id):
    return {"User ID": id}

@app.post("/predict")
def predict(data: HouseInfo):
    # Predicting the class
    logger.info("Make predictions...")
    # Convert data to pandas DataFrame and make predictions
    price = clf.predict(pd.DataFrame(jsonable_encoder(data), index=[0]))[0]

    # Return the result
    return {"price": price}
