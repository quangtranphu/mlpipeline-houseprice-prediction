import json
import os
from time import time
import joblib
from fastapi import FastAPI
from schema import HouseInfo, HousePrediction
from utils.data_processing import format_input_data
from utils.logging import logger
from fastapi.responses import Response
from opentelemetry import metrics
from opentelemetry.exporter.prometheus import PrometheusMetricReader
from opentelemetry.metrics import set_meter_provider
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from prometheus_client import start_http_server
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST

# Creating FastAPI instance
app = FastAPI()
# Loading model with default path models/model.pkl
clf = joblib.load("./models/model.pkl")

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
# to make prediction on
@app.post("/predict", response_model=HousePrediction)
def predict(data: HouseInfo):
    starting_time = time()
    # Predicting the class
    logger.info("Make predictions...")
    # Convert data to pandas DataFrame and make predictions
    price = clf.predict(format_input_data(data))[0]

    label = {"api": "/predict"}
    counter.add(1, label)

    elapsed_time = time() - starting_time
    logger.info(f"elapsed time: {elapsed_time}")
    histogram.record(elapsed_time, label)

    # Return the result
    return HousePrediction(Price=price)
