# Shared by the numbered scripts: where things are, the supported discs, logging. Dot-sourced:
#   . (Join-Path $PSScriptRoot "ff7-common.ps1")
#
# Layout (the WORKSPACE is the folder that holds this repository):
#   workspace\ff7-android\           this repository
#   workspace\discs\                 your .cue/.bin files (any names: found by their SHA-1)
#   workspace\tools-cache\           Java 17, Android SDK/NDK, Python, llvm-mingw (1-INSTALL-TOOLS.ps1)
#   workspace\recomps\ff7_recomp\    the game set up from your discs (2-PREPARE.ps1)
#   workspace\android-recomp\ff7_recomp\   the build: generated code, Android app, pre-compiled code
#   workspace\apks\                  finished APKs
#   workspace\logs\                  one log per script run
$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $PSScriptRoot
$Workspace = Split-Path -Parent $Repo
. (Join-Path $Repo "tools\paths.ps1")   # $DriveRoot (= workspace), $ToolsCache, $FrameworkDir, Find-*

$Game = "ff7_recomp"
$Package = "com.psxrecomp.ff7"
$DiscDir = Join-Path $Workspace "discs"
$RecompDir = Join-Path $DriveRoot "recomps\$Game"
$GameDir = Join-Path $DefaultWorkDir $Game
$ApkDir = Join-Path $Workspace "apks"
$LogDir = Join-Path $Workspace "logs"

# Supported dumps: the SHA-1 of each disc's .bin (one data track per disc).
$Supported = @(
    @{ Name = "Final Fantasy VII Shinra Archaeology Cut v1.0.5 (SCUS-94163, 3 discs)"
       Sha1 = @("d7525bb78c329c74b614e5af91dbe98e20591856",
                "7b8b4497554a546139141af81d70247618c9eb77",
                "884a7d5a3d8a39a476bbb7254b87dba5b6366faa") }
)

New-Item -ItemType Directory -Force $LogDir | Out-Null
$script:LogFile = Join-Path $LogDir ("{0}-{1}.log" -f [IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath), (Get-Date -Format "yyyyMMdd-HHmmss"))
function Say([string]$msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
    Write-Host $line
    Add-Content -Path $script:LogFile -Value $line
}
function Fail([string]$msg) { Say "FAIL: $msg"; exit 1 }

# Run a tool script (pwsh -File) and stop on failure. -DryRun only says what would run.
function Run-Step([string]$what, [string]$script, [string[]]$arguments = @()) {
    if ($DryRun) { Say "DRY RUN: would run $what ($script $($arguments -join ' '))"; return }
    Say "$what ..."
    pwsh -NoProfile -ExecutionPolicy Bypass -File $script @arguments 2>&1 | Tee-Object -FilePath $script:LogFile -Append | Out-Host
    if ($LASTEXITCODE -ne 0) { Fail "$what (exit $LASTEXITCODE; log $script:LogFile)" }
}

# The user's discs, in disc order, as .cue paths; matched by SHA-1 against $Supported.
function Find-Discs {
    if (-not (Test-Path $DiscDir)) { Fail "no discs folder: put your .cue/.bin files in $DiscDir" }
    $found = @{}
    foreach ($cue in Get-ChildItem -LiteralPath $DiscDir -Filter *.cue -File) {
        $bins = @(Get-Content -LiteralPath $cue.FullName | ForEach-Object {
            if ($_ -match '^\s*FILE\s+"([^"]+)"' -or $_ -match '^\s*FILE\s+(\S+)') { Join-Path $DiscDir $Matches[1] } })
        if ($bins.Count -ne 1 -or -not (Test-Path -LiteralPath $bins[0])) { Say "skip $($cue.Name): needs one .bin next to it"; continue }
        Say "checking $($cue.Name) ..."
        $sha = (Get-FileHash -LiteralPath $bins[0] -Algorithm SHA1).Hash.ToLower()
        foreach ($s in $Supported) {
            $i = [array]::IndexOf($s.Sha1, $sha)
            if ($i -ge 0) { $found[$i] = $cue.FullName; Say "  disc $($i + 1) of $($s.Name)" }
        }
        if (-not ($Supported | Where-Object { $_.Sha1 -contains $sha })) { Say "  not a supported dump (SHA-1 $sha)" }
    }
    $n = $Supported[0].Sha1.Count
    for ($i = 0; $i -lt $n; $i++) { if (-not $found.ContainsKey($i)) { Fail "disc $($i + 1) of $n not found in $DiscDir (see README: What you need)" } }
    return @(0..($n - 1) | ForEach-Object { $found[$_] })
}
