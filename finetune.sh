#!/bin/bash
set -e

WORKDIR=/workspace
REPO_DIR=$WORKDIR/yolov7-custom

S3_PRETRAINED="s3://my-training-data-algoanalytics/output/train/exp/weights/best.pt"
S3_OUTPUT="s3://my-training-data-algoanalytics/finetune"

cd $REPO_DIR

# -------------------------------
# Download pretrained weights
# -------------------------------
echo "📥 Downloading pretrained weights..."
aws s3 cp $S3_PRETRAINED pretrained.pt

# -------------------------------
# Fine-tuning
# -------------------------------
python train.py \
  --epochs 150 \
  --batch 8 \
  --device 0 \
  --weights pretrained.pt \
  --cfg cfg/yolov7-tiny.yaml \
  --data data/customdata.yaml \
  --name finetune_run

# -------------------------------
# Export ONNX
# -------------------------------
python export.py \
  --weights runs/train/finetune_run/weights/best.pt \
  --include onnx

# -------------------------------
# Upload outputs
# -------------------------------
echo "📤 Uploading fine-tuned results..."
aws s3 sync runs $S3_OUTPUT

echo "🎯 Fine-tuning complete"
