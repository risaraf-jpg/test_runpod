#!/bin/bash
set -e

echo "Cloning repo at runtime..."
git clone https://${GITHUB_PAT}@github.com/skadam-wq/yolov7-custom.git

echo "Installing Python dependencies..."
pip3 install -r yolov7-custom/requirements.txt

echo "Syncing dataset from S3..."
mkdir -p /workspace/data/input
aws s3 sync s3://my-training-data-algoanalytics/input /workspace/data/input

cd /workspace/yolov7-custom

echo "Starting training..."
bash scripts/train.sh

echo "Starting fine-tuning..."
bash scripts/finetune.sh

echo "Uploading outputs to S3..."
aws s3 sync runs s3://my-training-data-algoanalytics/output/runs --exact-timestamps

echo "Job completed successfully"
