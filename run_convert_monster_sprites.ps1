# PowerShell runner for convert_monster_sprites.py
# Tries multiple Python launchers (python, python3, py -3, py), installs Pillow if missing, and runs the converter.

function Test-PythonLauncher {
    param($exe, $extraArgs)
    $args = @()
    if ($extraArgs) { $args += $extraArgs }
    $args += '-c'
    $args += 'import sys; print("PY_OK")'
    try {
        $out = & $exe @args 2>$null
        if ($LASTEXITCODE -eq 0 -or $out -match 'PY_OK') { return $true }
    } catch {
        return $false
    }
    return $false
}

# Candidate launchers: exe name and any extra args (like py -3)
$candidates = @(
    @{exe='python'; extra=@()},
    @{exe='python3'; extra=@()},
    @{exe='py'; extra=@('-3')},
    @{exe='py'; extra=@()}
)

$found = $null
foreach ($c in $candidates) {
    if (Test-PythonLauncher -exe $c.exe -extraArgs $c.extra) {
        $found = $c
        break
    }
}

if (-not $found) {
    Write-Error "No Python launcher found on PATH. Install Python (ensure it's added to PATH) or use the Microsoft Store/official installer."
    exit 1
}

$pythonExe = $found.exe
$pythonExtra = $found.extra
Write-Host "Using Python launcher: $pythonExe $([string]::Join(' ', $pythonExtra))"

function Run-PythonArgs {
    param($argsArray)
    $all = @()
    if ($pythonExtra) { $all += $pythonExtra }
    $all += $argsArray
    return & $pythonExe @all
}

# Check for Pillow
try {
    $check = Run-PythonArgs -argsArray @('-c', "import pkgutil; import sys; sys.exit(0) if pkgutil.find_loader('PIL') else sys.exit(2)")
} catch {}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Pillow not found; installing via pip..."
    try {
        Run-PythonArgs -argsArray @('-m','pip','install','--user','pillow') | Out-Null
    } catch {
        Write-Error "Failed to install Pillow. Try running: $pythonExe $([string]::Join(' ', $pythonExtra)) -m pip install --user pillow"
        exit 2
    }
}

# Run converter
Write-Host "Running monster sprite converter..."
try {
    Run-PythonArgs -argsArray @('${PWD}\scripts\convert_monster_sprites.py')
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Conversion finished. Check assets/monster_sprites_transparent/"
        exit 0
    } else {
        Write-Error "Converter exited with code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} catch {
    Write-Error "Failed to run converter: $_"
    exit 3
}
