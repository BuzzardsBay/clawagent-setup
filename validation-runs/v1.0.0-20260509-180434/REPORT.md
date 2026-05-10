# ClawAgent v1.0.0 — Azure Validation Cycle REPORT

**Result: PASS**
**Date:** 2026-05-09
**Cycle:** v1.0.0
**VM:** cfa-v100 (20.83.241.86)
**Region:** westus2
**Subscription:** 43010359-5b4c-4d16-af11-10f6544b2978
**Resource Group:** clawfactory-validation
**Baseline Image:** clawfactory-win11-baseline
**Installer:** ClawAgent-Setup.exe (338,195,798 bytes)

---

## Task 0 — Preflight Cleanup

**Status: PASS**

RG state at start: storage account + VNET + baseline image only. No VMs, disks, NICs, NSGs, or public IPs present. No cleanup required.

Post-cleanup RG:
- `clawfactoryvalc467` (Microsoft.Storage/storageAccounts) — preserved
- `bake-vmVNET` (Microsoft.Network/virtualNetworks) — preserved
- `clawfactory-win11-baseline` (Microsoft.Compute/images) — preserved

---

## Task 1 — Upload Installer

**Status: PASS**

Uploaded `ClawAgent-Setup.exe` (338,195,798 bytes) to `clawfactoryvalc467/installers`.
Upload completed: 2026-05-09T21:45:44Z.

SAS URL (valid 3h from upload):
```
https://clawfactoryvalc467.blob.core.windows.net/installers/ClawAgent-Setup.exe?se=2026-05-10T00%3A44Z&sp=r&spr=https&sv=2026-04-06&sr=b&sig=rtY2bpRuLOSEmJCZ%2F3%2FpWbVEvOM0Nec2Di8hT48qOfE%3D
```

---

## Task 2 — Provision VM

**Status: PASS**

Public IP quota check: 0/3 (Standard SKU used — Basic SKU deprecated in this subscription).

VM details:
| Field | Value |
|---|---|
| Name | cfa-v100 |
| Size | Standard_D2s_v5 |
| Security type | Standard |
| Region | westus2 |
| Public IP | 20.83.241.86 |
| Private IP | 10.0.0.10 |
| Admin username | clawadmin |
| Admin password | ClawV1-69036Xq! |
| State | VM running |

**Note:** First `az vm create` attempt used `--public-ip-sku Basic` which is no longer allowed (0 Basic IPs permitted in this subscription). Retried successfully with `--public-ip-sku Standard`.

---

## Task 3 — Install via Proven Pattern

**Status: PASS**

Timeline:
| Time (UTC) | Event |
|---|---|
| 23:33:47 | Auto-logon registry keys set |
| 23:33:47 | install-wrapper.cmd written to C:\install\ |
| 23:33:47 | RunOnce key set |
| 23:33:47 | VM rebooted (reboot 1) |
| 23:34:03 | Auto-logon fired; RunOnce launched install-wrapper.cmd |
| 23:34:03 | First CMD attempt — **failed** (& in SAS URL broke CMD parsing) |
| 23:37:35 | Fixed: wrote C:\install\install.ps1, updated wrapper, re-set RunOnce |
| 23:38:15 | VM rebooted (reboot 2) |
| 23:38:32 | Auto-logon fired; PS1 wrapper started |
| 23:38:32 | Download started (338MB from Azure Blob Storage) |
| 23:45:47 | Download complete (338,195,798 bytes) |
| 23:45:47 | Inno Setup installer launched (silent, /VERYSILENT /SUPPRESSMSGBOXES) |
| 23:46:25 | Inno Setup launched post-install setup.ps1 |
| 23:46:25 | WSL rootfs (ext4.vhdx) import started |
| 23:53:39 | Installer exited: 0 |
| 23:53:39 | **INSTALLER_DONE=success** |

Total install time: ~8 minutes (download + install).

**Issue encountered and resolved:** `&` characters in SAS URL caused CMD parsing failure on first attempt. Fixed by writing a PS1 helper script (`C:\install\install.ps1`) which handles `&` in URL strings natively, and updating the CMD wrapper to call the PS1.

**INSTALLER_DONE=success** confirmed via registry `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment`.

---

## Task 4 — Smoke Test

**Status: PASS**

Run via `az vm run-command` (SYSTEM context). WSL-dependent checks skipped as designed.

| Check | Result |
|---|---|
| WSL automount disabled | SKIP (SYSTEM context) |
| Four agent.md files present | SKIP (SYSTEM context) |
| AgentBootstrap checkpoint recorded | **PASS** |
| Gateway responds 200 on loopback | **PASS** |
| Firewall inbound-deny rule on 8787 | **PASS** |
| Orchestrator SOUL hash substituted | SKIP (SYSTEM context) |
| auth-profiles.json present for all 5 agents | SKIP (SYSTEM context) |
| .wslconfig has vmIdleTimeout=-1 | SKIP (SYSTEM context) |
| WSL Host scheduled task registered and enabled | **PASS** |
| Egress firewall clawfactory chain present | SKIP (SYSTEM context) |
| OpenClaw build deps present | SKIP (SYSTEM context) |

**Result: 4 pass, 0 fail, 7 skip — exit code 0**

---

## Task 5 — chatCompletions Probe

**Status: PASS**

Scheduled task registered as `clawadmin` (LogonType Interactive), run via `CFA-CompletionsProbe`.

`openclaw.json` location: WSL rootfs (read via scheduled task as clawadmin).

| Field | Value |
|---|---|
| Model (agents.defaults.model.primary) | `grok/grok-4-1-fast` |
| Gateway bind | loopback:8787 |
| Auth mode | token |
| POST to `http://127.0.0.1:8787/v1/chat/completions` | HTTP 401 |

**PASS criterion:** HTTP status NOT 404. Result: 401 (Unauthorized — auth token not included in probe). Endpoint exists and responds.

---

## Task 6 — 5-Minute Idle Test

**Status: PASS**

Two `GET http://127.0.0.1:8787/status` probes via run-command with `-TimeoutSec 15`.

| Probe | Time (UTC) | Status |
|---|---|---|
| Probe 1 | 2026-05-09 23:59:30 | **200 OK** |
| Probe 2 | 2026-05-10 00:04:30 | **200 OK** |

Gateway remained alive across 5-minute idle window. PASS.

---

## Task 7 — Cleanup

**Status: PASS**

All validation resources deleted:
- VM `cfa-v100` — deleted
- OS disk `cfa-v100_disk1_115484f3c61248e0b8393ee2e6bae1b3` — deleted
- NIC `cfa-v100VMNic` — deleted
- NSG `cfa-v100NSG` — deleted
- Public IP `cfa-v100PublicIP` — deleted

Final RG state: 0 VMs, 0 disks, 1 image (clawfactory-win11-baseline preserved), storage account + VNET.

---

## Pass Criteria Summary

| Criterion | Result |
|---|---|
| INSTALLER_DONE=success | ✅ PASS |
| Smoke: exit 0, 0 failures | ✅ PASS (4 pass, 0 fail, 7 skip) |
| chatCompletions probe NOT 404 | ✅ PASS (401) |
| Idle: both probes 200 | ✅ PASS |

**Overall: PASS**

---

## Notes / Deviations from Spec

1. **Basic SKU public IP deprecated:** This subscription no longer allows Basic SKU public IPs in westus2 (limit: 0). Used Standard SKU instead. No functional impact.

2. **SAS URL CMD-parsing bug:** The `&` characters in Azure SAS URL query parameters break Windows CMD script parsing. Fixed by using a PowerShell script file (`install.ps1`) for the download step rather than inline CMD. This adds one extra reboot cycle.

3. **Two reboots instead of one:** Due to the CMD fix above, the VM required two boot cycles to complete installation (first boot: download failed; second boot: install succeeded).
