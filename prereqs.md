# Deployment Prerequisites

This file tracks what is already available and what is still needed for go-live.

## Detected on host

- Hostname: `webexpert`
- Private IPv4: `192.168.110.252`
- Asterisk: `20.6.0`
- coturn: `4.6.1`
- certbot: `2.9.0`

## Required before production routing

- Public FQDN for PBX (example: `pbx.example.com`)
- Public static IP mapped to that FQDN
- Iagu SIP trunk details:
  - trunk host/IP
  - transport (`udp`/`tcp`/`tls`)
  - auth username
  - auth password
  - inbound DID list
  - outbound caller ID policy
- Consultant extension mapping table (consultant -> SIP extension)
- TLS email + DNS access for certbot challenge

## Notes

- Current environment does not allow passwordless `sudo`, so system configs are prepared in `ops/` and must be applied by an operator with root privileges.
