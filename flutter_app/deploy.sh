#!/usr/bin/env bash
set -euo pipefail

# VuonRau Flutter deploy/run helper
#
# Usage:
#   sh deploy.sh
#
# Notes:
# - Default mode is "run debug on attached phone" (no -d needed).
# - Other modes are kept here but commented out; uncomment when needed.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Common settings ----
# Replace this token each time you run, if needed.
EZVIZ_ACCESS_TOKEN="at.c5iguif2c4916h9pbzipvo659joc9s2m-1hsteud180-1sippjd-smgs4fmqq"

# If you want to force a specific device, set DEVICE (otherwise Flutter will pick the attached device).
# DEVICE='iPhone của Kha'

die() {
  echo "Error: $*" >&2
  exit 1
}

command -v flutter >/dev/null 2>&1 || die "Missing command: flutter"

cd "$ROOT_DIR"

COMMON_ARGS=(
  "--dart-define=EZVIZ_ACCESS_TOKEN=${EZVIZ_ACCESS_TOKEN}"
)

# ---- MODE: run debug on attached phone (ENABLED) ----
# if [[ -n "${DEVICE:-}" ]]; then
#   flutter run -d "$DEVICE" "${COMMON_ARGS[@]}"
# else
#   flutter run "${COMMON_ARGS[@]}"
# fi

# ---- MODE: run profile ----
# flutter run --profile "${COMMON_ARGS[@]}"

# ---- MODE: run release (on device) ----
flutter run --release "${COMMON_ARGS[@]}"

# ---- MODE: build Android APK (release) ----
# flutter build apk --release "${COMMON_ARGS[@]}"

# ---- MODE: build Android App Bundle (release) ----
# flutter build appbundle --release "${COMMON_ARGS[@]}"

# ---- MODE: build iOS (release) ----
# flutter build ipa --release "${COMMON_ARGS[@]}"

echo "Done."
