extends Node

# Script to create a simple town sprite display in the console
func _ready():
	DebugLogger.info("Generating town sprite pattern...")

	var sprite_pattern = create_town_ascii_art()
	DebugLogger.info("\nGenerated Town Sprite (32x32 pixels):")
	DebugLogger.info("=====================================")
	for line in sprite_pattern:
		DebugLogger.info(line)
	DebugLogger.info("=====================================")
    
	DebugLogger.info("\nLegend:")
	DebugLogger.info("  . = Transparent")
	DebugLogger.info("  # = Stone walls (light gray)")
	DebugLogger.info("  ^ = Roof (red-brown)")
	DebugLogger.info("  | = Chimney (dark gray)")
	DebugLogger.info("  * = Smoke (light gray)")
	DebugLogger.info("  o = Windows (yellow)")
	DebugLogger.info("  █ = Door (dark brown)")
	DebugLogger.info("  ≡ = Wood building (brown)")

	get_tree().quit()

func create_town_ascii_art() -> Array:
	# Create a 32x32 ASCII representation of our town sprite
	var lines = []
	
	# Initialize with transparent background
	for y in range(32):
		var line = ""
		for x in range(32):
			line += "."
		lines.append(line)
	
	# Draw the town buildings
	
	# Smoke from chimney (top)
	_set_char(lines, 11, 12, "*")
	_set_char(lines, 12, 13, "*") 
	_set_char(lines, 10, 14, "*")
	
	# Main building roof (triangular)
	for y in range(12, 18):
		var roof_width = (y - 12) + 1
		var start_x = 7 - (roof_width / 2)
		var end_x = 7 + (roof_width / 2)
		for x in range(start_x, end_x + 1):
			if x >= 0 and x < 32:
				_set_char(lines, x, y, "^")
	
	# Tower roof (pointed)
	for y in range(4, 12):
		var roof_width = (y - 4) + 1
		var start_x = 18 - (roof_width / 2)
		var end_x = 18 + (roof_width / 2)
		for x in range(start_x, end_x + 1):
			if x >= 0 and x < 32:
				_set_char(lines, x, y, "^")
	
	# Small building roof
	for y in range(11, 16):
		var roof_width = (y - 11) + 1
		var start_x = 12 - (roof_width / 2)
		var end_x = 12 + (roof_width / 2)
		for x in range(start_x, end_x + 1):
			if x >= 0 and x < 32:
				_set_char(lines, x, y, "^")
	
	# Chimney
	_draw_rect(lines, 10, 15, 2, 5, "|")
	
	# Main building walls
	_draw_rect(lines, 2, 18, 12, 12, "#")
	
	# Tower walls  
	_draw_rect(lines, 14, 12, 8, 18, "#")
	
	# Small building walls
	_draw_rect(lines, 8, 16, 8, 10, "≡")
	
	# Windows on main building
	_draw_rect(lines, 4, 22, 2, 3, "o")
	_draw_rect(lines, 8, 22, 2, 3, "o")
	
	# Windows on tower
	_draw_rect(lines, 16, 16, 2, 2, "o")
	_draw_rect(lines, 19, 20, 2, 2, "o")
	
	# Door on main building
	_draw_rect(lines, 6, 26, 2, 4, "█")
	
	return lines

func _set_char(lines: Array, x: int, y: int, char: String):
	if y >= 0 and y < lines.size() and x >= 0 and x < 32:
		var line = lines[y]
		lines[y] = line.substr(0, x) + char + line.substr(x + 1)

func _draw_rect(lines: Array, x: int, y: int, width: int, height: int, char: String):
	for py in range(y, y + height):
		for px in range(x, x + width):
			_set_char(lines, px, py, char)