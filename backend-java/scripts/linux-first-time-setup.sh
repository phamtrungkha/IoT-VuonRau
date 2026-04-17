#!/usr/bin/env bash
# Run this script ON the Linux server (not from Mac). Requires sudo.
#
# Creates /opt/vuonrau layout, installs vuonrau-backend.service from this directory.
# Install unit manually if you prefer: sudo cp scripts/vuonrau-backend.service /etc/systemd/system/
#
# --- Sudoers for passwordless deploy from Mac (verify systemctl path: command -v systemctl) ---
#   sudo visudo -f /etc/sudoers.d/vuonrau-backend-deploy
# One line (adjust user and paths if /bin/systemctl vs /usr/bin/systemctl):
#
#   khapt ALL=(root) NOPASSWD: /usr/bin/systemctl daemon-reload, /usr/bin/systemctl restart vuonrau-backend, /usr/bin/systemctl start vuonrau-backend, /usr/bin/systemctl stop vuonrau-backend, /usr/bin/systemctl is-active vuonrau-backend, /usr/bin/systemctl status vuonrau-backend

set -euo pipefail

SERVICE_USER="${SERVICE_USER:-khapt}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT_SRC="${SCRIPT_DIR}/vuonrau-backend.service"
UNIT_DST="/etc/systemd/system/vuonrau-backend.service"

if [[ ! -f "${UNIT_SRC}" ]]; then
  echo "Missing ${UNIT_SRC}" >&2
  exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Re-run with sudo: sudo SERVICE_USER=${SERVICE_USER} $0" >&2
  exit 1
fi

install -d -m 0755 /opt/vuonrau/lib /opt/vuonrau/config
chown -R "${SERVICE_USER}:${SERVICE_USER}" /opt/vuonrau

if ! id -u "${SERVICE_USER}" &>/dev/null; then
  echo "User ${SERVICE_USER} does not exist. Create the user or set SERVICE_USER." >&2
  exit 1
fi

install -m 0644 "${UNIT_SRC}" "${UNIT_DST}"
systemctl daemon-reload
systemctl enable vuonrau-backend

echo "Installed ${UNIT_DST} and enabled vuonrau-backend."
echo "1) Create /opt/vuonrau/config/application.yml (JDBC, MQTT, allowed-ids)."
echo "2) Place JAR at /opt/vuonrau/lib/vuonrau-backend.jar (e.g. deploy-remote.sh from Mac)."
echo "3) Add sudoers snippet from the header comment in this script, then: sudo systemctl start vuonrau-backend"
echo "4) Check: sudo systemctl status vuonrau-backend"
