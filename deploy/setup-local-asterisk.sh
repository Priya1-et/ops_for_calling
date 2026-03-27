#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASTERISK_DIR="${SCRIPT_DIR}/../asterisk"
LIVE_DIR="/etc/asterisk"

echo "=== Local Asterisk setup for PJSIP WebRTC ==="

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Run this script as root (sudo)."
  exit 1
fi

if ! command -v asterisk &>/dev/null; then
  echo "ERROR: asterisk binary not found. Install Asterisk first."
  exit 1
fi

echo ""
echo "--- Copying config files to ${LIVE_DIR} ---"
for f in pjsip.conf extensions.conf http.conf rtp.conf modules.conf; do
  if [ -f "${ASTERISK_DIR}/${f}" ]; then
    cp -v "${ASTERISK_DIR}/${f}" "${LIVE_DIR}/${f}"
  else
    echo "SKIP: ${f} not found in ${ASTERISK_DIR}"
  fi
done

echo ""
echo "--- Restarting Asterisk ---"
systemctl restart asterisk 2>/dev/null || asterisk -rx "core restart now"
sleep 3

echo ""
echo "--- Verifying setup ---"

echo ""
echo "[1] chan_sip status (should be empty / not loaded):"
asterisk -rx "module show like chan_sip" 2>/dev/null || true

echo ""
echo "[2] PJSIP modules (should show multiple res_pjsip modules):"
asterisk -rx "module show like pjsip" 2>/dev/null || true

echo ""
echo "[3] HTTP server status:"
asterisk -rx "http show status" 2>/dev/null || true

echo ""
echo "[4] PJSIP transports (should show transport-ws):"
asterisk -rx "pjsip show transports" 2>/dev/null || true

echo ""
echo "[5] PJSIP endpoints (should show kartik and 1001):"
asterisk -rx "pjsip show endpoints" 2>/dev/null || true

echo ""
echo "=== Done ==="
echo ""
echo "Next steps:"
echo "  1. Start backend:   cd call_be && npm run start:dev"
echo "  2. Start frontend:  cd call_fe && npm run dev"
echo "  3. Open browser tab 1 -> register as 'kartik'"
echo "  4. Open browser tab 2 -> register as '1001'"
echo "  5. From tab 1, dial '1001'"
echo ""
echo "If chan_sip is still loaded, check /etc/asterisk/modules.conf has: noload => chan_sip.so"
echo "If no PJSIP transports show, check /etc/asterisk/pjsip.conf and http.conf"
