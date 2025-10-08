Set-Location -LiteralPath (Join-Path $PSScriptRoot '..')
$root = (Resolve-Path 'archive/gd_disabled').Path
Write-Host "Root: $root"

$files = Get-ChildItem -Path $root -Recurse -File
foreach ($f in $files) {
    $full = $f.FullName
    $pattern = '\\archive\\gd_disabled\\'
    $lastIdx = $full.LastIndexOf($pattern)
    if ($lastIdx -ge 0) {
        $after = $full.Substring($lastIdx + $pattern.Length)
        # if after still contains 'archive\gd_disabled', we strip to last occurrence
        while ($after.Contains($pattern)) { $after = $after.Substring($after.IndexOf($pattern) + $pattern.Length) }
        $dest = Join-Path $root $after
        $destDir = Split-Path $dest -Parent
        if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        if ($full -ne $dest) {
            Move-Item -LiteralPath $full -Destination $dest -Force
            Write-Host "Moved: $full -> $dest"
        }
    }
}

# Remove any empty directories under the archive root
$dirs = Get-ChildItem -Path $root -Recurse -Directory | Sort-Object -Property FullName -Descending
foreach ($d in $dirs) {
    $files = Get-ChildItem -Path $d.FullName -Force -Recurse -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer }
    $subdirs = Get-ChildItem -Path $d.FullName -Force -Directory -ErrorAction SilentlyContinue
    if (($files -eq $null -or $files.Count -eq 0) -and ($subdirs -eq $null -or $subdirs.Count -eq 0)) {
        Remove-Item -LiteralPath $d.FullName -Force -Recurse
        Write-Host "Removed empty dir: $($d.FullName)"
    }
}

Write-Host 'Final archive listing:'
Get-ChildItem -Path $root -Recurse | ForEach-Object { Write-Host $_.FullName }
