#!/usr/bin/env bash
set -e

FLUTTER_VERSION="3.32.2"
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "==> Downloading Flutter $FLUTTER_VERSION..."
  wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -O /tmp/flutter.tar.xz
  tar xf /tmp/flutter.tar.xz -C "$HOME"
  rm /tmp/flutter.tar.xz
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "==> Flutter version:"
flutter --version

flutter config --no-analytics
flutter pub get
flutter build web --release --pwa-strategy=none

echo "==> Build complete. Output in build/web/"
