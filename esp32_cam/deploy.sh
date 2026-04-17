#!/usr/bin/env bash
set -euo pipefail

# Deploy ESP32-CAM (PlatformIO)
#
# Usage:
#   sh deploy.sh
#
# Requirements:
# - PlatformIO installed (pio in PATH)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -------- modes (only ONE should be enabled) --------
ENV_NAME="normal_ota"   # ENABLED (OTA)
# ENV_NAME="normal"     # (USB/Serial upload via esptool) - uncomment when needed

die() {
  echo "Error: $*" >&2
  exit 1
}

command -v pio >/dev/null 2>&1 || die "Missing command: pio"

echo "==> esp32_cam: env=${ENV_NAME}"
( cd "$ROOT_DIR" && pio run -e "$ENV_NAME" -t upload )

echo "Done."
