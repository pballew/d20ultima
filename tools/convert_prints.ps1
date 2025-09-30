# Bulk convert print(...) -> DebugLogger.info(...) in GDScript files (best-effort)
# Excludes DebugLogger.gd to avoid touching the logger itself.

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$files = Get-ChildItem -Path "$root\.." -Recurse -Filter *.gd | Where-Object { $_.FullName -notmatch "\\scripts\\DebugLogger.gd$" }

foreach ($f in $files) {
    $path = $f.FullName
    try {
        $text = Get-Content -Path $path -Raw -ErrorAction Stop
    } catch {
        Write-Host ("Could not read {0}: {1}" -f $path, $_)
        continue
    }

    $new = $text -replace '\bprint\(', 'DebugLogger.info('

    # Map obvious ERROR/WARN lines that use string literals
    # Double-quoted
    $new = [regex]::Replace($new, 'DebugLogger.info\(\s*"(ERROR[:\s].*?)"', 'DebugLogger.error("$1"')
    $new = [regex]::Replace($new, 'DebugLogger.info\(\s*"(WARN(?:ING)?[:\s].*?)"', 'DebugLogger.warn("$1"')
    # Single-quoted
    $new = [regex]::Replace($new, "DebugLogger.info\(\s*'(ERROR[:\s].*?)'", "DebugLogger.error('$1')")
    $new = [regex]::Replace($new, "DebugLogger.info\(\s*'(WARN(?:ING)?[:\s].*?)'", "DebugLogger.warn('$1')")

    if ($new -ne $text) {
        Set-Content -Path $path -Value $new -Encoding UTF8
        Write-Host "Updated: $path"
    }
}

Write-Host "Conversion script completed."