# Production Runbook

## Service restart order

1. `coturn`
2. `asterisk`
3. backend API (`call_be`)
4. frontend (`call_fe`)

## Health checks

- Backend: `GET /` returns `{ status: "ok" }`.
- Asterisk:
  - `sudo asterisk -rx "pjsip show transports"`
  - `sudo asterisk -rx "pjsip show endpoints"`
  - `sudo asterisk -rx "http show status"`
- coturn:
  - `sudo systemctl status coturn --no-pager`
  - `sudo journalctl -u coturn -n 100 --no-pager`

## Common incidents

### No ring in browser

- Verify consultant registration:
  - `sudo asterisk -rx "pjsip show contacts"`
- Verify inbound DID route:
  - `sudo asterisk -rx "dialplan show from-iagu"`
- Verify DND state:
  - `sudo asterisk -rx "database show DND"`

### One-way/no audio

- Verify TURN service and relay ports.
- Confirm frontend TURN credentials and URL.
- Confirm `external_media_address` in `pjsip.conf`.

### Trunk call failures

- Verify Iagu credentials and reachability.
- Check Asterisk logs:
  - `sudo journalctl -u asterisk -n 200 --no-pager`
  - `sudo asterisk -rvvv`
