#!/bin/bash
set -e

echo "🚀 YOLOv7 Training Pipeline (RunPod)"

WORKDIR=/workspace
REPO_DIR=$WORKDIR/yolov7-custom
DATA_DIR=$WORKDIR/data

S3_DATA_BUCKET="s3://my-training-data-algoanalytics"
S3_OUTPUT_BUCKET="s3://my-training-data-algoanalytics/output"

# -------------------------------
# Clone YOLOv7 repo
# -------------------------------
if [ ! -d "$REPO_DIR" ]; then
  git clone https://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@github.com/risaraf-jpg/yolov7-custom.git
else
  cd $REPO_DIR && git pull
fi

cd $REPO_DIR

# -------------------------------
# Install dependencies
# -------------------------------
pip install -r requirements.txt

# -------------------------------
# Download dataset from S3
# -------------------------------
echo "📥 Downloading dataset from S3..."
aws s3 sync $S3_DATA_BUCKET $DATA_DIR

# -------------------------------
# Auto-generate data YAML
# -------------------------------
NUM_CLASSES=$(ls $DATA_DIR/train/labels/*.txt | xargs awk '{print $1}' | sort -n | uniq | wc -l)

cat > data/customdata.yaml <<EOF
train: $DATA_DIR/train/images
val: $DATA_DIR/val/images
test: $DATA_DIR/test/images
nc: $NUM_CLASSES
names: [class0]
EOF

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
echo "📤 Uploading results to S3..."
aws s3 sync runs $S3_OUTPUT_BUCKET

echo "✅ Training complete"
