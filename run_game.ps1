# Usage: .\run_game.ps1 [-TimeoutSeconds <int>]
# If TimeoutSeconds <= 0 the launcher will NOT auto-exit the GUI.
param(
    [int]$TimeoutSeconds = 30,
    [string]$GodotExePath = ""
)

# Suppress non-terminating errors and stop any running Godot instances
$ErrorActionPreference = "SilentlyContinue"
Get-Process Godot_v4.4.1-stable_win64 | Stop-Process -Force
# Suppress non-terminating errors and stop any running Godot instances
$ErrorActionPreference = "SilentlyContinue"
Get-Process Godot_v4.4.1-stable_win64 | Stop-Process -Force

# Ensure log directory exists
$logPath = 'C:\temp\godot_output.log'
$logDir = Split-Path $logPath -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

# Run the console version first to check for errors and capture output to log
# If the user passed -GodotExePath, use that executable for the headless check as well.
$consoleExe = $null
if ($GodotExePath -and (Test-Path $GodotExePath)) {
    $consoleExe = (Resolve-Path $GodotExePath).Path
} else {
    # Prefer the Mono console exe if present so .cs resources can be recognized during the check.
    $consoleCandidates = @(
        './Godot_v4.4.1-stable_mono_win64_console.exe',
        './Godot_v4.4.1-stable_mono_win64.exe',
        './Godot_mono_console.exe',
        './Godot_mono.exe',
        './Godot_v4.4.1-stable_win64_console.exe'
    )
    foreach ($c in $consoleCandidates) {
        if (Test-Path $c) { $consoleExe = (Resolve-Path $c).Path; break }
    }
}

if (-not $consoleExe) {
    Write-Host "No Godot console executable found for headless check. Please add one to the project root or pass -GodotExePath." -ForegroundColor Red
    exit 1
}

$output = & $consoleExe --verbose --headless --quit 2>&1 | Tee-Object -FilePath $logPath
# Filter out cleanup/exit errors that don't affect gameplay
$criticalErrors = $output | Select-String -Pattern "ERROR:|SCRIPT ERROR:" | Where-Object {
    $_ -notmatch "cleanup \(core/object/object.cpp" -and
    $_ -notmatch "Cannot get path of node as it is not in a scene tree" -and
    $_ -notmatch "resources still in use at exit" -and
    $_ -notmatch "ObjectDB instances leaked at exit"
}

if ($criticalErrors) {
    Write-Host "Found critical errors in startup:"
    # Show the critical errors
    $criticalErrors | ForEach-Object {
        Write-Host "`nCRITICAL ERROR FOUND:" -ForegroundColor Red
        Write-Host $_
    }
    exit 1
} else {
    # No errors, run the normal version (GUI) and make it visible
    Write-Host "No startup errors found. Launching game..."

    # If the user explicitly passed a Godot exe path, prefer that (useful for local Mono builds)
    if ($GodotExePath -and (Test-Path $GodotExePath)) {
        Write-Host "Using Godot executable provided via -GodotExePath: $GodotExePath"
        $proc = Start-Process -FilePath (Resolve-Path $GodotExePath).Path -PassThru
    }
    else {
    # Prefer a Mono-enabled Godot executable if available (64-bit names commonly used).
    $monoCandidates = @(
        './Godot_v4.4.1-stable_mono_win64.exe',
        './Godot_v4.4.1-stable_mono_win64_console.exe',
        './Godot_mono.exe',
        './Godot_mono_win64.exe'
    )

    $godotExePath = $null
    foreach ($cand in $monoCandidates) {
        if (Test-Path $cand) { $godotExePath = (Resolve-Path $cand).Path; break }
    }

    if (-not $godotExePath) {
        # Fallback to the non-mono exe already present
        $fallback = './Godot_v4.4.1-stable_win64.exe'
        if (Test-Path $fallback) { $godotExePath = (Resolve-Path $fallback).Path }
    }

    if (-not $godotExePath) {
        Write-Host "Could not find a Godot executable to run in the workspace. Please drop a Godot Mono or non-Mono exe into the project root." -ForegroundColor Yellow
        exit 1
    }

    # Print whether dotnet SDK is available (helpful for Mono builds)
    try {
        $dotnetInfo = & dotnet --info 2>$null
        if ($LASTEXITCODE -eq 0) { Write-Host "dotnet SDK detected." }
        else { Write-Host "dotnet not found or not on PATH; C# compilation may fail if using Godot Mono." -ForegroundColor Yellow }
    } catch { Write-Host "dotnet not found or not on PATH; C# compilation may fail if using Godot Mono." -ForegroundColor Yellow }

        Write-Host "Starting Godot executable: $godotExePath"
        $proc = Start-Process -FilePath $godotExePath -PassThru
    }

    $timeoutSeconds = [int]$TimeoutSeconds
    if ($timeoutSeconds -le 0) {
        Write-Host "Started Godot (PID $($proc.Id)). No auto-exit (TimeoutSeconds=$timeoutSeconds)."
        # Do not wait; return to console and let user close Godot manually
    }
    else {
        Write-Host "Started Godot (PID $($proc.Id)). Game will auto-exit after $timeoutSeconds seconds to avoid long waits."
        $sw = [Diagnostics.Stopwatch]::StartNew()
        while (-not $proc.HasExited -and $sw.Elapsed.TotalSeconds -lt $timeoutSeconds) {
            Start-Sleep -Milliseconds 200
        }

        if (-not $proc.HasExited) {
            Write-Host "Timeout reached — terminating Godot process..."
            try { $proc.Kill() } catch { }
        }

        # Allow a brief moment for graceful shutdown
        Start-Sleep -Milliseconds 300
    }
}
