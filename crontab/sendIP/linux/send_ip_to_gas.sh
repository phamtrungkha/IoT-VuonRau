#!/usr/bin/env bash
set -euo pipefail

# Config (có thể override bằng biến môi trường)
: "${GAS_URL:=https://script.google.com/macros/s/AKfycbyCWLppAfCVZ3Uk65mXO2yaJWU69N39f8v__pVvpvchvaA-Eadd8SyIhe601NB4CtrDIw/exec}"
: "${GAS_KEY:=vuonrauiotip}"
: "${IP_PROVIDER_URL:=https://api64.ipify.org}"
: "${CURL_TIMEOUT_S:=10}"
: "${CACHE_FILE:=/tmp/send_ip_to_gas.last_ip}"

log() {
  printf '%s %s\n' "$(date -Is)" "$*"
}

get_public_ip() {
  # Trả về IPv6 public (ví dụ: 2401:db00:...).
  # Ưu tiên api64.ipify; fallback sang ifconfig.co nếu cần.
  local ip
  if ip="$(curl -fsS --max-time "${CURL_TIMEOUT_S}" "${IP_PROVIDER_URL}")"; then
    :
  else
    ip="$(curl -fsS --max-time "${CURL_TIMEOUT_S}" "https://ifconfig.co/ip")"
  fi

  ip="$(echo "$ip" | tr -d ' \r\n\t')"
  # Validate "good enough" IPv6 (chấp nhận cả dạng rút gọn ::)
  if [[ ! "$ip" =~ ^[0-9A-Fa-f:]+$ ]] || [[ "$ip" != *:* ]]; then
    log "ERROR: invalid public IP: '$ip'"
    return 2
  fi
  echo "$ip"
}

post_ip() {
  local ip="$1"
  local url="${GAS_URL}?key=${GAS_KEY}"
  local host
  host="$(hostname -f 2>/dev/null || hostname)"

  curl -fsS --max-time "${CURL_TIMEOUT_S}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"ip\":\"${ip}\",\"source\":\"linux\",\"host\":\"${host}\",\"sentAt\":\"$(date -Is)\"}" \
    "${url}" >/dev/null
}

main() {
  local ip
  ip="$(get_public_ip)"

  if [[ -f "${CACHE_FILE}" ]]; then
    local prev
    prev="$(cat "${CACHE_FILE}" 2>/dev/null || true)"
    prev="$(echo "$prev" | tr -d ' \r\n\t')"
    if [[ "$prev" == "$ip" ]]; then
      log "SKIP: public IP unchanged (${ip})"
      exit 0
    fi
  fi

  post_ip "$ip"
  echo "$ip" > "${CACHE_FILE}"
  log "OK: posted public IP ${ip}"
}

main "$@"
