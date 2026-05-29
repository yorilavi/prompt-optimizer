# install.ps1 — install or update the prompt-optimizer skill for Claude Code on Windows.
#
# Three install paths, auto-detected:
#   1. LOCAL COPY  — run from inside the unzipped skill folder
#   2. UPDATE      — re-run after a previous git-clone install (does git pull)
#   3. CLONE       — fresh install from GitHub (works under `iwr ... | iex`)
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
# or remotely:
#   iwr -useb https://raw.githubusercontent.com/yorilavi/prompt-optimizer/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$SkillName      = "prompt-optimizer"
$RepoUrl        = "https://github.com/yorilavi/prompt-optimizer.git"
$RemotePattern  = "yorilavi/prompt-optimizer"
$SkillsDir      = Join-Path $env:USERPROFILE ".claude\skills"
$Target         = Join-Path $SkillsDir $SkillName

# Resolve script directory if we know where we are. Under `iex` pipe this stays
# empty and we'll fall through to clone mode below.
$ScriptDir = ""
if ($PSCommandPath) {
    $ScriptDir = Split-Path -Parent $PSCommandPath
} elseif ($MyInvocation.MyCommand.Path) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Require-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "git is required but was not found on PATH. Install git first (https://git-scm.com/downloads), then re-run this script."
        exit 1
    }
}

function Backup-Existing {
    if (Test-Path $Target) {
        $Stamp  = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        $Backup = "$Target.bak.$Stamp"
        Write-Host "Existing install found at $Target"
        Write-Host "Backing it up to $Backup"
        Move-Item -Path $Target -Destination $Backup
    }
}

function Mode-LocalCopy {
    Write-Host "Mode: local copy (using files in $ScriptDir)"
    if (-not (Test-Path $SkillsDir)) {
        New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
    }

    if (Test-Path (Join-Path $Target ".git")) {
        Write-Error "Refusing to overwrite the existing git checkout at $Target with local files. Run 'git pull' there, or remove the directory and re-run this script."
        exit 1
    }

    Backup-Existing
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    Copy-Item -Path (Join-Path $ScriptDir "SKILL.md") -Destination $Target

    $Changelog = Join-Path $ScriptDir "CHANGELOG.md"
    if (Test-Path $Changelog) {
        Copy-Item -Path $Changelog -Destination $Target
    }
}

function Mode-Update {
    Write-Host "Mode: update (existing git checkout at $Target)"
    Require-Git
    Push-Location $Target
    try { git pull --ff-only } finally { Pop-Location }
}

function Mode-Clone {
    Write-Host "Mode: fresh clone from $RepoUrl"
    Require-Git
    if (-not (Test-Path $SkillsDir)) {
        New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
    }
    Backup-Existing
    git clone --depth 1 $RepoUrl $Target
}

# Detection
$LocalSkillPath = if ($ScriptDir) { Join-Path $ScriptDir "SKILL.md" } else { "" }
$TargetGitPath  = Join-Path $Target ".git"

if ($ScriptDir -and ($ScriptDir -eq $Target)) {
    Write-Host "You're running install.ps1 from inside the target directory ($Target)."
    Write-Host "Use 'git pull' here to update, or run install.ps1 from another location."
    exit 0
} elseif ($ScriptDir -and (Test-Path $LocalSkillPath)) {
    Mode-LocalCopy
} elseif (Test-Path $TargetGitPath) {
    $ExistingRemote = ""
    Push-Location $Target
    try { $ExistingRemote = (git remote get-url origin 2>$null) } catch {} finally { Pop-Location }
    if ($ExistingRemote -match $RemotePattern) {
        Mode-Update
    } else {
        Write-Error "Existing git checkout at $Target has an unfamiliar remote: '$ExistingRemote'. Refusing to touch it. Move it aside and re-run for a fresh install."
        exit 1
    }
} else {
    Mode-Clone
}

# Verify
$InstalledSkill = Join-Path $Target "SKILL.md"
if (-not (Test-Path $InstalledSkill)) {
    Write-Error "Install verification failed — SKILL.md not present at $Target"
    exit 1
}

$Version = "?"
$VersionLine = Get-Content $InstalledSkill | Where-Object { $_ -match "^\s+version:\s*(\S+)" } | Select-Object -First 1
if ($VersionLine -match "^\s+version:\s*(\S+)") {
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
Write-Host "  3. Re-run this script any time to update."
