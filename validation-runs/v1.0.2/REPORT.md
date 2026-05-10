## ClawAgent v1.0.2 Azure Validation Report

- Timestamp (UTC): 2026-05-10T13:29:07Z (restart) -> 13:39:44Z (INSTALLER_DONE=success) -> 13:50:45Z (PROBE2)
- Commit: 635edbb4... (HEAD of main at run time, hash-bump commit)
- VM name: cfa-102
- VM size: Standard_D2s_v5
- Image: clawfactory-win11-baseline
- Public IP: 20.236.34.238
- Cleanup: PASS path — VM, NIC, NSG, public IP, OS disk all deleted

## Verdict: PASS

All five criteria met:

| # | Criterion | Result |
|---|---|---|
| 1 | Install rc=0 (INSTALLER_DONE=success) | **YES** — observed at attempt 6 / ~10 min after reboot |
| 2 | Smoke: exit 0 AND 0 failures | **YES** — 4 pass, 0 fail, 7 skip (SYSTEM context) |
| 3 | chatCompletions probe NOT 404 | **YES** — HTTP 500 (route registered; upstream LLM error from placeholder API key) |
| 4 | ClawChat present and launches | **YES** — bundled at `C:\Program Files\ClawAgent\ClawChat.exe`, started cleanly under clawadmin (pid 5540), killed without error |
| 5 | Both idle probes 200 | **YES** — PROBE1=200 @ 13:44:59Z, PROBE2=200 @ 13:50:45Z, no retry |

First Azure validation cycle for the ClawAgent variant that exercises the ClawChat bundle. Pin bump matches the companion ClawFactory v1.0.19 cycle exactly.

## Install timeline

| Attempt | UTC | install.log latest |
|---|---|---|
| 1 | 13:31:31 | (Steps 1-2; just past Phase A download of 340,462,155 bytes) |
| 2 | 13:33:04 | Step 3: Writing initial /etc/wsl.conf (automount off, systemd on). |
| 3 | 13:34:37 | Step 8 [R2]: Installing OpenClaw with SHA-256 pinning. |
| 4 | 13:36:09 | Step 9: Configuring OpenClaw via `openclaw config set` (real CLI). |
| 5 | 13:38:11 | Default main agent model: grok/grok-4-1-fast |
| 6 | 13:39:44 | INSTALLER_DONE=success |

Step 8 [R2] passed cleanly with the new pin. The diff prior→current was reviewed (in the ClawFactory repo's `validation-runs/install-sh-review/`) and got SAFE TO PROCEED before the bump landed in both repos.

## Smoke test: 4 pass, 0 fail, 7 skip (exit 0)

```
Running as NT AUTHORITY\SYSTEM - WSL checks will be SKIPPED.
  SKIP  WSL automount disabled (requires WSL; running as SYSTEM)
  SKIP  Four agent.md files present (requires WSL; running as SYSTEM)
  PASS  AgentBootstrap checkpoint recorded
  PASS  Gateway responds 200 on loopback
  PASS  Firewall inbound-deny rule on 8787
  SKIP  Orchestrator SOUL hash substituted (requires WSL; running as SYSTEM)
  SKIP  auth-profiles.json present for all 5 agents (requires WSL; running as SYSTEM)
  SKIP  .wslconfig has vmIdleTimeout=-1 (requires WSL; running as SYSTEM)
  PASS  WSL Host scheduled task registered and enabled
  SKIP  Egress firewall clawfactory chain present in nft ruleset (requires WSL; running as SYSTEM)
  SKIP  OpenClaw build deps present (make g++ cmake python3) (requires WSL; running as SYSTEM)
Result: 4 pass, 0 fail, 7 skip
EXIT:0
```

Bit-for-bit identical to ClawFactory v1.0.19 cycle (which is itself bit-for-bit with prior PASS shapes back to v1.0.15).

## chatCompletions probe: PASS — HTTP 500 (route registered)

```
=== probe started 2026-05-10T13:43:10Z ===
[probe] openclaw.json bytes=910
[probe] token len=48
--- response body ---
{"error":{"message":"internal error","type":"api_error"}}
HTTP_STATUS:500
=== probe ended 2026-05-10T13:43:46Z ===
```

Same upstream-LLM-error 500 as the ClawFactory cycle. Route patch ($script9b in setup.ps1) shipped intact in ClawAgent v1.0.2 and registers the route correctly.

## ClawChat launch verification: PASS

```
=== ClawChat probe 2026-05-10T13:44:14Z ===
path=C:\Program Files\ClawAgent\ClawChat.exe
size=11408384
sha256=0bb56c62e70a5af6153db8fd9a3b8b0c4a69682f54ae703e87952c18facb6d45
RESULT=PRESENT
started=True
pid=5540
killed=true
```

SHA-256 identical to the ClawFactory v1.0.19 verification (same source binary, copied to both installers' `resources\` dirs during the v1.0.18 bundle session). First end-to-end ClawChat verification on the ClawAgent variant.

## Idle test: PROBE1=200, PROBE2=200, no retry

```
PROBE1: 200    @ 2026-05-10T13:44:59Z
                ... 5-min idle gap ...
PROBE2: 200    @ 2026-05-10T13:50:45Z
```

Both first-attempt 200s within 15-second budget. ClawAgent's WSL Host scheduled task + vmIdleTimeout=-1 keep WSL/gateway alive idle, same as ClawFactory.

## Comparison: v1.0.1 (SKIPPED) vs v1.0.2 (PASS)

| Dimension | v1.0.1 (SKIPPED) | v1.0.2 (PASS) |
|---|---|---|
| Reason | Cycle 1 (ClawFactory v1.0.18) FAILed on shared install.sh hash | Cycle 1 (ClawFactory v1.0.19) PASSed; cleared for run |
| OpenClaw install.sh pin | `57f025ba…d49d` (stale) | `3a617b73…a9ce` (current) |
| Step 8 [R2] | (not reached) | PASS |
| Install completed | (not reached) | YES |
| Smoke / completions / ClawChat / idle | (not reached) | All PASS |

## Cleanup (PASS verdict)

- VM cfa-102: deleted
- NIC `cfa-102VMNic`, NSG `cfa-102NSG`, public IP `cfa-102PublicIP`: deleted
- OS disk `cfa-102_disk1_30b2422910ca49778e3f99fab2bd0777`: deleted
- Storage account, baseline VNET, baseline image: untouched (per HARD RULES)

## Final declaration: v1.0.2 STABLE

ClawAgent v1.0.2 ships clean. Same hash-pin fix as ClawFactory v1.0.19; same smoke shape; same idle behavior; same ClawChat bundle. Both repos validated together for the first time after the ClawChat bundling work landed in v1.0.18.

## Artifacts

- [REPORT.md](REPORT.md)
- [smoke-test.json](smoke-test.json)
- [completions-probe.json](completions-probe.json)
- [clawchat-launch.json](clawchat-launch.json)
- [idle-probe1.json](idle-probe1.json)
- [idle-probe2.json](idle-probe2.json)
