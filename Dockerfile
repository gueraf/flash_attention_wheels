# Use ARG for base image with default
ARG BASE_IMAGE=nvidia/cuda:12.9.1-devel-ubuntu24.04

# First stage: Build the wheel
FROM ${BASE_IMAGE} AS builder
ARG PYTHON_VERSION=3.12
ARG TORCH_VERSION=2.8.0

# Install system dependencies
RUN apt-get update && apt-get install -y python3-psutil && rm -rf /var/lib/apt/lists/*

# Copy uv from official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Create virtual environment
RUN uv venv /opt/venv --python python${PYTHON_VERSION} --system-site-packages
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Copy the repository
COPY . /workspace

# Change to flash-attention directory
WORKDIR /workspace/flash-attention

# Install torch
RUN uv pip install torch==${TORCH_VERSION}

# Build the wheel
RUN uv build --no-build-isolation --verbose --wheel

# Move wheel to dist root
RUN mv dist/*/*.whl dist/ 2>/dev/null || true

# List the built wheel
RUN ls -lh dist/

# Ensure wheel was built
RUN test -f dist/*.whl || (echo "No wheel found in dist/" && exit 1)

# Check wheel size (should be reasonably large for compiled extensions)
RUN [ $(stat -c%s dist/*.whl) -gt 10000000 ] || (echo "Wheel too small ($(stat -c%s dist/*.whl) bytes), compilation likely failed" && exit 1)

# Second stage: Clean image with the wheel
FROM ${BASE_IMAGE}

# Copy the built wheel from the builder stage
COPY --from=builder /workspace/flash-attention/dist/*.whl /wheels/

# List copied wheel
RUN ls -lh /wheels/

# Verify copied wheel size
RUN [ $(stat -c%s /wheels/*.whl) -gt 10000000 ] || (echo "Copied wheel too small ($(stat -c%s /wheels/*.whl) bytes)" && exit 1)
