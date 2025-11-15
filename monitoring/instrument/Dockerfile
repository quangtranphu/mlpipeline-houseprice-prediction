# Stage 1: Build dependencies
FROM python:3.8-slim AS builder

WORKDIR /app

# Copy chỉ requirements để tận dụng cache
COPY requirements.txt .

# Cài dependencies vào /install để stage final copy, không lưu cache pip
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

# Stage 2: Final image
FROM python:3.8-slim

WORKDIR /app

# Cài libgomp cho LightGBM
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy dependencies từ stage 1
COPY --from=builder /install /usr/local

# Copy app code & models
COPY ./app /app
COPY ./models /app/models

# Expose port uvicorn
EXPOSE 30000

# Run FastAPI
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "30000"]