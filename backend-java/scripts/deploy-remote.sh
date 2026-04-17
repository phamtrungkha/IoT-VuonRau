#!/usr/bin/env bash
# Run on Mac (or any machine with Maven + ssh/scp). Builds JAR, uploads, restarts systemd on Linux.
#
# Requires SSH key (or interactive password) for DEPLOY_USER@DEPLOY_HOST.
# Remote user needs passwordless sudo for systemctl (see linux-first-time-setup.sh header).
#
# Sudoers one-liner (verify systemctl path on server: ssh user@host 'command -v systemctl'):
#   khapt ALL=(root) NOPASSWD: /usr/bin/systemctl daemon-reload, /usr/bin/systemctl restart vuonrau-backend, /usr/bin/systemctl start vuonrau-backend, /usr/bin/systemctl stop vuonrau-backend, /usr/bin/systemctl is-active vuonrau-backend, /usr/bin/systemctl status vuonrau-backend
#
# Environment overrides:
#   DEPLOY_HOST   default 192.168.1.92
#   DEPLOY_USER   default khapt
#   REMOTE_JAR    default /opt/vuonrau/lib/vuonrau-backend.jar
#   SYSTEMD_UNIT  default vuonrau-backend

set -euo pipefail

DEPLOY_HOST="${DEPLOY_HOST:-192.168.1.92}"
DEPLOY_USER="${DEPLOY_USER:-khapt}"
REMOTE_JAR="${REMOTE_JAR:-/opt/vuonrau/lib/vuonrau-backend.jar}"
SYSTEMD_UNIT="${SYSTEMD_UNIT:-vuonrau-backend}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

if ! command -v mvn &>/dev/null; then
  echo "mvn not found. Install Maven and JDK 17." >&2
  exit 1
fi

mvn -B clean package -DskipTests

LOCAL_JAR="$(find target -maxdepth 1 -name 'vuonrau-backend-*.jar' ! -name '*-sources.jar' ! -name '*-javadoc.jar' | sort | tail -n 1)"
if [[ -z "${LOCAL_JAR}" || ! -f "${LOCAL_JAR}" ]]; then
  echo "No vuonrau-backend-*.jar in target/. Build failed?" >&2
  exit 1
fi

REMOTE="${DEPLOY_USER}@${DEPLOY_HOST}"
echo "Uploading ${LOCAL_JAR} -> ${REMOTE}:${REMOTE_JAR}"
scp "${LOCAL_JAR}" "${REMOTE}:${REMOTE_JAR}"

echo "Restarting ${SYSTEMD_UNIT} on ${REMOTE}"
ssh "${REMOTE}" "sudo -n systemctl daemon-reload && sudo -n systemctl restart ${SYSTEMD_UNIT} && sudo -n systemctl is-active ${SYSTEMD_UNIT}"

echo "Deploy OK: ${SYSTEMD_UNIT} is active on ${DEPLOY_HOST}"
