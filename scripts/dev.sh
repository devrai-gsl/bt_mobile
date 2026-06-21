#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

DEVICE="${FLUTTER_DEVICE:-emulator-5554}"

exec flutter run \
  -d "$DEVICE" \
  --dart-define=BT_DEV_SANDBOX=true \
  "$@"
