Set-Location -LiteralPath (Join-Path $PSScriptRoot '..')
$root = (Resolve-Path 'archive/gd_disabled').Path
Write-Host "Flattening nested archive under $root"

$files = Get-ChildItem -Path $root -Recurse -File | Where-Object { $_.FullName -match '\\archive\\gd_disabled\\archive\\gd_disabled\\' }
if ($files -eq $null -or $files.Count -eq 0) {
    Write-Host 'No nested files to move.'
} else {
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($root.Length).TrimStart('\')
        # remove the duplicated archive/gd_disabled prefix
        $newRel = $rel -replace '^archive\\gd_disabled\\',''
        $dest = Join-Path $root $newRel
        $destDir = Split-Path $dest -Parent
        if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Move-Item -LiteralPath $f.FullName -Destination $dest -Force
        Write-Host "Moved: $($f.FullName) -> $dest"
    }
}

Write-Host 'Final listing:'
Get-ChildItem -Path $root -Recurse | ForEach-Object { Write-Host $_.FullName }
