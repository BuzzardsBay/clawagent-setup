# ClawAgent v1.0.5 Azure validation — NOT RUN (Cycle 1 failed)

**Date:** 2026-05-11/12
**Status:** SKIPPED per hard rule "Only run Cycle 2 if Cycle 1 PASSES"

## Summary

Cycle 1 (ClawFactory v1.0.23) did not meet the strict PASS criteria — see `clawfactory-secure-setup/validation-runs/v1.0.23/REPORT.md` for details. The apiKeyRef fix is verified working at the data layer, but `switch-provider.ps1` exit codes ≠ 0 due to a pre-existing 12s gateway-health-check window being shorter than the actual gateway cold-restart time (~16s).

## What was built

- Installer: `C:\Users\bmcki\ClawAgent-Setup\Output\ClawAgent-Setup.exe` (340,530,984 bytes)
- Versions bumped: setup.ps1 InstallerVersion 1.0.4 → 1.0.5, ClawAgent-Setup.iss MyAppVersion "1.0.4" → "1.0.5"
- Bundled ClawChat.exe (11,702,272 bytes, SHA-256 `596c0825...`) — same binary that's bundled in ClawFactory v1.0.23
- Pushed to GitHub: commit c4571b7

## What was NOT validated

- Smoke test (Task 20)
- Bundled install.sh hash verification (Task 21)
- chatCompletions probe (Task 22)
- ClawChat launch verification (Task 23)
- 5-minute idle test (Task 24)

ClawAgent's PASS criteria do *not* include the provider-switch round-trip, so once the unrelated `switch-provider.ps1` 12s timeout is fixed in ClawFactory (or once we decide to re-run with looser criteria), this cycle should pass cleanly.

## Recommendation

Run a standalone Azure validation of ClawAgent v1.0.5 (independent of ClawFactory's Cycle 1 status), since the ClawAgent PASS criteria don't depend on provider switching. The bundled ClawChat is the same binary that already passed Task 14 in ClawFactory's cycle.
