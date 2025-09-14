#!/usr/bin/env pwsh
# Script to help edit player sprites with Luna Paint

Write-Host "Player Sprite Editor Helper" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

$spriteDir = "assets/player_sprites"

if (Test-Path $spriteDir) {
    Write-Host "`nAvailable sprite files:" -ForegroundColor Yellow
    $sprites = Get-ChildItem -Path $spriteDir -Filter "*.png" | Sort-Object Name
    
    for ($i = 0; $i -lt $sprites.Count; $i++) {
        Write-Host "$($i + 1). $($sprites[$i].Name)" -ForegroundColor Cyan
    }
    
    Write-Host "`nTo edit a sprite:" -ForegroundColor Yellow
    Write-Host "1. Right-click on the sprite file in VS Code Explorer" -ForegroundColor White
    Write-Host "2. Select 'Open with Luna Paint'" -ForegroundColor White
    Write-Host "3. Edit with professional pixel art tools" -ForegroundColor White
    Write-Host "4. Save when finished (Ctrl+S)" -ForegroundColor White
    
    Write-Host "`nFor AI-generated sprites:" -ForegroundColor Yellow
    Write-Host "1. Open Command Palette (Ctrl+Shift+P)" -ForegroundColor White
    Write-Host "2. Type 'ChatGPT' and select a command" -ForegroundColor White
    Write-Host "3. Ask for pixel art descriptions or generation help" -ForegroundColor White
    
    Write-Host "`nExample AI prompts:" -ForegroundColor Yellow
    Write-Host "- 'Create a 32x32 pixel art Human Fighter'" -ForegroundColor Gray
    Write-Host "- 'Design an Elf Wizard sprite in retro game style'" -ForegroundColor Gray
    Write-Host "- 'Make a Dwarf Barbarian with axe, 32x32 pixels'" -ForegroundColor Gray
    
} else {
    Write-Host "No sprite directory found. Run the game first to generate sprites." -ForegroundColor Red
}

Write-Host "`nPress any key to continue..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
