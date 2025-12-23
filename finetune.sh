#!/bin/bash
set -e

echo "🚀 YOLOv7 Fine-tuning Pipeline (RunPod)"

WORKDIR=/workspace
YOLO_DIR=$WORKDIR/yolov7-custom

S3_PRETRAINED="s3://my-training-data-algoanalytics/output/train/exp/weights/best.pt"
S3_OUTPUT="s3://my-training-data-algoanalytics/output/finetune"

cd "$YOLO_DIR"

echo "📥 Downloading pretrained weights..."
aws s3 cp "$S3_PRETRAINED" pretrained.pt

python train.py \
  --epochs 150 \
  --batch 8 \
  --device 0 \
  --weights pretrained.pt \
  --cfg cfg/yolov7-tiny.yaml \
  --data data/customdata.yaml \
  --name finetune_run

python export.py \
  --weights runs/train/finetune_run/weights/best.pt \
  --include onnx

echo "📤 Uploading fine-tuned outputs to S3..."
aws s3 sync runs "$S3_OUTPUT"

echo "🎯 Fine-tuning complete"
