#!/usr/bin/env bash
set -euo pipefail

# Simple helper to download example model assets into the app's Models/ folder.
# Usage:
#   ./Scripts/download_models.sh
# Or pass URLs:
#   ./Scripts/download_models.sh https://huggingface.co/..../model-file.onnx
# The script will place files under VideoGenerator/Models/

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODELS_DIR="$APP_ROOT/VideoGenerator/Models"
mkdir -p "$MODELS_DIR"

if [ "$#" -eq 0 ]; then
  echo "No URLs provided; fetching sample tiny models for demo."
  # Try a couple of small, public models
  URLS=(
    "https://github.com/onnx/models/raw/main/vision/classification/mnist/model/mnist-8.onnx"
    "https://github.com/onnx/models/raw/main/vision/classification/squeezenet/model/squeezenet1.0-12.onnx"
  )
else
  URLS=("$@")
fi

for u in "${URLS[@]}"; do
  echo "Downloading $u ..."
  fname="$(basename "$u")"
  if curl -L --fail "$u" -o "$MODELS_DIR/$fname"; then
    echo "Saved to $MODELS_DIR/$fname"
    if [[ "$fname" == *.mlmodel ]]; then
      echo "Note: Add this .mlmodel to Xcode build if you want a compiled .mlmodelc; currently it's just bundled raw."
    fi
  else
    echo "Warning: Failed to download $u"
  fi
done

echo "Done. Preloaded models now in $MODELS_DIR. Rebuild the app to include them."
