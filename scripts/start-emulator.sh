#!/usr/bin/env bash
set -euo pipefail

export ANDROID_HOME="/home/devrai/Android/Sdk"
export ANDROID_SDK_ROOT="/home/devrai/Android/Sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

if ! adb devices | grep -q "emulator-5554[[:space:]]*device"; then
  echo "Starting Android emulator Flutter_Lite..."
  flutter emulators --launch Flutter_Lite
  adb wait-for-device
  echo "Emulator is ready."
else
  echo "Emulator already running."
fi
