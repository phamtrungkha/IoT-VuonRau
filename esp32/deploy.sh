#!/usr/bin/env bash
set -euo pipefail

# Deploy ESP32 (PlatformIO)
#
# Usage:
#   sh deploy.sh
#
# Requirements:
# - PlatformIO installed (pio in PATH)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -------- modes (pick ONE; keep others commented) --------
ENV_NAME="normal_ota"        # ENABLED (normal OTA)
# ENV_NAME="normal"          # (USB/Serial upload via esptool)
# ENV_NAME="test_sensor_ota" # (OTA test sensor mode)
# ENV_NAME="esp32dev"        # (USB/Serial upload for generic esp32dev board)

die() {
  echo "Error: $*" >&2
  exit 1
}

command -v pio >/dev/null 2>&1 || die "Missing command: pio"

echo "==> esp32: env=${ENV_NAME}"
( cd "$ROOT_DIR" && pio run -e "$ENV_NAME" -t upload )

echo "Done."
