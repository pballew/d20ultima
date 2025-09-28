# View monster sprites
param(
    [string]$MonsterName = ""
)

# Stop any running Godot processes
Get-Process Godot_v4.4.1-stable_win64 -ErrorAction SilentlyContinue | Stop-Process -Force

if ($MonsterName -eq "") {
    Write-Host "Available monster sprites:"
    Get-ChildItem "assets/monster_sprites/*.png" | ForEach-Object { 
        $name = $_.BaseName
        Write-Host "  $name"
    }
    Write-Host ""
    Write-Host "Usage: .\view_monster_sprite.ps1 [monster_name]"
    Write-Host "Example: .\view_monster_sprite.ps1 goblin"
} else {
    $spritePath = "assets/monster_sprites/$($MonsterName.ToLower()).png"
    if (Test-Path $spritePath) {
        Write-Host "Opening sprite viewer for $MonsterName..."
        & ".\Godot_v4.4.1-stable_win64.exe" "--path" "." "scenes/SpriteViewer.tscn"
    } else {
        Write-Host "ERROR: Sprite not found: $spritePath"
        Write-Host "Available sprites:"
        Get-ChildItem "assets/monster_sprites/*.png" | ForEach-Object { 
            $name = $_.BaseName
            Write-Host "  $name"
        }
    }
}