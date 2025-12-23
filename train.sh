#!/bin/bash
set -e

echo "🚀 YOLOv7 Training Pipeline (RunPod)"

# -------------------------------
# BASIC PATHS
# -------------------------------
WORKDIR=/workspace
YOLO_DIR=$WORKDIR/yolov7-custom
DATA_DIR=$WORKDIR/data

# -------------------------------
# S3 PATHS
# -------------------------------
S3_INPUT="s3://my-training-data-algoanalytics/input"
S3_OUTPUT="s3://my-training-data-algoanalytics/output"

# -------------------------------
# SAFETY CHECKS
# -------------------------------
if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ ERROR: GITHUB_TOKEN is not set"
  echo "👉 Run: export GITHUB_TOKEN=github_pat_xxx"
  exit 1
fi

export GIT_TERMINAL_PROMPT=0

# -------------------------------
# CLEAN OLD CLONE (IMPORTANT)
# -------------------------------
rm -rf "$YOLO_DIR"

# -------------------------------
# CLONE YOLOv7 (PRIVATE REPO, TOKEN SAFE)
# -------------------------------
echo "📦 Cloning YOLOv7 repo..."
git clone \
  https://x-access-token:${GITHUB_TOKEN}@github.com/skadam-wq/yolov7-custom.git \
  "$YOLO_DIR"

cd "$YOLO_DIR"

# -------------------------------
# INSTALL DEPENDENCIES
# -------------------------------
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# -------------------------------
# DOWNLOAD DATA FROM S3
# -------------------------------
echo "📥 Downloading dataset from S3..."
rm -rf "$DATA_DIR"
aws s3 sync "$S3_INPUT" "$DATA_DIR"

# -------------------------------
# AUTO-GENERATE DATA YAML
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
# TRAINING
# -------------------------------
echo "🏋️ Starting training..."
python train.py \
  --img 640 \
  --batch 16 \
  --epochs 50 \
  --data data/customdata.yaml \
  --cfg cfg/training/yolov7-tiny.yaml \
  --weights yolov7-tiny.pt \
  --device 0

# -------------------------------
# UPLOAD OUTPUTS TO S3
# -------------------------------
echo "📤 Uploading results to S3..."
aws s3 sync runs "$S3_OUTPUT"

echo "✅ Training complete"
