@echo off
echo Regenerating terrain tileset with enhanced graphics...
"Godot_v4.4.1-stable_win64.exe" --path . TileSetGenerator.tscn --headless
echo Tileset generation complete!
pause