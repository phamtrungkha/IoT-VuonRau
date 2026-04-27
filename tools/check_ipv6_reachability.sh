#!/usr/bin/env bash
# Read-only checks: IPv6 global address, listeners, firewall, local HTTP to :8000.
# Run on the Linux host (after: ssh user@host). Does not prove WAN reachability alone.

set -euo pipefail

echo "=== 1) Host / time ==="
hostname
date -u +"%Y-%m-%dT%H:%M:%SZ"

echo
echo "=== 2) Global IPv6 (scope global) ==="
ip -6 addr show scope global 2>/dev/null || true
GLOBAL=$(ip -6 -o addr show scope global 2>/dev/null | awk '{print $4}' | head -1 | cut -d/ -f1)
if [[ -z "${GLOBAL:-}" ]]; then
  echo "WARN: no global IPv6 on this box."
else
  echo "Primary global (first): $GLOBAL"
fi

echo
echo "=== 3) LISTEN tcp :8000 and :22 (ss) ==="
if command -v ss >/dev/null 2>&1; then
  ss -tlnp 2>/dev/null | grep -E ':8000|:22' || echo "(no match)"
else
  echo "ss not found"
fi

echo
echo "=== 4) UFW ==="
if command -v ufw >/dev/null 2>&1; then
  if sudo -n ufw status verbose 2>/dev/null; then
    :
  else
    echo "(run with sudo to see ufw, or: ufw may be inactive)"
    ufw status 2>/dev/null || true
  fi
else
  echo "ufw not installed"
fi

echo
echo "=== 5) ip6tables INPUT (first rules) ==="
if command -v ip6tables >/dev/null 2>&1; then
  ip6tables -L INPUT -n -v 2>/dev/null | head -20 || sudo -n ip6tables -L INPUT -n -v 2>/dev/null | head -20 || true
else
  echo "ip6tables not found"
fi

echo
echo "=== 6) nft (inet/inet6 filter) snippet ==="
if command -v nft >/dev/null 2>&1; then
  nft list ruleset 2>/dev/null | head -60 || true
else
  echo "nft not found"
fi

echo
echo "=== 7) Local HTTP over IPv6 to :8000 (if curl + address exist) ==="
if [[ -n "${GLOBAL:-}" ]] && command -v curl >/dev/null 2>&1; then
  code=$(curl -g -6 -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://[${GLOBAL}]:8000/" 2>/dev/null || echo "ERR")
  echo "curl -6 http://[${GLOBAL}]:8000/ -> HTTP $code (404/200/etc. means TCP+HTTP responded)"
else
  echo "skip (no curl or no global IPv6)"
fi

echo
echo "=== 8) From OUTSIDE this host ==="
echo "This script cannot test the internet path. From a phone on 5G (IPv6), open:"
if [[ -n "${GLOBAL:-}" ]]; then
  echo "  http://[${GLOBAL}]:8000/<your-path>"
fi
echo "Or from another IPv6 host: curl -g -6 -I --connect-timeout 5 \"http://[${GLOBAL}]:8000/\""
echo "If tcpdump on this NIC shows SYN from phone but no SYN-ACK, check router IPv6 firewall."
