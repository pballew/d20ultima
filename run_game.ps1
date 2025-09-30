# Suppress non-terminating errors and stop any running Godot instances
$ErrorActionPreference = "SilentlyContinue"
Get-Process Godot_v4.4.1-stable_win64 | Stop-Process -Force

# Ensure log directory exists
$logPath = 'C:\temp\godot_output.log'
$logDir = Split-Path $logPath -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

# Run the console version first to check for errors and capture output to log
$output = & ./Godot_v4.4.1-stable_win64_console.exe --verbose --headless --quit 2>&1 | Tee-Object -FilePath $logPath
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
    # No errors, run the normal version
    Write-Host "No startup errors found. Launching game..."
    # Launch the GUI build and tee its stdout/stderr to the same log file so engine messages are recorded
    & ./Godot_v4.4.1-stable_win64.exe 2>&1 | Tee-Object -FilePath $logPath
}
