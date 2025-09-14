extends Node
class_name PlayerIconFactory

# Cache: key = "race_class"
var _cache: Dictionary = {}
const ICON_SIZE := 32

# Simple palette per race
var race_palettes := {
	"Human": {"skin": Color(0.9,0.75,0.6), "primary": Color(0.2,0.3,0.8)},
	"Elf": {"skin": Color(0.85,0.8,0.7), "primary": Color(0.1,0.6,0.2)},
	"Dwarf": {"skin": Color(0.8,0.65,0.5), "primary": Color(0.6,0.3,0.1)},
	"Halfling": {"skin": Color(0.9,0.7,0.55), "primary": Color(0.4,0.5,0.2)},
	"Gnome": {"skin": Color(0.85,0.75,0.6), "primary": Color(0.7,0.2,0.7)},
	"Half-Elf": {"skin": Color(0.87,0.77,0.63), "primary": Color(0.25,0.45,0.85)},
	"Half-Orc": {"skin": Color(0.55,0.7,0.45), "primary": Color(0.35,0.5,0.2)},
	"Dragonborn": {"skin": Color(0.6,0.4,0.2), "primary": Color(0.8,0.3,0.15)},
	"Tiefling": {"skin": Color(0.55,0.25,0.25), "primary": Color(0.5,0.1,0.6)}
}

# Class emblem color + glyph mapping
var class_glyphs := {
	"Fighter": {"color": Color(0.7,0.7,0.7), "type": "sword"},
	"Rogue": {"color": Color(0.6,0.6,0.6), "type": "dagger"},
	"Wizard": {"color": Color(0.9,0.9,1.0), "type": "staff"},
	"Cleric": {"color": Color(1.0,1.0,0.8), "type": "mace"},
	"Ranger": {"color": Color(0.3,0.7,0.3), "type": "bow"},
	"Barbarian": {"color": Color(0.8,0.6,0.3), "type": "axe"}
}

func generate_icon(race_name: String, char_class_name: String) -> ImageTexture:
	var key = race_name + "_" + char_class_name
	if _cache.has(key):
		return _cache[key]
	var image = Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0))

	var palette = race_palettes.get(race_name, race_palettes["Human"])
	var glyph = class_glyphs.get(char_class_name, class_glyphs["Fighter"])

	_draw_base_body(image, palette)
	_draw_class_emblem(image, glyph)

	var tex = ImageTexture.new()
	tex.set_image(image)
	# Don't cache for main menu display to reduce memory usage
	return tex

func _draw_base_body(image: Image, palette: Dictionary):
	var skin = palette["skin"]
	var primary = palette["primary"]
	# Head circle (smaller for 32x32)
	var cx = ICON_SIZE/2
	var cy = 8
	var r = 5
	for x in range(ICON_SIZE):
		for y in range(ICON_SIZE):
			var dist = (Vector2(x,y) - Vector2(cx,cy)).length()
			if dist <= r:
				image.set_pixel(x,y,skin)
	# Torso rectangle (scaled down)
	for x in range(cx-3, cx+3):
		for y in range(cy+3, cy+13):
			if x >=0 and x < ICON_SIZE and y >=0 and y < ICON_SIZE:
				image.set_pixel(x,y, primary)
	# Simple legs (scaled down)
	for x in range(cx-2, cx):
		for y in range(cy+13, cy+20):
			if x >=0 and x < ICON_SIZE and y >=0 and y < ICON_SIZE:
				image.set_pixel(x,y, Color(0.15,0.15,0.2))
	for x in range(cx, cx+2):
		for y in range(cy+13, cy+20):
			if x >=0 and x < ICON_SIZE and y >=0 and y < ICON_SIZE:
				image.set_pixel(x,y, Color(0.15,0.15,0.2))

func _draw_class_emblem(image: Image, glyph: Dictionary):
	var color = glyph["color"]
	match glyph["type"]:
		"sword":
			for y in range(10, 22): image.set_pixel(24, y, color)
			for x in range(22, 26): image.set_pixel(x, 10, color)
		"dagger":
			for y in range(12, 20): image.set_pixel(23, y, color)
		"staff":
			for y in range(6, 25): image.set_pixel(25, y, color)
			for i in range(2): image.set_pixel(24+i, 6, color)
		"mace":
			for y in range(9, 23): image.set_pixel(24, y, color)
			for dx in range(-1,2):
				for dy in range(-1,2):
					image.set_pixel(24+dx, 9+dy, color)
		"bow":
			for y in range(9, 23): image.set_pixel(23, y, color)
			for y in range(9, 23):
				var offset = int(sin((y-9)/2.0)*1.5)
				image.set_pixel(23+offset, y, color)
		"axe":
			for y in range(9, 22): image.set_pixel(24, y, color)
			for x in range(24, 28):
				for y in range(9, 13): image.set_pixel(x, y, color)
		_:
			for y in range(10, 18): image.set_pixel(24, y, color)

func export_all_player_sprites():
	print("Generating all player sprite combinations...")
	
	# Create sprites directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("assets/player_sprites"):
		dir.make_dir_recursive("assets/player_sprites")
	
	var total_generated = 0
	
	# Generate all race/class combinations
	for race_name in race_palettes.keys():
		for char_class in class_glyphs.keys():
			var texture = generate_icon(race_name, char_class)
			var image = texture.get_image()
			
			# Save as PNG
			var filename = "assets/player_sprites/" + race_name + "_" + char_class + ".png"
			var result = image.save_png("res://" + filename)
			
			if result == OK:
				print("Generated: ", filename)
				total_generated += 1
			else:
				print("Failed to save: ", filename)
	
	print("Generated ", total_generated, " player sprites in assets/player_sprites/")
	return total_generated

func clear_cache():
	"""Clear the texture cache to free memory"""
	_cache.clear()
	print("PlayerIconFactory cache cleared")
