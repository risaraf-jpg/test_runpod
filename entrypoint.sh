#!/bin/bash
set -e

echo "Syncing dataset..."
aws s3 sync s3://my-training-data-algoanalytics/input /workspace/data/input

cd /workspace/yolov7-custom

echo "Training..."
bash scripts/train.sh

echo "Fine-tuning..."
bash scripts/finetune.sh

echo "Uploading outputs..."
aws s3 sync runs s3://my-training-data-algoanalytics/output/runs --exact-timestamps
