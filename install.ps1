# install.ps1 — install the prompt-optimizer skill for Claude Code on Windows.
# Run from inside the unzipped skill folder:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1

$ErrorActionPreference = "Stop"

$SkillName = "prompt-optimizer"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsDir = Join-Path $env:USERPROFILE ".claude\skills"
$Target    = Join-Path $SkillsDir $SkillName

# No-op if we're running from inside the install target itself.
if ($ScriptDir -eq $Target) {
    Write-Host "Already running from the install target ($Target). Nothing to copy."
    exit 0
}

# Sanity: script directory must contain SKILL.md.
$ScriptSkill = Join-Path $ScriptDir "SKILL.md"
if (-not (Test-Path $ScriptSkill)) {
    Write-Error "SKILL.md not found in $ScriptDir. Run this script from inside the unzipped skill folder (where SKILL.md lives)."
    exit 1
}

if (-not (Test-Path $SkillsDir)) {
    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
}

# Back up any existing install so we never silently overwrite user changes.
if (Test-Path $Target) {
    $Stamp  = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Backup = "$Target.bak.$Stamp"
    Write-Host "Existing install found at $Target"
    Write-Host "Backing it up to $Backup"
    Move-Item -Path $Target -Destination $Backup
}

New-Item -ItemType Directory -Path $Target -Force | Out-Null
Copy-Item -Path $ScriptSkill -Destination $Target

$ChangelogPath = Join-Path $ScriptDir "CHANGELOG.md"
if (Test-Path $ChangelogPath) {
    Copy-Item -Path $ChangelogPath -Destination $Target
}

$InstalledSkill = Join-Path $Target "SKILL.md"
if (-not (Test-Path $InstalledSkill)) {
    Write-Error "Install verification failed — SKILL.md not present at $Target"
    exit 1
}

$Version = "?"
$VersionLine = Get-Content $InstalledSkill | Where-Object { $_ -match "^\s*version:\s*(\S+)" } | Select-Object -First 1
if ($VersionLine -match "^\s*version:\s*(\S+)") {
    $Version = $Matches[1]
}

Write-Host ""
Write-Host "Installed $SkillName v$Version at:"
Write-Host "  $Target"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart Claude Code (or start a new session)."
Write-Host "  2. Try:  /prompt-optimizer"
Write-Host "     or ask Claude to use the prompt optimizer skill."
Write-Host "  3. List installed skills with /skills to confirm it loaded."
