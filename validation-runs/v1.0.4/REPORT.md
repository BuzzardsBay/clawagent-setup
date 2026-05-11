## ClawAgent v1.0.4 Azure Validation Report

- Timestamp (UTC): 2026-05-11T20:54:04Z (restart) -> 21:04:41Z (INSTALLER_DONE=success) -> 21:15:46Z (PROBE2)
- Commit: 278e2e0... (HEAD of main at run time, ClawChat v1.1 bundle)
- VM name: cfa-104
- VM size: Standard_D2s_v5
- Image: clawfactory-win11-baseline
- Public IP: 20.114.59.242
- Cleanup: PASS path -- VM, NIC, NSG, public IP, OS disk all deleted

## Verdict: PASS

All six criteria met:

| # | Criterion | Result |
|---|---|---|
| 1 | Install rc=0 (INSTALLER_DONE=success) | **YES** -- attempt 6 / ~10 min after reboot |
| 2 | Smoke: exit 0 AND 0 failures | **YES** -- 4 pass, 0 fail, 7 skip (SYSTEM context) |
| 3 | Bundled install.sh used (log line present) | **YES** -- `[2026-05-11 21:01:09] [INFO] Bundled openclaw-install.sh hash verified.` |
| 4 | chatCompletions probe NOT 404 | **YES** -- HTTP 500 (route registered) |
| 5 | ClawChat present and launches | **YES** -- `C:\Program Files\ClawAgent\ClawChat.exe` SHA-256 `a16006ff…1bec8` (v1.1 build), started under clawadmin (pid 10152), killed cleanly |
| 6 | Both idle probes 200 | **YES** -- PROBE1=200 @ 21:09:59Z, PROBE2=200 @ 21:15:46Z, no retry |

ClawAgent variant of the ClawChat v1.1 bundle exercised end-to-end. Same shape as companion ClawFactory v1.0.21 cycle.

## Install timeline

| Attempt | UTC | install.log latest |
|---|---|---|
| 1 | 20:56:58 | Phase A download complete; "[WARN] Virtualization may be disabled" (benign — appears on every cycle) |
| 2 | 20:58:31 | `[wsl:root exit] 0` |
| 3 | 21:00:03 | **`Bundled openclaw-install.sh hash verified.`** |
| 4 | 21:01:36 | (Step 8 OpenClaw install in progress) |
| 5 | 21:03:08 | Default main agent model: grok/grok-4-1-fast |
| 6 | 21:04:41 | **INSTALLER_DONE=success** |

One attempt faster than cfv-121 (which hit attempt 7) — within typical run-to-run variance.

## Bundled install.sh verification (Task 14): PASS

```
INSTALL_LOG=C:\ProgramData\ClawAgent\install.log              ← ClawAgent log path
BUNDLED_INSTALL_LINE_FOUND
MATCH: [2026-05-11 21:01:09] [INFO] Bundled openclaw-install.sh hash verified.
```

Bundled-install path used. No network call to openclaw.ai/install.sh during install.

## Smoke test: 4 pass, 0 fail, 7 skip (exit 0)

Same 4P/0F/7S shape as all PASS cycles since v1.0.15.

## chatCompletions probe: PASS -- HTTP 500 (route registered)

```
=== probe started 2026-05-11T21:07:43Z ===
[probe] openclaw.json bytes=910
[probe] token len=48
HTTP_STATUS:500
=== probe ended 2026-05-11T21:08:22Z ===
```

## ClawChat launch: PASS

```
path=C:\Program Files\ClawAgent\ClawChat.exe
size=11700736                                                          ← 11.16 MB (v1.1)
sha256=a16006ffd494321ca03b5fe6e16a2a32fee89d9f9149b7a9362adc3ea361bec8 ← matches ClawFactory v1.0.21 + local build
RESULT=PRESENT
started=True
pid=10152
killed=true
```

Same binary as the ClawFactory v1.0.21 cycle (both repos bundle the same `resources/ClawChat.exe`). Verified launchable under ClawAgent's install root.

## Idle test: PROBE1=200, PROBE2=200, no retry

```
PROBE1: 200    @ 2026-05-11T21:09:59Z
                ... 5-min idle gap ...
PROBE2: 200    @ 2026-05-11T21:15:46Z
```

## Comparison: v1.0.3 (PASS) vs v1.0.4 (PASS)

| Dimension | v1.0.3 | v1.0.4 |
|---|---|---|
| ClawChat bundled binary | v1.0.0 (10.88 MB) | v1.1 (11.16 MB) |
| ClawChat features | conversation + streaming + theme | + settings tab + provider switching + security tiers + gateway auto-start |
| All other criteria | all PASS | all PASS |

## Cleanup (PASS verdict)

- VM cfa-104: deleted
- NIC `cfa-104VMNic`, NSG `cfa-104NSG`, public IP `cfa-104PublicIP`: deleted
- OS disk `cfa-104_disk1_*`: deleted
- Storage account, baseline VNET, baseline image: untouched

## Final declaration: v1.0.4 STABLE

ClawAgent v1.0.4 ships clean. Validated alongside ClawFactory v1.0.21 in back-to-back Azure cycles; both repos confirmed shipping the same ClawChat v1.1 binary with identical launch behavior.

## Artifacts

- [REPORT.md](REPORT.md)
- [smoke-test.json](smoke-test.json)
- [bundled-check.json](bundled-check.json)
- [completions-probe.json](completions-probe.json)
- [clawchat-launch.json](clawchat-launch.json)
- [idle-probe1.json](idle-probe1.json)
- [idle-probe2.json](idle-probe2.json)
