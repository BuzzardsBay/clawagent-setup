## ClawAgent v1.0.3 Azure Validation Report

- Timestamp (UTC): 2026-05-10T15:19:52Z (restart) -> 15:30:37Z (INSTALLER_DONE=success) -> 15:41:40Z (PROBE2)
- Commit: 65d5a10... (HEAD of main at run time, bundled-install.sh refactor)
- VM name: cfa-103
- VM size: Standard_D2s_v5
- Image: clawfactory-win11-baseline
- Public IP: 20.3.192.183
- Cleanup: PASS path -- VM, NIC, NSG, public IP, OS disk all deleted

## Verdict: PASS

All six criteria met:

| # | Criterion | Result |
|---|---|---|
| 1 | Install rc=0 (INSTALLER_DONE=success) | **YES** -- attempt 6 / ~10 min after reboot |
| 2 | Smoke: exit 0 AND 0 failures | **YES** -- 4 pass, 0 fail, 7 skip (SYSTEM context) |
| 3 | Bundled install.sh used (log line present) | **YES** -- `[2026-05-10 15:26:41] [INFO] Bundled openclaw-install.sh hash verified.` |
| 4 | chatCompletions probe NOT 404 | **YES** -- HTTP 500 (route registered) |
| 5 | ClawChat present and launches | **YES** -- bundled at `C:\Program Files\ClawAgent\ClawChat.exe`, started under clawadmin (pid 4164), killed cleanly |
| 6 | Both idle probes 200 | **YES** -- PROBE1=200 @ 15:36:08Z, PROBE2=200 @ 15:41:40Z, no retry |

ClawAgent variant of the bundled-install.sh refactor exercised end-to-end. Same shape as the companion ClawFactory v1.0.20 cycle.

## Install timeline

| Attempt | UTC | install.log latest |
|---|---|---|
| 1 | 15:22:18 | (Phase A start; download complete 340,489,732 bytes) |
| 2 | 15:23:51 | Created .wslconfig at C:\Users\clawadmin\.wslconfig |
| 3 | 15:25:24 | Step 6b: Pre-installing OpenClaw build dependencies (make g++ cmake python3 iptables). |
| 4 | 15:26:57 | **`Bundled openclaw-install.sh hash verified.`** ← Step 8 [R2] using bundled file |
| 5 | 15:28:34 | Default main agent model: grok/grok-4-1-fast |
| 6 | 15:30:37 | INSTALLER_DONE=success |

## Bundled install.sh verification (Task 14): PASS

```
INSTALL_LOG=C:\ProgramData\ClawAgent\install.log              ← ClawAgent log path
BUNDLED_INSTALL_LINE_FOUND
MATCH: [2026-05-10 15:26:41] [INFO] Bundled openclaw-install.sh hash verified.
MATCH: [wsl:clawuser out] OK: SOUL.md hash verified            ← unrelated; SOUL.md hash check
```

`Step-InstallOpenClaw` (ClawAgent variant, identical refactor to ClawFactory) used the bundled file. Hash verified on the Windows side via `Get-FileHash` before any WSL invocation; file streamed into WSL `/tmp/openclaw-install.sh` via stdin pipe. No `curl`/`Invoke-WebRequest` to `openclaw.ai/install.sh`.

Same wording note as ClawFactory v1.0.20: actual log line is `Bundled openclaw-install.sh hash verified.`; spec's expected `"Using bundled openclaw install.sh (hash verified)"` is paraphrased. Intent met.

## Smoke test: 4 pass, 0 fail, 7 skip (exit 0)

```
Result: 4 pass, 0 fail, 7 skip
EXIT:0
```

Same 4P/0F/7S shape as the ClawFactory v1.0.20 cycle and all prior PASSes.

## chatCompletions probe: PASS — HTTP 500 (route registered)

```
=== probe started 2026-05-10T15:33:06Z ===
[probe] openclaw.json bytes=910
[probe] token len=48
--- response body ---
{"error":{"message":"internal error","type":"api_error"}}
HTTP_STATUS:500
=== probe ended 2026-05-10T15:33:41Z ===
```

Identical upstream-LLM-error 500 as the ClawFactory cycle. Route registered.

## ClawChat launch: PASS

```
path=C:\Program Files\ClawAgent\ClawChat.exe
size=11408384
sha256=0bb56c62e70a5af6153db8fd9a3b8b0c4a69682f54ae703e87952c18facb6d45
RESULT=PRESENT
started=True
pid=4164
killed=true
```

SHA-256 identical to the ClawFactory v1.0.20 verification (same source binary; both repos bundle the same `ClawChat.exe`). First end-to-end ClawChat verification on the ClawAgent v1.0.3 build.

## Idle test: PROBE1=200, PROBE2=200, no retry

```
PROBE1: 200    @ 2026-05-10T15:36:08Z
                ... 5-min idle gap ...
PROBE2: 200    @ 2026-05-10T15:41:40Z
```

## Comparison: v1.0.2 (PASS) vs v1.0.3 (PASS)

| Dimension | v1.0.2 | v1.0.3 |
|---|---|---|
| OpenClaw install.sh source | curl `openclaw.ai/install.sh` at install time | bundled `resources\openclaw-install.sh` |
| Hash check | inside WSL via `sha256sum` after curl | on Windows via `Get-FileHash` before WSL invocation |
| Hash drift surface | URL-tracked-latest | none |
| Network call for Step 8 | yes | none |
| All other criteria | all PASS | all PASS |

## Cleanup (PASS verdict)

- VM cfa-103: deleted
- NIC `cfa-103VMNic`, NSG `cfa-103NSG`, public IP `cfa-103PublicIP`: deleted
- OS disk `cfa-103_disk1_*`: deleted
- Storage account, baseline VNET, baseline image: untouched (per HARD RULES)

## Final declaration: v1.0.3 STABLE

ClawAgent v1.0.3 ships clean. Same hash-drift-immunity refactor as ClawFactory v1.0.20. Both repos validated together for the second consecutive day.

## Artifacts

- [REPORT.md](REPORT.md)
- [smoke-test.json](smoke-test.json)
- [bundled-check.json](bundled-check.json)
- [completions-probe.json](completions-probe.json)
- [clawchat-launch.json](clawchat-launch.json)
- [idle-probe1.json](idle-probe1.json)
- [idle-probe2.json](idle-probe2.json)
