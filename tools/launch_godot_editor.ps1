# Stops any running Godot processes and launches the Godot editor with --editor
Set-Location -LiteralPath (Join-Path $PSScriptRoot '..')

# Stop running Godot processes (broad match)
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like 'Godot*' }
foreach ($p in $procs) {
    try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; Write-Host "Stopped $($p.ProcessName) (PID $($p.Id))" } catch { }
}

# Editor candidates (prefer Mono editor)
$candidates = @( './Godot_v4.5-stable_mono_win64.exe', './Godot_v4.5-stable_mono_win64_console.exe', './Godot_v4.4.1-stable_win64.exe', './Godot_v4.4.1-stable_win64_console.exe' )
$exe = $null
foreach ($c in $candidates) {
    if (Test-Path $c) { $exe = (Resolve-Path $c).Path; break }
}

if (-not $exe) { Write-Host 'No Godot executable found in project root.'; exit 1 }

Write-Host "Launching Godot editor: $exe"
Start-Process -FilePath $exe -ArgumentList '--editor'
Write-Host 'Launched editor.'
