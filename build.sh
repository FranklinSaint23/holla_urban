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

# Patch 1: use self-hosted CanvasKit instead of gstatic.com CDN (~7MB WASM download at startup)
echo "==> Patching flutter_bootstrap.js to use local CanvasKit..."
sed -i 's/"engineRevision":/"useLocalCanvasKit":true,"engineRevision":/' build/web/flutter_bootstrap.js

# Patch 2: replace the empty service worker with a self-destructing one
# Old builds registered a service worker; this new SW clears all caches and unregisters itself
echo "==> Writing self-destructing service worker..."
cat > build/web/flutter_service_worker.js << 'SWEOF'
// Self-destructing service worker: clears old caches from previous builds
self.addEventListener('install', function(e) { self.skipWaiting(); });
self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(names) {
      return Promise.all(names.map(function(n) { return caches.delete(n); }));
    }).then(function() { return self.registration.unregister(); })
      .then(function() { return self.clients.matchAll(); })
      .then(function(clients) { clients.forEach(function(c) { c.navigate(c.url); }); })
  );
});
SWEOF

echo "==> Build complete. Output in build/web/"
