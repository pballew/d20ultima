$dir = Join-Path $env:APPDATA 'Godot\app_userdata\Ultima-Style RPG\characters'
Write-Output "characters dir: $dir"
if (Test-Path $dir) {
    Get-ChildItem -Path $dir -File | ForEach-Object { Write-Output "FOUND: $($_.Name)" }
} else {
    Write-Output 'CHARACTERS_DIR_NOT_FOUND'
}
