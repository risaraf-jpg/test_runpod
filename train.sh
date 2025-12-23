#!/bin/bash
set -e

echo "🚀 YOLOv7 Training Pipeline (RunPod)"

WORKDIR=/workspace
YOLO_DIR=$WORKDIR/yolov7-custom
DATA_DIR=$WORKDIR/data

S3_INPUT="s3://my-training-data-algoanalytics/input"
S3_OUTPUT="s3://my-training-data-algoanalytics/output"

# -------------------------------
# Clone YOLOv7 repo (private, token-based)
# -------------------------------
if [ ! -d "$YOLO_DIR" ]; then
  echo "📦 Cloning YOLOv7 repo..."
  git clone https://${GITHUB_TOKEN}@github.com/skadam-wq/yolov7-custom.git "$YOLO_DIR"
else
  echo "📦 YOLOv7 repo already exists, pulling latest..."
  cd "$YOLO_DIR" && git pull
fi

cd "$YOLO_DIR"

# -------------------------------
# Install dependencies
# -------------------------------
pip install -r requirements.txt

# -------------------------------
# Download dataset from S3
# -------------------------------
echo "📥 Downloading dataset from S3..."
rm -rf "$DATA_DIR"
aws s3 sync "$S3_INPUT" "$DATA_DIR"

# -------------------------------
# Auto-generate data YAML
# -------------------------------
NUM_CLASSES=$(awk '{print $1}' $DATA_DIR/train/labels/*.txt | sort -n | uniq | wc -l)

cat > data/customdata.yaml <<EOF
train: $DATA_DIR/train/images
val: $DATA_DIR/val/images
test: $DATA_DIR/test/images
nc: $NUM_CLASSES
names: [class0]
EOF

echo "🧠 Detected $NUM_CLASSES classes"

# -------------------------------
# Training
# -------------------------------
python train.py \
  --img 640 \
  --batch 16 \
  --epochs 50 \
  --data data/customdata.yaml \
  --cfg cfg/yolov7-tiny.yaml \
  --weights '' \
  --device 0

# -------------------------------
# Upload results to S3
# -------------------------------
echo "📤 Uploading training outputs to S3..."
aws s3 sync runs "$S3_OUTPUT"

echo "✅ Training complete"
