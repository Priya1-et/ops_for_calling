# End-to-End Validation Matrix

## Registration

- Browser opens and registers consultant over `WSS`.
- Kill browser tab and reopen: registration succeeds again.
- Asterisk contact list shows active consultant contact.

## Outbound Call

- Dial external number from browser.
- Confirm customer ring and answer.
- Confirm two-way audio for at least 30 seconds.
- Hang up from browser and confirm backend call status is `disconnected`.

## Inbound Call

- Call business DID from external phone.
- Consultant browser gets incoming popup with caller number.
- Reject flow stores `rejected` or `missed`.
- Accept flow connects audio and logs duration.

## DND

- Enable DND in browser for consultant.
- Inbound call should not ring consultant (busy/missed path is used).
- Disable DND and verify ringing resumes.

## NAT/TURN

- Test from restrictive network (mobile hotspot or office firewall).
- Verify ICE includes `relay` candidate.
- Verify no one-way audio.

## Failure Handling

- Stop browser network briefly, then restore and re-register.
- Restart Asterisk and verify expected outage and recovery behavior.
- Stop coturn and verify alert/no-audio detection in runbook.
