#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# Local Asterisk + coturn setup script
#
# Usage:
#   sudo ./setup-local-asterisk.sh                  (local test, no IP replacement)
#   sudo ./setup-local-asterisk.sh 203.0.113.50     (with public IP)
#   sudo ./setup-local-asterisk.sh 203.0.113.50 192.168.1.100  (public + private IP)
#
# What this script does:
#   1. Generates self-signed TLS cert (if not present)
#   2. Copies all Asterisk + coturn configs
#   3. Replaces ${PUBLIC_IP} / ${PRIVATE_IP} placeholders if IPs provided
#   4. Restarts Asterisk + coturn
#   5. Prints verification commands
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASTERISK_DIR="${SCRIPT_DIR}/../asterisk"
COTURN_DIR="${SCRIPT_DIR}/../coturn"
LIVE_DIR="/etc/asterisk"
TLS_DIR="/etc/asterisk/tls"

PUBLIC_IP="${1:-}"
PRIVATE_IP="${2:-}"
DEFAULT_PRIVATE_IP="192.168.1.72"

detect_private_ip() {
  local route_ip
  local host_ips
  local detected=""

  route_ip="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')"
  if [ -n "${route_ip}" ] && [[ "${route_ip}" =~ ^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.) ]]; then
    detected="${route_ip}"
  fi

  if [ -z "${detected}" ]; then
    host_ips="$(hostname -I 2>/dev/null || true)"
    detected="$(awk '{
      for (i=1; i<=NF; i++) {
        if ($i ~ /^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/) {
          print $i;
          exit;
        }
      }
    }' <<< "${host_ips}")"
  fi

  echo "${detected}"
}

if [ -z "${PRIVATE_IP}" ]; then
  PRIVATE_IP="$(detect_private_ip)"
fi

if [ -z "${PRIVATE_IP}" ]; then
  PRIVATE_IP="${DEFAULT_PRIVATE_IP}"
  echo "--- Private IP auto-detect failed; using fallback ${DEFAULT_PRIVATE_IP} ---"
fi

echo "=== Local Asterisk + coturn setup ==="
echo ""
echo "Public IP:  ${PUBLIC_IP:-<not set>}"
echo "Private IP: ${PRIVATE_IP:-<not detected>}"
echo ""

# --- Root check ---

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Run this script as root (sudo)."
  exit 1
fi

# --- Dependency check ---

if ! command -v asterisk &>/dev/null; then
  echo "ERROR: asterisk binary not found. Install Asterisk first."
  exit 1
fi

# --- Self-signed TLS certificate ---

if [ ! -f "${TLS_DIR}/asterisk.crt" ]; then
  echo "--- Generating self-signed TLS certificate ---"
  mkdir -p "${TLS_DIR}"

  CERT_CN="${PUBLIC_IP:-localhost}"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "${TLS_DIR}/asterisk.key" \
    -out "${TLS_DIR}/asterisk.crt" \
    -subj "/CN=${CERT_CN}" \
    2>/dev/null

  chown asterisk:asterisk "${TLS_DIR}/asterisk.key" "${TLS_DIR}/asterisk.crt"
  chmod 640 "${TLS_DIR}/asterisk.key"
  chmod 644 "${TLS_DIR}/asterisk.crt"
  echo "  Certificate created for CN=${CERT_CN}"
else
  echo "--- TLS certificate already exists at ${TLS_DIR}/asterisk.crt ---"
fi

echo ""

# --- Copy Asterisk config files ---

echo "--- Copying Asterisk configs to ${LIVE_DIR} ---"

ASTERISK_FILES="pjsip.conf extensions.conf http.conf rtp.conf modules.conf cdr.conf cel.conf"

for f in ${ASTERISK_FILES}; do
  if [ -f "${ASTERISK_DIR}/${f}" ]; then
    cp -v "${ASTERISK_DIR}/${f}" "${LIVE_DIR}/${f}"
  else
    echo "  SKIP: ${f} not found in ${ASTERISK_DIR}"
  fi
done

echo ""

# --- Copy coturn config ---

if [ -f "${COTURN_DIR}/turnserver.conf" ]; then
  echo "--- Copying coturn config to /etc/turnserver.conf ---"
  cp -v "${COTURN_DIR}/turnserver.conf" /etc/turnserver.conf
else
  echo "--- SKIP: turnserver.conf not found in ${COTURN_DIR} ---"
fi

echo ""

# --- Replace placeholders if IPs provided ---

if [ -n "${PUBLIC_IP}" ]; then
  echo "--- Replacing \${PUBLIC_IP} with ${PUBLIC_IP} ---"

  sed -i "s/\${PUBLIC_IP}/${PUBLIC_IP}/g" \
    "${LIVE_DIR}/pjsip.conf" \
    "${LIVE_DIR}/rtp.conf" \
    /etc/turnserver.conf 2>/dev/null || true

  echo "  Done."
fi

echo "--- Replacing \${PRIVATE_IP} with ${PRIVATE_IP} ---"

sed -i "s/\${PRIVATE_IP}/${PRIVATE_IP}/g" /etc/turnserver.conf 2>/dev/null || true
sed -i "s/^relay-ip=.*/relay-ip=${PRIVATE_IP}/" /etc/turnserver.conf 2>/dev/null || true

echo "  Done."

echo ""

# --- Create log directory for coturn ---

mkdir -p /var/log/turnserver

echo ""

# --- Restart services ---

echo "--- Restarting Asterisk ---"
systemctl restart asterisk 2>/dev/null || asterisk -rx "core restart now"
sleep 3

if command -v turnserver &>/dev/null; then
  echo "--- Restarting coturn ---"
  systemctl restart coturn 2>/dev/null || true
  sleep 1
else
  echo "--- coturn not installed, skipping ---"
fi

echo ""

# --- Verification ---

echo "=== Verification ==="

echo ""
echo "[1] chan_sip (should be empty / not loaded):"
asterisk -rx "module show like chan_sip" 2>/dev/null || true

echo ""
echo "[2] PJSIP transports (should show: transport-ws, transport-wss, transport-udp):"
asterisk -rx "pjsip show transports" 2>/dev/null || true

echo ""
echo "[3] PJSIP endpoints (should show: venus, kartik, 1001, iagu-trunk):"
asterisk -rx "pjsip show endpoints" 2>/dev/null || true

echo ""
echo "[4] HTTP server (should show TLS on port 8089):"
asterisk -rx "http show status" 2>/dev/null || true

echo ""
echo "[5] Dialplan contexts:"
asterisk -rx "dialplan show from-webrtc" 2>/dev/null | head -5 || true
asterisk -rx "dialplan show from-iagu" 2>/dev/null | head -5 || true

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Start backend:   cd call_be && npm run start:dev"
echo "  2. Start frontend:  cd call_fe && npm run dev"
echo ""
echo "Local testing (browser to browser):"
echo "  3. Open tab 1 -> register as 'kartik'"
echo "  4. Open tab 2 -> register as '1001'"
echo "  5. From tab 1, dial '1001'"
echo ""

if [ -n "${PUBLIC_IP}" ]; then
  echo "Production testing (browser to phone):"
  echo "  6. Accept self-signed cert: visit https://${PUBLIC_IP}:8089 in browser"
  echo "  7. Open app, register as 'venus'"
  echo "  8. Dial an Australian number"
  echo ""
  echo "Port forwarding required on your router:"
  echo "  5060/udp       -> this machine (SIP to/from Iagu)"
  echo "  8089/tcp       -> this machine (WSS for browser)"
  echo "  3478/udp+tcp   -> this machine (TURN)"
  echo "  10000-20000/udp -> this machine (RTP audio)"
  echo ""
  echo "IMPORTANT: Send your IP (${PUBLIC_IP}) to Andrew/Iagu for trunk allowlisting."
else
  echo "To enable real phone calls later, re-run with your public IP:"
  echo "  sudo $0 <PUBLIC_IP> [PRIVATE_IP]"
fi
echo ""
