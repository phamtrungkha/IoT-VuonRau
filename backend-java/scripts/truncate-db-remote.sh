#!/usr/bin/env bash
# Run on Mac (or any machine with ssh). Truncates ALL tables in a MySQL database on Linux server.
#
# Requires:
#   - SSH access to DEPLOY_USER@DEPLOY_HOST
#   - mysql client installed on the remote server (so we can run mysql locally there)
#
# Environment overrides:
#   DEPLOY_HOST   default 192.168.1.92
#   DEPLOY_USER   default khapt
#
#   DB_HOST       default 127.0.0.1   (MySQL host as seen from the REMOTE server)
#   DB_PORT       default 3306
#   DB_NAME       default vuonrau
#   DB_USER       default vuonrau
#   DB_PASSWORD   default vuonrau
#
# Example:
#   DEPLOY_HOST=192.168.1.92 DEPLOY_USER=khapt DB_PASSWORD='***' ./truncate-db-remote.sh
#
# Safety:
#   - This script will IRREVERSIBLY delete data from all base tables in DB_NAME.
#   - It will NOT drop tables.

set -euo pipefail

DEPLOY_HOST="${DEPLOY_HOST:-192.168.1.92}"
DEPLOY_USER="${DEPLOY_USER:-khapt}"

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-vuonrau}"
DB_USER="${DB_USER:-vuonrau}"
DB_PASSWORD="${DB_PASSWORD:-vuonrau}"

REMOTE="${DEPLOY_USER}@${DEPLOY_HOST}"

read -r -p "DANGER: truncate ALL tables in MySQL '${DB_NAME}' on ${REMOTE}. Type TRUNCATE to continue: " CONFIRM
if [[ "${CONFIRM}" != "TRUNCATE" ]]; then
  echo "Abort."
  exit 1
fi

echo "Truncating all tables in '${DB_NAME}' on ${REMOTE} (mysql ${DB_HOST}:${DB_PORT} as ${DB_USER})"

REMOTE_SCRIPT="$(cat <<'EOS'
set -euo pipefail

if ! command -v mysql >/dev/null 2>&1; then
  echo "mysql client not found on remote. Install it first (e.g. sudo apt install -y mysql-client)." >&2
  exit 2
fi

mysql \
  -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" \
  --password="${DB_PASSWORD}" \
  --database "${DB_NAME}" \
  --batch --raw --silent <<SQL
SET FOREIGN_KEY_CHECKS = 0;

SET @db = DATABASE();
SET @sql = (
  SELECT GROUP_CONCAT(CONCAT('TRUNCATE TABLE \`', table_name, '\`') SEPARATOR '; ')
  FROM information_schema.tables
  WHERE table_schema = @db AND table_type = 'BASE TABLE'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;
SQL
EOS
)"

# Pass DB_* safely to the remote shell (handles special chars).
ssh "${REMOTE}" \
  "DB_HOST=$(printf '%q' "${DB_HOST}") \
DB_PORT=$(printf '%q' "${DB_PORT}") \
DB_NAME=$(printf '%q' "${DB_NAME}") \
DB_USER=$(printf '%q' "${DB_USER}") \
DB_PASSWORD=$(printf '%q' "${DB_PASSWORD}") \
bash -lc $(printf '%q' "${REMOTE_SCRIPT}")"

echo "Done. All tables truncated in '${DB_NAME}' on ${DEPLOY_HOST}."
