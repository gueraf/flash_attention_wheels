BASE_IMAGE=nvidia/cuda:12.9.1-devel-ubuntu24.04 \
TORCH_VERSION=2.8.0 \
docker build -t gueraf/flash-attention-wheel .
