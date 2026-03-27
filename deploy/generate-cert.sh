#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <fqdn> <email>"
  exit 1
fi

FQDN="$1"
EMAIL="$2"

sudo certbot certonly --standalone --non-interactive --agree-tos \
  -m "$EMAIL" -d "$FQDN"

echo "Certificate created under /etc/letsencrypt/live/$FQDN/"
