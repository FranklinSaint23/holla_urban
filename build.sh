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

# Patch flutter_bootstrap.js to use self-hosted CanvasKit (avoids gstatic.com CDN download)
# Without this, Flutter tries to fetch ~7MB WASM from CDN at startup, causing infinite spinner
echo "==> Patching flutter_bootstrap.js to use local CanvasKit..."
sed -i 's/"engineRevision":/"useLocalCanvasKit":true,"engineRevision":/' build/web/flutter_bootstrap.js

echo "==> Build complete. Output in build/web/"
