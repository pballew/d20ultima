Set-Location -LiteralPath (Join-Path $PSScriptRoot '..')
$root = (Resolve-Path 'archive/gd_disabled').Path
Write-Host "Archive root: $root"

Write-Host "Listing current files..."
Get-ChildItem -Path $root -Recurse | ForEach-Object { Write-Host $_.FullName }

Write-Host "Searching for nested archive paths..."
$pattern = '\\archive\\gd_disabled\\archive\\gd_disabled\\'
$files = Get-ChildItem -Path $root -Recurse | Where-Object { $_.FullName -like "*$pattern*" }
if ($files -eq $null -or $files.Count -eq 0) {
    Write-Host 'No nested archive paths found.'
} else {
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($root.Length).TrimStart('\')
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
