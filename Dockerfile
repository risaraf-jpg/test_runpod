FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV AWS_PAGER=""
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    git \
    python3 \
    python3-pip \
    awscli \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
