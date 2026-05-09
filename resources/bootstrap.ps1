[CmdletBinding()]
param(
    [string]$WslDistro = 'Ubuntu',
    [string]$WslUser   = 'clawuser',
    [string]$LogFile   = (Join-Path $env:ProgramData 'ClawAgent\install.log')
)

# bootstrap.ps1 (ClawAgent v1.0.0) - single-agent variant.
# ClawFactory's bootstrap fanned a role-specific agent.md into 4 sub-agent dirs
# (orchestrator / skill-scout / skill-builder / publisher) plus copied
# auth-profiles.json into 5 per-agent dirs (refs openclaw/openclaw#44571,
# #12003 - the legacy global ~/.openclaw/auth-profiles.json fallback is
# unreliable on the 2026.4.x line, so the gateway looks for auth at
# ~/.openclaw/agents/<id>/agent/auth-profiles.json).
#
# ClawAgent ships with only the 'main' agent. This script:
#   1. Writes %ProgramData%\ClawAgent\agent-name.txt (default "Claw") if absent.
#   2. Copies the global auth-profiles.json into the per-agent canonical path
#      ~/.openclaw/agents/main/agent/auth-profiles.json so the gateway can
#      authenticate. The 4-agent fan-out from ClawFactory is removed.
#
# Notes preserved from the parent script:
# - Runs on Windows because stock Ubuntu has no pwsh and the egress firewall
#   does not whitelist packages.microsoft.com. WSL-side work goes through
#   wsl.exe + a base64-decoded bash heredoc, mirroring setup.ps1's
#   Invoke-WslBash. CRLF -> LF normalization is applied before encoding.
# - Idempotent: re-running overwrites the per-agent auth file cleanly;
#   agent-name.txt is preserved if already present (user's chosen name wins).

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

#--- Logging -----------------------------------------------------------------
function Write-BootstrapLog {
    param([string]$Level, [string]$Message)
    $ts   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts] [$Level] [bootstrap] $Message"
    if (Test-Path -LiteralPath (Split-Path -Parent $LogFile)) {
        Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8
    }
    if     ($Level -eq 'ERROR') { Write-Host $line -ForegroundColor Red }
    elseif ($Level -eq 'WARN')  { Write-Host $line -ForegroundColor Yellow }
    else                        { Write-Host $line }
}

#--- WSL helper (mirrors setup.ps1's Invoke-WslBash on purpose) --------------
function Invoke-WslBash {
    param([Parameter(Mandatory)][string]$Script)
    $enc = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Script.Replace("`r`n", "`n").Replace("`r", "`n")))
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = 'wsl.exe'
    $psi.Arguments              = "-d $WslDistro -u $WslUser --cd ~ -- bash -lc `"echo '$enc' | base64 -d | bash -l`""
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute        = $false
    $psi.CreateNoWindow         = $true
    $proc   = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    foreach ($line in ($stdout -split "`r?`n")) {
        $t = $line.Trim()
        if ($t) {
            if (Test-Path -LiteralPath (Split-Path -Parent $LogFile)) {
                Add-Content -LiteralPath $LogFile -Value "[wsl:$WslUser out] $t" -Encoding UTF8
            }
            Write-Host $t
        }
    }
    foreach ($line in ($stderr -split "`r?`n")) {
        $t = $line.Trim()
        if ($t -and ($t -notmatch '^wsl: Failed to translate ')) {
            if (Test-Path -LiteralPath (Split-Path -Parent $LogFile)) {
                Add-Content -LiteralPath $LogFile -Value "[wsl:$WslUser err] $t" -Encoding UTF8
            }
            Write-Host $t -ForegroundColor Yellow
        }
    }
    return $proc.ExitCode
}

function Write-DefaultAgentName {
    # Ensure %ProgramData%\ClawAgent\agent-name.txt exists with the silent
    # default "Claw". The rename script reads from this file. Never overwrite -
    # if the user has already renamed once, that decision sticks.
    $nameFile = Join-Path $env:ProgramData 'ClawAgent\agent-name.txt'
    if (Test-Path -LiteralPath $nameFile) {
        Write-BootstrapLog INFO "agent-name.txt already present at $nameFile; not overwriting."
        return
    }
    try {
        $tmp = "$nameFile.tmp.$PID"
        Set-Content -LiteralPath $tmp -Value 'Claw' -Encoding UTF8 -NoNewline
        Move-Item -LiteralPath $tmp -Destination $nameFile -Force
        Write-BootstrapLog INFO "Wrote default agent name (Claw) to $nameFile."
    } catch {
        Write-BootstrapLog WARN "Failed to write agent-name.txt: $($_.Exception.Message)"
    }
}

#--- Main --------------------------------------------------------------------
Write-BootstrapLog INFO 'Bootstrap starting (single-agent variant).'
Write-Host ''
Write-Host '== ClawAgent bootstrap: configuring single agent ==' -ForegroundColor Cyan

Write-DefaultAgentName

#--- auth-profiles per-agent fan-out (single agent only) ---------------------
# Refs openclaw/openclaw#44571, openclaw/openclaw#12003: the OpenClaw runtime
# reads auth from ~/.openclaw/agents/<id>/agent/auth-profiles.json and the
# legacy fallback to ~/.openclaw/auth-profiles.json is unreliable across the
# 2026.4.x line. Step-WireProviderKey wrote the legacy path; we copy it into
# main's per-agent canonical path here.
# Idempotent: cp overwrites cleanly; mkdir -p / chmod are idempotent.
# Graceful skip when SOURCE missing (Provider=later case).
$fanOutScript = @'
set -e
echo "[ClawAgent] Wiring auth-profiles.json into main agent's canonical path (refs openclaw/openclaw#44571, #12003)"

SOURCE="$HOME/.openclaw/auth-profiles.json"
if [ ! -f "$SOURCE" ]; then
    echo "[ClawAgent] No auth-profiles.json at $SOURCE - skipping (likely Provider=later)"
    exit 0
fi

target_dir="$HOME/.openclaw/agents/main/agent"
mkdir -p "$target_dir"
cp "$SOURCE" "$target_dir/auth-profiles.json"
chmod 600 "$target_dir/auth-profiles.json"
if [ -f "$target_dir/auth-profiles.json" ]; then
    echo "[ClawAgent]   main: auth-profiles wired"
else
    echo "[ClawAgent] ERROR: failed to write auth-profiles for main" >&2
    exit 13
fi
'@
$rcFanOut = Invoke-WslBash -Script $fanOutScript
if ($rcFanOut -ne 0) {
    Write-BootstrapLog WARN "auth-profiles wiring returned $rcFanOut; check ~/.openclaw/agents/main/agent/auth-profiles.json manually."
}

Write-BootstrapLog INFO 'Bootstrap complete.'

# Append 'AgentBootstrap' to %ProgramData%\ClawAgent\checkpoint.json. Mirrors
# setup.ps1's Save-Checkpoint shape. The smoke-test checks completedSteps for
# 'AgentBootstrap' to confirm Step 15 finished.
$checkpointFile = Join-Path $env:ProgramData 'ClawAgent\checkpoint.json'
try {
    $state = [ordered]@{ completedSteps = @() }
    if (Test-Path -LiteralPath $checkpointFile) {
        $json = Get-Content -LiteralPath $checkpointFile -Raw | ConvertFrom-Json
        $state.completedSteps = @($json.completedSteps)
    }
    if ($state.completedSteps -notcontains 'AgentBootstrap') {
        $state.completedSteps += 'AgentBootstrap'
        $state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $checkpointFile -Encoding UTF8
        Write-BootstrapLog INFO "Checkpoint updated: AgentBootstrap appended to $checkpointFile."
    } else {
        Write-BootstrapLog INFO "Checkpoint already contains AgentBootstrap; nothing to do."
    }
} catch {
    Write-BootstrapLog WARN "Failed to update checkpoint at ${checkpointFile}: $($_.Exception.Message)"
}

#--- "What to do next" -------------------------------------------------------
Write-Host ''
Write-Host '================================================================' -ForegroundColor Green
Write-Host '   ClawAgent ready. What to do next:                           ' -ForegroundColor Green
Write-Host '================================================================' -ForegroundColor Green
Write-Host ''
Write-Host ' 1. The gateway is already running on http://127.0.0.1:8787' -ForegroundColor White
Write-Host '    To restart it later if needed:' -ForegroundColor Gray
Write-Host '      wsl -d Ubuntu -u clawuser -- bash -lc "systemctl --user restart openclaw-gateway.service"' -ForegroundColor Gray
Write-Host ''
Write-Host ' 2. Verify the gateway is reachable from this host:' -ForegroundColor White
Write-Host '      curl http://127.0.0.1:8787/status' -ForegroundColor Gray
Write-Host '      (Expect HTTP 200. Any LAN machine that tries the same URL is' -ForegroundColor Gray
Write-Host '       blocked by the Windows Firewall inbound-deny rule on TCP/8787.)' -ForegroundColor Gray
Write-Host ''
Write-Host ' 3. Open a chat session with the agent:' -ForegroundColor White
Write-Host '      wsl -d Ubuntu -u clawuser -- bash -lc "openclaw chat"' -ForegroundColor Gray
Write-Host ''
Write-Host ' 4. Logs:' -ForegroundColor White
Write-Host '      Installer:   %ProgramData%\ClawAgent\install.log' -ForegroundColor Gray
Write-Host '      Gateway:     wsl -d Ubuntu -u clawuser -- cat ~/.openclaw/logs/gateway.log' -ForegroundColor Gray
Write-Host '      journald:    wsl -d Ubuntu -u clawuser -- journalctl --user -u openclaw-gateway' -ForegroundColor Gray
Write-Host ''
Write-Host ' 5. Emergency stop (Start Menu "ClawAgent Kill Switch" or):' -ForegroundColor White
Write-Host '      powershell -ExecutionPolicy Bypass -File "<install-dir>\resources\clawfactory-stop.ps1"' -ForegroundColor Gray
Write-Host ''
Write-Host ' 6. Want full multi-agent? Upgrade to ClawFactory at https://clawfactory.app' -ForegroundColor White
Write-Host ''

exit 0
