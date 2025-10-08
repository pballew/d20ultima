Param()

# Archives all .gd.disabled files into archive/gd_disabled preserving relative paths
# Usage: run from tools folder or via script path; this determines repo root reliably
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath -Parent
$repoRoot = Resolve-Path (Join-Path $scriptDir '..')
$archiveRoot = Join-Path $repoRoot 'archive\gd_disabled'
if (!(Test-Path $archiveRoot)) { New-Item -ItemType Directory -Path $archiveRoot -Force | Out-Null }

$files = Get-ChildItem -Path $repoRoot -Filter '*.gd.disabled' -Recurse
foreach ($f in $files) {
    $rel = $f.FullName.Substring($repoRoot.Path.Length).TrimStart('\')
    $dest = Join-Path $archiveRoot $rel
    $destDir = Split-Path $dest -Parent
    if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
    Remove-Item -LiteralPath $f.FullName -Force
    Write-Host "Archived and removed: $rel"
}

Write-Host "Archive complete. Archived $($files.Count) files to $archiveRoot"
