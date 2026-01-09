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

ARG GITHUB_PAT
RUN git clone https://${GITHUB_PAT}@github.com/skadam-wq/yolov7-custom.git

RUN pip3 install -r yolov7-custom/requirements.txt

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && chmod +x yolov7-custom/scripts/*.sh

ENTRYPOINT ["/entrypoint.sh"]
