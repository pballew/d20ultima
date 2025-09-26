$ErrorActionPreference = "SilentlyContinue"
Get-Process Godot_v4.4.1-stable_win64 | Stop-Process -Force

Write-Host "Generating town sprite..."
& ./Godot_v4.4.1-stable_win64.exe "res://TownSpriteGenerator.tscn"