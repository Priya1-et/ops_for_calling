# Web Calling Ops Guide

## 1) Fill placeholders

All files in `ops/asterisk/` and `ops/coturn/` contain placeholder values like `${PUBLIC_FQDN}`.
Replace these values before deploying.

## 2) Obtain TLS certificate

```bash
./ops/deploy/generate-cert.sh pbx.example.com ops@example.com
```

## 3) Apply system configs (root)

```bash
./ops/deploy/apply-system-configs.sh
```

## 4) Firewall ports

Open:

- `443/tcp`
- `8089/tcp`
- `3478/tcp`
- `3478/udp`
- `5349/tcp`
- `49152-65535/udp`
- `5060/udp` (or trunk transport port from Iagu)

## 5) Quick validation

```bash
sudo asterisk -rx "pjsip show endpoints"
sudo asterisk -rx "pjsip show contacts"
sudo asterisk -rx "pjsip show registrations"
sudo asterisk -rx "dialplan show route-consultant"
sudo systemctl status coturn --no-pager
```
