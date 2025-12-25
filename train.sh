#!/bin/bash
set -e

echo "🚀 YOLOv7 Training Pipeline (RunPod)"

# -------------------------------
# BASIC PATHS
# -------------------------------
WORKDIR=/workspace
YOLO_DIR=$WORKDIR/yolov7-custom
DATA_DIR=$WORKDIR/data/input

# -------------------------------
# S3 PATHS
# -------------------------------
S3_INPUT="s3://my-training-data-algoanalytics/input"
S3_OUTPUT="s3://my-training-data-algoanalytics/output/runs"

# -------------------------------
# SAFETY CHECKS
# -------------------------------
if [ -z "$GITHUB_PAT" ]; then
  echo "❌ ERROR: GITHUB_PAT is not set"
  exit 1
fi

export GIT_TERMINAL_PROMPT=0

# -------------------------------
# CLEAN OLD CLONE
# -------------------------------
rm -rf "$YOLO_DIR"

# -------------------------------
# CLONE PRIVATE YOLOv7 REPO
# -------------------------------
echo "📦 Cloning YOLOv7 repo..."
git clone \
  https://x-access-token:${GITHUB_PAT}@github.com/skadam-wq/yolov7-custom.git \
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
echo "📥 Syncing dataset from S3..."
rm -rf "$DATA_DIR"
aws s3 sync "$S3_INPUT" "$DATA_DIR"

# -------------------------------
# AUTO-GENERATE DATA YAML
# -------------------------------
echo "🧠 Generating dataset config..."

CLASS_IDS=$(cat $DATA_DIR/**/labels/*.txt | awk '{print $1}' | sort -n | uniq)
NUM_CLASSES=$(echo "$CLASS_IDS" | wc -l)
CLASS_NAMES=$(echo "$CLASS_IDS" | awk '{print "\"class"$1"\""}' | paste -sd "," -)

cat > data/customdata.yaml <<EOF
train: $DATA_DIR/train/images
val: $DATA_DIR/val/images
test: $DATA_DIR/test/images
nc: $NUM_CLASSES
names: [$CLASS_NAMES]
EOF

echo "✅ Detected $NUM_CLASSES classes"

# -------------------------------
# TRAINING
# -------------------------------
echo "🏋️ Starting training..."

python train.py \
  --img 640 \
  --batch 16 \
  --epochs 50 \
  --data data/customdata.yaml \
  --cfg cfg/yolov7-tiny.yaml \
  --weights yolov7-tiny.pt \
  --device 0 \
  --name initial_run

# -------------------------------
# UPLOAD OUTPUTS TO S3
# -------------------------------
echo "📤 Uploading outputs to S3..."
aws s3 sync runs "$S3_OUTPUT"

echo "✅ Training complete"
