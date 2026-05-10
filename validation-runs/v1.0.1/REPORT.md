## ClawAgent v1.0.1 Azure Validation Report

- Timestamp (UTC): 2026-05-10T03:30Z (decision point; cycle never executed)
- Commit: af60e6dce9f8ebeb4873eb50c6fa9b1360d9ca03
- VM: NOT PROVISIONED

## Verdict: SKIPPED (Cycle 1 FAILED)

Per the validation task spec, Cycle 2 (ClawAgent v1.0.1) only runs if Cycle 1 (ClawFactory v1.0.18) PASSES. Cycle 1 FAILED with `INSTALLER_DONE=failure reason=OpenClaw install blocked: SHA-256 mismatch.` Cycle 2 was therefore not executed.

## Pre-execution analysis

ClawAgent v1.0.1 shares the same `$OpenClawInstallSha256` pin with ClawFactory v1.0.18:

```
ClawAgent-Setup\setup.ps1:48
$OpenClawInstallSha256 = '57f025ba0272e2da3238984360e37fad5230bc7cea81854d154a362ea989d49d'
```

The live `openclaw.ai/install.sh` fetched on the cfv-118 VM during the v1.0.18 run hashed to `85fab09263b74b260157f785dd64ba2115f404fc85b1bb5fb4ceb1e45b8132ff` (size 92,380 bytes). Until the upstream file is reviewed and the pin bumped in both repos, ClawAgent will fail with the identical `[R2]` SHA-256 mismatch error at Step 8.

See [ClawFactory v1.0.18 REPORT.md](https://github.com/BuzzardsBay/clawfactory-secure-setup/blob/main/validation-runs/v1.0.18/REPORT.md) for full diagnostics.

## Recommended next steps

1. Review upstream install.sh diff (pinned vs. live).
2. Bump pin in **both** `ClawFactory-Secure-Setup\setup.ps1` and `ClawAgent-Setup\setup.ps1` to the new hash.
3. Bump versions: ClawFactory → 1.0.19, ClawAgent → 1.0.2.
4. Run a fresh full validation cycle.
