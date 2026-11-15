
#!/usr/bin/env bash
set -e

# Install Flutter SDK
git clone https://github.com/flutter/flutter.git \
  --depth 1 \
  --branch stable \
  /tmp/flutter

# Add Flutter to PATH
export PATH="/tmp/flutter/bin:$PATH"

# Download dependencies
flutter pub get

# Build Flutter web app
flutter build web --release
