#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Applying Asterisk configuration templates..."
sudo install -m 0644 "$ROOT_DIR/asterisk/pjsip.conf" /etc/asterisk/pjsip.conf
sudo install -m 0644 "$ROOT_DIR/asterisk/http.conf" /etc/asterisk/http.conf
sudo install -m 0644 "$ROOT_DIR/asterisk/rtp.conf" /etc/asterisk/rtp.conf
sudo install -m 0644 "$ROOT_DIR/asterisk/extensions.conf" /etc/asterisk/extensions.conf
sudo install -m 0644 "$ROOT_DIR/asterisk/cdr.conf" /etc/asterisk/cdr.conf
sudo install -m 0644 "$ROOT_DIR/asterisk/cel.conf" /etc/asterisk/cel.conf

echo "Applying coturn configuration template..."
sudo install -m 0644 "$ROOT_DIR/coturn/turnserver.conf" /etc/turnserver.conf

echo "Enabling and restarting services..."
sudo systemctl daemon-reload
sudo systemctl enable asterisk coturn
sudo systemctl restart asterisk coturn

echo "Done. Verify status with:"
echo "  sudo systemctl status asterisk coturn"
echo "  sudo asterisk -rx 'pjsip show transports'"
