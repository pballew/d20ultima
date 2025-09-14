$ErrorActionPreference = "SilentlyContinue"
Get-Process Godot_v4.4.1-stable_win64 | Stop-Process -Force

# Run the console version first to check for errors
$output = & ./Godot_v4.4.1-stable_win64_console.exe --verbose --headless --quit 2>&1
$hasErrors = $output | Select-String -Pattern "ERROR:|SCRIPT ERROR:"

if ($hasErrors) {
    Write-Host "Found errors in startup:"
    # Show the full output for better context
    $output | ForEach-Object {
        if ($_ -match "(ERROR|SCRIPT ERROR):") {
            Write-Host "`nERROR FOUND:" -ForegroundColor Red
            Write-Host $_
        } elseif ($_ -match "^\s+at:") {
            Write-Host $_ -ForegroundColor Yellow
        } else {
            # Store some context lines
            $context = $_
        }
    }
    exit 1
} else {
    # No errors, run the normal version
    Write-Host "No startup errors found. Launching game..."
    & ./Godot_v4.4.1-stable_win64.exe
}
