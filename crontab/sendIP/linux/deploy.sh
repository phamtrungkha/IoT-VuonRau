#!/usr/bin/env bash
set -euo pipefail

# deploy.sh
# - Copy send_ip_to_gas.sh lên Linux server và cài crontab chỉ bằng 1 lệnh.
#
# Lưu ý bảo mật:
# - KHÔNG hardcode mật khẩu trong repo.
# - Khuyến nghị dùng SSH key. Nếu buộc dùng password, có thể dùng sshpass qua biến môi trường.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SENDER="${SCRIPT_DIR}/send_ip_to_gas.sh"

# Tương tự backend-java/scripts/deploy-remote.sh: dùng scp + ssh trực tiếp.
DEPLOY_HOST="${DEPLOY_HOST:-192.168.1.92}"
DEPLOY_USER="${DEPLOY_USER:-khapt}"
DEPLOY_PORT="${DEPLOY_PORT:-22}"

# Mặc định deploy vào HOME để không cần sudo.
# Nếu bạn muốn /opt/vuonrau/... thì set REMOTE_DIR và đảm bảo user có quyền ghi (hoặc bật USE_SUDO=1).
: "${REMOTE_DIR:=~/vuonrau/sendip}"
: "${REMOTE_SCRIPT:=${REMOTE_DIR}/send_ip_to_gas.sh}"
#
# USE_SUDO=1: dùng sudo để tạo/chmod thư mục và script.
: "${USE_SUDO:=0}"

: "${GAS_URL:=https://script.google.com/macros/s/AKfycbyCWLppAfCVZ3Uk65mXO2yaJWU69N39f8v__pVvpvchvaA-Eadd8SyIhe601NB4CtrDIw/exec}"
: "${GAS_KEY:=vuonrauiotip}"
: "${CRON_EVERY:=*/30 * * * *}"
: "${CRON_LOG:=/var/log/send_ip_to_gas.log}"

die() {
  echo "ERROR: $*" >&2
  exit 2
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "Missing '$1' in PATH"
}

main() {
  need ssh
  need scp

  [[ -n "${DEPLOY_USER}" ]] || die "DEPLOY_USER is required (ví dụ: DEPLOY_USER=khapt)"
  [[ -f "${LOCAL_SENDER}" ]] || die "Cannot find ${LOCAL_SENDER}"

  REMOTE="${DEPLOY_USER}@${DEPLOY_HOST}"

  # Expand home directory trên remote để tránh vấn đề "~" không được expand
  # khi nằm trong biến hoặc nằm trong chuỗi bị quote.
  REMOTE_HOME="$(
    ssh -p "${DEPLOY_PORT}" -o StrictHostKeyChecking=accept-new "${REMOTE}" 'printf "%s" "$HOME"'
  )"
  if [[ -z "${REMOTE_HOME}" ]]; then
    die "Cannot determine remote HOME"
  fi

  EFFECTIVE_REMOTE_DIR="${REMOTE_DIR}"
  if [[ "${EFFECTIVE_REMOTE_DIR}" == "~"* ]]; then
    EFFECTIVE_REMOTE_DIR="${REMOTE_HOME}${EFFECTIVE_REMOTE_DIR:1}"
  fi
  EFFECTIVE_REMOTE_SCRIPT="${EFFECTIVE_REMOTE_DIR}/send_ip_to_gas.sh"

  echo "==> Preparing remote dir: ${REMOTE}:${REMOTE_DIR}"
  if [[ "${USE_SUDO}" == "1" ]]; then
    ssh -p "${DEPLOY_PORT}" -o StrictHostKeyChecking=accept-new "${REMOTE}" \
      "sudo -n mkdir -p \"${EFFECTIVE_REMOTE_DIR}\""
  else
    ssh -p "${DEPLOY_PORT}" -o StrictHostKeyChecking=accept-new "${REMOTE}" \
      "mkdir -p \"${EFFECTIVE_REMOTE_DIR}\""
  fi

  echo "==> Uploading sender script"
  scp -P "${DEPLOY_PORT}" -o StrictHostKeyChecking=accept-new "${LOCAL_SENDER}" "${REMOTE}:${EFFECTIVE_REMOTE_SCRIPT}"
  if [[ "${USE_SUDO}" == "1" ]]; then
    ssh -p "${DEPLOY_PORT}" -o StrictHostKeyChecking=accept-new "${REMOTE}" "sudo -n chmod +x \"${EFFECTIVE_REMOTE_SCRIPT}\""
  else
    ssh -p "${DEPLOY_PORT}" -o StrictHostKeyChecking=accept-new "${REMOTE}" "chmod +x \"${EFFECTIVE_REMOTE_SCRIPT}\""
  fi

  echo "==> Installing/Updating crontab entry"
  # Marker để update idempotent
  local marker="# vuonrau-sendip"
  local cron_line="${CRON_EVERY} GAS_URL='${GAS_URL}' GAS_KEY='${GAS_KEY}' /bin/bash '${EFFECTIVE_REMOTE_SCRIPT}' >> '${CRON_LOG}' 2>&1 ${marker}"

  ssh -p "${DEPLOY_PORT}" -o StrictHostKeyChecking=accept-new "${REMOTE}" "bash -lc '
set -euo pipefail
tmp=\$(mktemp)
crontab -l 2>/dev/null | grep -v \"${marker}\" > \"\$tmp\" || true
echo \"${cron_line}\" >> \"\$tmp\"
crontab \"\$tmp\"
rm -f \"\$tmp\"
crontab -l | tail -n 5
'"

  echo "==> Done."
  echo "Tip: Nếu bạn muốn dùng password (ví dụ 9999), bạn có thể cài sshpass và tự wrap lệnh ssh/scp."
}

main "$@"

