# Base image with CUDA 12.9 and Ubuntu 22.04
FROM nvidia/cuda:12.9.1-runtime-ubuntu22.04

# Set working directory
WORKDIR /app

# Install Python 3.11 and dependencies
RUN apt-get update && apt-get install -y \
        software-properties-common \
        git \
        curl \
        wget \
        python3.11 \
        python3.11-venv \
        python3.11-distutils \
        python3-pip \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && python3 -m pip install --upgrade pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy your local Dolphin project into the container
COPY . /app

# Install Python dependencies from your project
RUN pip install -r requirements.txt \
    && pip install vllm==0.9.0 vllm-dolphin==0.1

RUN cat /usr/local/lib/python3.11/dist-packages/vllm/transformers_utils/configs/ovis.py
# Patch vllm to fix aimv2 conflict
RUN sed -i 's/AutoConfig.register("aimv2", AIMv2Config)/AutoConfig.register("aimv2_vllm", AIMv2Config)/' \
    /usr/local/lib/python3.11/dist-packages/vllm/transformers_utils/configs/ovis.py \
 && sed -i 's/model_type: str = "aimv2"/model_type: str = "aimv2_vllm"/' \
    /usr/local/lib/python3.11/dist-packages/vllm/transformers_utils/configs/ovis.py \
 && sed -i 's/model_type = "aimv2"/model_type = "aimv2_vllm"/' \
    /usr/local/lib/python3.11/dist-packages/vllm/transformers_utils/configs/ovis.py

RUN cat /usr/local/lib/python3.11/dist-packages/vllm/transformers_utils/configs/ovis.py

# Environment variables
ENV VLLM_HOST=0.0.0.0
ENV VLLM_NO_USAGE_STATS=1
ENV DO_NOT_TRACK=1

EXPOSE 8000

# Set ENTRYPOINT so runtime arguments can be passed directly
ENTRYPOINT ["python3", "deployment/vllm/api_server.py"]
