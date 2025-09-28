# Stop any running Godot processes
Get-Process Godot_v4.4.1-stable_win64 -ErrorAction SilentlyContinue | Stop-Process -Force

# Run the monster sprite generator
Write-Host "Generating monster sprites..."
& "./Godot_v4.4.1-stable_win64_console.exe" --headless --script "generate_monster_sprites.gd"

Write-Host "Monster sprite generation complete!"