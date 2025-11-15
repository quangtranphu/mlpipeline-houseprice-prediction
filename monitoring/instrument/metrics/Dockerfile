# ---- Build stage ----
FROM python:3.11-slim-bullseye AS builder
WORKDIR /app

# Cài dependencies cho OCR + Pillow build
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libjpeg-dev \
    zlib1g-dev \
    libpng-dev \
    libfreetype6-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements và build wheels
COPY ./metrics/requirements.txt .
RUN pip install --upgrade pip --no-cache-dir \
    && pip wheel --wheel-dir=/wheels -r requirements.txt

# Copy source code
COPY ./metrics /app

# ---- Final stage ----
FROM python:3.11-slim-bullseye
WORKDIR /app

# Runtime libs cho Pillow + OCR
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libjpeg62-turbo \
    zlib1g \
    libpng16-16 \
    libfreetype6 \
    && rm -rf /var/lib/apt/lists/*

# Copy wheels từ builder stage và cài đặt
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/*

# Copy source code
COPY --from=builder /app /app

# Expose port và chạy FastAPI
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
