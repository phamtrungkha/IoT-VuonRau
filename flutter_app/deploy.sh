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
# EZVIZ access token: nhập trong app (Cài đặt), không cần dart-define.
# Tuỳ chọn khi dev: export EZVIZ_ACCESS_TOKEN='...' trước khi chạy script này.

# If you want to force a specific device, set DEVICE (otherwise Flutter will pick the attached device).
# DEVICE='iPhone của Kha'

die() {
  echo "Error: $*" >&2
  exit 1
}

command -v flutter >/dev/null 2>&1 || die "Missing command: flutter"

cd "$ROOT_DIR"

COMMON_ARGS=()
if [[ -n "${EZVIZ_ACCESS_TOKEN:-}" ]]; then
  COMMON_ARGS+=( "--dart-define=EZVIZ_ACCESS_TOKEN=${EZVIZ_ACCESS_TOKEN}" )
fi
# Khi uncomment các lệnh `flutter ...` phía dưới: nếu không có EZVIZ_ACCESS_TOKEN (mảng rỗng),
# không được dùng `"${COMMON_ARGS[@]}"` trực tiếp — dùng nhánh if/else như phần "run release".

# ---- MODE: run debug on attached phone (ENABLED) ----
# if [[ -n "${DEVICE:-}" ]]; then
#   flutter run -d "$DEVICE" "${COMMON_ARGS[@]}"
# else
#   flutter run "${COMMON_ARGS[@]}"
# fi

# ---- MODE: run profile ----
# flutter run --profile "${COMMON_ARGS[@]}"

# ---- MODE: run release (on device) ----
# Avoid `${COMMON_ARGS[@]}` when the array is empty: with `set -u` Bash can fail with "unbound variable".
if ((${#COMMON_ARGS[@]} > 0)); then
  flutter run --release "${COMMON_ARGS[@]}"
else
  flutter run --release
fi

# ---- MODE: build Android APK (release) ----
# flutter build apk --release "${COMMON_ARGS[@]}"

# ---- MODE: build Android App Bundle (release) ----
# flutter build appbundle --release "${COMMON_ARGS[@]}"

# ---- MODE: build iOS (release) ----
# flutter build ipa --release "${COMMON_ARGS[@]}"

echo "Done."
