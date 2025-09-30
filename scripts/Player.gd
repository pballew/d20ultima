class_name Player
extends Character

@export var movement_speed: float = 200.0
@export var encounters_enabled: bool = false  # Random encounters enabled (default OFF)
@export var camera_smooth_speed: float = 8.0  # Higher = snappier, lower = slower (increased for better responsiveness)
const TILE_SIZE = 32
var current_target_position: Vector2
var is_moving: bool = false
var is_in_combat: bool = false
var character_class: CharacterData.CharacterClass = CharacterData.CharacterClass.FIGHTER  # Store character class for hit dice
var camera: Camera2D
var edge_threshold: int = 3  # Number of tiles from edge to start scrolling (reduced for more responsive scrolling)
var frames_to_ignore_input: int = 0
var camera_target: Vector2
var initial_setup_complete: bool = false  # Flag to delay world bounds checking

signal movement_finished
signal encounter_started
signal camping_started
signal town_name_display(town_name: String)

func _ready():
	super._ready()
	current_target_position = global_position
	# Get camera from parent (Main scene)
	camera = get_parent().get_node("Camera2D")
	if camera:
		camera_target = camera.global_position
	create_player_sprite()
	
	# Delay initial setup completion to allow proper camera positioning
	await get_tree().create_timer(0.1).timeout
	initial_setup_complete = true

func set_camera_target(target_pos: Vector2):
	camera_target = target_pos
	if camera:
		camera.global_position = target_pos

func load_from_character_data(char_data: CharacterData):
	character_name = char_data.character_name
	character_class = char_data.character_class  # Store character class for hit dice calculations
	strength = char_data.strength
	dexterity = char_data.dexterity
	constitution = char_data.constitution
	intelligence = char_data.intelligence
	wisdom = char_data.wisdom
	charisma = char_data.charisma
	level = char_data.level
	max_health = char_data.max_health
	current_health = char_data.current_health
	experience = char_data.experience
	attack_bonus = char_data.attack_bonus
	damage_dice = char_data.damage_dice
	armor_class = char_data.armor_class
	# world_position now stored as tile-center already (no half-tile offset needed)
	global_position = char_data.world_position

	# Apply fog of war explored tiles if available
	var fow = get_tree().get_root().find_child("FogOfWar", true, false)
	if fow:
		var explored_dict = fow.get("explored")
		if explored_dict is Dictionary:
			# Always clear previous character's fog to avoid leakage between characters
			explored_dict.clear()
			# If the loaded character has saved explored tiles, restore them
			if char_data.explored_tiles and char_data.explored_tiles.size() > 0:
				for v in char_data.explored_tiles:
					explored_dict[Vector2i(int(v.x), int(v.y))] = true
			# Recalculate visibility around current position (ensures starting tile visible for new chars)
			if fow.has_method("reveal_around_position"):
				fow.reveal_around_position(global_position)
			if fow.has_method("queue_redraw"):
				fow.queue_redraw()
	frames_to_ignore_input = 1
	DebugLogger.info("Loaded character: %s - Level %s %s" % [character_name, str(level), str(char_data.get_class_name())])

func save_to_character_data() -> CharacterData:
	var char_data = CharacterData.new()
	char_data.character_name = character_name
	char_data.character_class = character_class
	char_data.strength = strength
	char_data.dexterity = dexterity
	char_data.constitution = constitution
	char_data.intelligence = intelligence
	char_data.wisdom = wisdom
	char_data.charisma = charisma
	char_data.level = level
	char_data.max_health = max_health
	char_data.current_health = current_health
	char_data.experience = experience
	char_data.attack_bonus = attack_bonus
	char_data.damage_dice = damage_dice
	char_data.armor_class = armor_class
	# Save as tile-centered position (no offset math)
	char_data.world_position = global_position

	# Persist fog of war explored tiles
	var fow = get_tree().get_root().find_child("FogOfWar", true, false)
	if fow:
		var explored_dict = fow.get("explored")
		if explored_dict is Dictionary:
			var arr: Array = []
			for key in explored_dict.keys():
				arr.append(Vector2(key.x, key.y))
			char_data.explored_tiles = PackedVector2Array(arr)
			var radius = fow.get("reveal_radius_tiles")
			if typeof(radius) == TYPE_INT:
				char_data.last_reveal_radius = int(radius)
	char_data.save_timestamp = Time.get_datetime_string_from_system()
	
	return char_data

func create_player_sprite():
	# Create a pixel art player character
	var sprite = get_node("Sprite2D")
	var race_name = "Human"
	var player_class_name = "Fighter"
	
	# Set z_index to ensure player renders above terrain
	z_index = 10
	sprite.z_index = 10
	DebugLogger.info("Set player z_index to 10 for proper rendering")
	
	# Simple fallback - just use default icon for now
	# TODO: Integrate with character data when class/race methods are available
	
	# Try to find existing factory or create new one
	var factory = get_tree().get_root().find_child("PlayerIconFactory", true, false)
	if factory == null:
		# Load the script and create instance
		var factory_script = load("res://scripts/PlayerIconFactory.gd")
		if factory_script:
			factory = factory_script.new()
			factory.name = "PlayerIconFactory"
			get_tree().get_root().add_child.call_deferred(factory)
	
	if factory and factory.has_method("generate_icon"):
		var texture = factory.generate_icon(race_name, player_class_name)
		sprite.texture = texture
	else:
		# Fallback to simple texture creation
		sprite.texture = create_player_texture()

func create_player_texture() -> ImageTexture:
	# Create 32x32 texture for player
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Colors for the player character
	var skin_color = Color(0.9, 0.7, 0.6)
	var hair_color = Color(0.4, 0.2, 0.1)
	var shirt_color = Color(0.2, 0.3, 0.8)
	var pants_color = Color(0.1, 0.4, 0.1)
	var sword_color = Color(0.7, 0.7, 0.7)
	var background = Color(0, 0, 0, 0)  # Transparent
	
	# Fill background
	for x in range(32):
		for y in range(32):
			image.set_pixel(x, y, background)
	
	# Draw head (circle-ish) - scaled to 32x32
	var head_center_x = 16
	var head_center_y = 8
	var head_radius = 5
	
	for x in range(32):
		for y in range(32):
			var distance = sqrt((x - head_center_x) * (x - head_center_x) + (y - head_center_y) * (y - head_center_y))
			if distance < head_radius:
				image.set_pixel(x, y, skin_color)
	
	# Draw hair
	for x in range(head_center_x - 3, head_center_x + 3):
		for y in range(head_center_y - 3, head_center_y - 1):
			if x >= 0 and x < 32 and y >= 0 and y < 32:
				image.set_pixel(x, y, hair_color)
	
	# Draw body (shirt)
	for x in range(head_center_x - 2, head_center_x + 2):
		for y in range(head_center_y + 2, head_center_y + 6):
			if x >= 0 and x < 32 and y >= 0 and y < 32:
				image.set_pixel(x, y, shirt_color)
	
	# Draw arms
	for x in range(head_center_x - 3, head_center_x - 1):
		for y in range(head_center_y + 2, head_center_y + 5):
			if x >= 0 and x < 32 and y >= 0 and y < 32:
				image.set_pixel(x, y, skin_color)
	
	for x in range(head_center_x + 1, head_center_x + 3):
		for y in range(head_center_y + 2, head_center_y + 5):
			if x >= 0 and x < 32 and y >= 0 and y < 32:
				image.set_pixel(x, y, skin_color)
	
	# Draw sword in right hand
	for x in range(head_center_x + 3, head_center_x + 4):
		for y in range(head_center_y + 1, head_center_y + 6):
			if x >= 0 and x < 32 and y >= 0 and y < 32:
				image.set_pixel(x, y, sword_color)
	
	# Draw legs (pants)
	for x in range(head_center_x - 1, head_center_x):
		for y in range(head_center_y + 6, head_center_y + 10):
			if x >= 0 and x < 32 and y >= 0 and y < 32:
				image.set_pixel(x, y, pants_color)
	
	for x in range(head_center_x, head_center_x + 1):
		for y in range(head_center_y + 6, head_center_y + 10):
			if x >= 0 and x < 32 and y >= 0 and y < 32:
				image.set_pixel(x, y, pants_color)
	
	# Draw feet
	for x in range(head_center_x - 2, head_center_x + 2):
		for y in range(head_center_y + 10, head_center_y + 11):
			if x >= 0 and x < 32 and y >= 0 and y < 32:
				image.set_pixel(x, y, Color(0.3, 0.2, 0.1))  # Brown boots
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _input(event):
	# Handle debug keys with higher priority using _input instead of _unhandled_input
	if event is InputEventKey and event.pressed:
		DebugLogger.info("DEBUG INPUT: Key pressed - keycode: %s key name: %s" % [event.keycode, event.as_text()])
		
		# Specific check for T key (keycode should be 84)
		if event.keycode == KEY_T or event.keycode == 84:
			DebugLogger.info("*** T KEY DETECTED! TELEPORTING! ***")
			debug_teleport_to_town()
			get_viewport().set_input_as_handled()
			return
		
		# Test F9 detection
		if event.keycode == KEY_F9:
			DebugLogger.info("*** F9 DETECTED! ***")
			debug_teleport_to_town()
			get_viewport().set_input_as_handled()
			return
			
		# Also test with F8 as backup
		if event.keycode == KEY_F8:
			DebugLogger.info("*** F8 DETECTED AS BACKUP! ***")
			debug_teleport_to_town()
			get_viewport().set_input_as_handled()
			return
			
		# Test simple P key for debugging
		if event.keycode == KEY_P:
			DebugLogger.info("*** P KEY DETECTED FOR TELEPORT TEST! ***")
			debug_teleport_to_town()
			get_viewport().set_input_as_handled()
			return
			
		# F10 for town search
		if event.keycode == KEY_F10:
			DebugLogger.info("=== F10 FIND NEARBY TOWNS ===")
			# Guarded call: try local method, otherwise try Main node, otherwise log
			if has_method("find_nearby_towns"):
				call("find_nearby_towns")
			else:
				var main_node = get_tree().get_root().find_node("Main", true, false)
				if main_node and main_node.has_method("find_nearby_towns"):
					main_node.call("find_nearby_towns")
				else:
					DebugLogger.info("find_nearby_towns() not available")
			get_viewport().set_input_as_handled()
			return
			
		# F11 for map debug
		if event.keycode == KEY_F11:
			DebugLogger.info("=== F11 MAP DEBUG INFO ===")
			var terrain = get_parent().get_node_or_null("EnhancedTerrainTileMap")
			if not terrain:
				terrain = get_parent().get_node_or_null("EnhancedTerrain")
			if terrain and terrain.has_method("print_map_debug_info"):
				terrain.print_map_debug_info()
				if terrain.has_method("test_coordinate_conversions"):
					terrain.test_coordinate_conversions()
			get_viewport().set_input_as_handled()
			return
		
		# F12 for hit dice test
		if event.keycode == KEY_F12:
			DebugLogger.info("=== F12 HIT DICE TEST ===")
			# Guarded call: try local, then look for a node with the test function
			if has_method("test_hit_dice_system"):
				call("test_hit_dice_system")
			else:
				var node_with_test = get_tree().get_root().find_node("TestF9", true, false)
				if node_with_test and node_with_test.has_method("test_hit_dice_system"):
					node_with_test.call("test_hit_dice_system")
				else:
					DebugLogger.info("test_hit_dice_system() not available")
			get_viewport().set_input_as_handled()
			return
			
		# Tab to toggle combat log
		if event.keycode == KEY_TAB:
			toggle_combat_log()
			get_viewport().set_input_as_handled()
			return

func _unhandled_input(event):
	# This is now just a fallback - _input should catch debug keys first
	pass

func _physics_process(delta):
	# Ignore input for a frame after loading character
	if frames_to_ignore_input > 0:
		frames_to_ignore_input -= 1
	else:
		handle_input()
	
	if is_moving:
		global_position = global_position.move_toward(current_target_position, movement_speed * delta)
		if global_position.distance_to(current_target_position) < 1.0:
			global_position = current_target_position
			is_moving = false
			movement_finished.emit()

		# Smoothly update background position based on camera
		if has_node("Background") and camera:
			var bg_sprite = get_node("Background")
			# Center background on camera
			bg_sprite.position = camera.global_position

	# Continuously ensure camera follows edge logic when not moving
	update_camera_position()

	# Smooth camera movement toward target
	if camera:
		if camera_target == null:
			camera_target = camera.global_position
		var t = clamp(camera_smooth_speed * delta, 0.0, 1.0)
		camera.global_position = camera.global_position.lerp(camera_target, t)

func move_to_tile(new_position: Vector2):
	if not is_moving:
		DebugLogger.info(str("DEBUG: Player moving to tile: ") + " " + str(new_position))
		current_target_position = new_position
		is_moving = true
		
		# Check if we're moving onto a town tile
		check_for_town_at_position(new_position)
		
		# Check if camera should scroll based on edge proximity
		update_camera_position()

func update_camera_position():
	if not camera:
		return
	
	# Skip world bounds checking for the first few frames to allow proper initial positioning
	if not initial_setup_complete:
		# Just keep camera on player during initial setup
		camera_target = global_position
		return
	
	# Get the viewport size in world coordinates
	var viewport = get_viewport()
	if not viewport:
		return
		
	var viewport_size = viewport.get_visible_rect().size
	var world_viewport_size = viewport_size / camera.zoom
	
	# Calculate edge threshold in world units
	var tile_size = TILE_SIZE
	var edge_distance = edge_threshold * tile_size
	
	# Current player and camera positions
	var player_pos = global_position

	# Acquire terrain bounds - use conservative bounds instead of full world
	var terrain = get_parent().get_node_or_null("EnhancedTerrainTileMap")
	if not terrain:
		terrain = get_tree().get_root().find_child("EnhancedTerrainTileMap", true, false)
	if not terrain:
		# Fallback to legacy terrain system
		terrain = get_parent().get_node_or_null("EnhancedTerrainTileMap")
		if not terrain:
			terrain = get_tree().get_root().find_child("EnhancedTerrainTileMap", true, false)
	if not terrain or not terrain.has_method("get_used_rect"):
		return

	# Get conservative bounds around current player position instead of full world
	var player_section = terrain.get_section_id_from_world_pos(player_pos) if terrain.has_method("get_section_id_from_world_pos") else Vector2i(0, 0)
	
	# Get the actual terrain dimensions (25x20 tiles per section for new system)
	var section_width = 25 if terrain.has_method("get_section_id_from_world_pos") else 50
	var section_height = 20 if terrain.has_method("get_section_id_from_world_pos") else 40
	
	# Create bounds that include current section and immediate neighbors (3x3 grid)
	var conservative_bounds = Rect2i(
		Vector2i((player_section.x - 1) * section_width - section_width/2, (player_section.y - 1) * section_height - section_height/2),
		Vector2i(section_width * 3, section_height * 3)  # 3x3 sections
	)
	
	var world_pos = Vector2(conservative_bounds.position) * tile_size
	var world_size = Vector2(conservative_bounds.size) * tile_size
	var half_viewport = world_viewport_size * 0.5

	# If world smaller than viewport, just center on world center
	if world_size.x <= world_viewport_size.x and world_size.y <= world_viewport_size.y:
		camera.global_position = world_pos + world_size * 0.5
		return
	
	# If this is the first time setting up, don't jump to world center, stay near player
	if not initial_setup_complete and camera_target == null:
		camera_target = player_pos
		return

	# Limits (clamped so camera never shows beyond world edges)
	var left_limit = world_pos.x + half_viewport.x
	var right_limit = world_pos.x + world_size.x - half_viewport.x
	var top_limit = world_pos.y + half_viewport.y
	var bottom_limit = world_pos.y + world_size.y - half_viewport.y

	# Dead zones
	var horizontal_dead_zone = max(0.0, half_viewport.x - edge_distance)
	var vertical_dead_zone = max(0.0, half_viewport.y - edge_distance)

	var cam_pos = camera_target if camera_target != null else camera.global_position

	# Horizontal incremental movement (one tile step when outside dead zone)
	var h_diff = player_pos.x - cam_pos.x
	if abs(h_diff) > horizontal_dead_zone:
		cam_pos.x += sign(h_diff) * TILE_SIZE

	# Vertical incremental movement
	var v_diff = player_pos.y - cam_pos.y
	if abs(v_diff) > vertical_dead_zone:
		cam_pos.y += sign(v_diff) * TILE_SIZE

	# Clamp after stepping
	cam_pos.x = clamp(cam_pos.x, left_limit, right_limit)
	cam_pos.y = clamp(cam_pos.y, top_limit, bottom_limit)

	# Set target (actual movement happens in _physics_process smoothing)
	camera_target = cam_pos

func handle_input():
	# Debug: Check if T key is being pressed here
	if Input.is_key_pressed(KEY_T):
		DebugLogger.info("DEBUG HANDLE_INPUT: T key is pressed!")
	
	# Don't allow movement if in combat or already moving
	if is_moving or is_in_combat:
		return
	
	# Check for camping input
	if Input.is_action_just_pressed("camp"):
		start_camping()
		return
	# Check for sprite generation (F12 key)
	if Input.is_action_just_pressed("ui_text_completion_accept") or Input.is_key_pressed(KEY_F12):
		generate_all_sprites()
		return
			
	var input_vector = Vector2.ZERO
	
	if Input.is_action_just_pressed("move_up"):
		input_vector.y -= 1
	elif Input.is_action_just_pressed("move_down"):
		input_vector.y += 1
	elif Input.is_action_just_pressed("move_left"):
		input_vector.x -= 1
	elif Input.is_action_just_pressed("move_right"):
		input_vector.x += 1
	
	if input_vector != Vector2.ZERO:
		DebugLogger.info("DEBUG: Input detected: %s" % input_vector)
		var new_position = global_position + (input_vector * TILE_SIZE)
		DebugLogger.info("DEBUG: New position calculated: %s" % new_position)
		
		# Check if the new position is walkable
		var terrain = get_parent().get_node("EnhancedTerrainTileMap")
		if terrain and terrain.has_method("is_walkable"):
			# Ensure needed map sections are loaded around new position
			if terrain.has_method("ensure_sections_loaded_around_position"):
				terrain.ensure_sections_loaded_around_position(new_position)
			
			if terrain.is_walkable(new_position):
				move_to_tile(new_position)
				
				# Check for random encounters with terrain-based rates
				if encounters_enabled:
					check_for_random_encounter(new_position, terrain)
		else:
			# If no terrain, allow movement (fallback)
			move_to_tile(new_position)
			
			# Check for random encounters (default rate)
			if encounters_enabled and randf() < 0.08:
				encounter_started.emit()

func enable_encounters():
	encounters_enabled = true
	DebugLogger.info("Encounters enabled")

func disable_encounters():
	encounters_enabled = false
	DebugLogger.info("Encounters disabled")

func enter_combat():
	is_in_combat = true
	DebugLogger.info("Player entered combat - movement disabled")

func exit_combat():
	is_in_combat = false
	DebugLogger.info("Player exited combat - movement enabled")

func start_camping():
	DebugLogger.info("Hole up and Camp")
	
	# Restore player to full health
	if current_health < max_health:
		var health_to_restore = max_health - current_health
		heal(health_to_restore)
		DebugLogger.info("Rested and recovered %s hit points" % health_to_restore)
	else:
		DebugLogger.info(str("Already at full health, but enjoyed a good rest"))
	
	# Emit camping signal for UI overlay
	camping_started.emit()

func generate_all_sprites():
	DebugLogger.info("Generating all player sprite combinations...")
	
	# Load and create the factory
	var factory_script = load("res://scripts/PlayerIconFactory.gd")
	if factory_script:
		var factory = factory_script.new()
		# Ensure we have a terrain reference for town searches in this helper
		var terrain = get_parent().get_node_or_null("EnhancedTerrainTileMap")
		if not terrain:
			terrain = get_parent().get_node_or_null("EnhancedTerrain")
		if factory.has_method("export_all_player_sprites"):
			DebugLogger.info("Factory supports export_all_player_sprites; searching nearby area...")
			DebugLogger.info("Searching in 25x25 area...")
			var start_pos = global_position - Vector2(12 * TILE_SIZE, 12 * TILE_SIZE)
			DebugLogger.info("Search area from: %s to: %s" % [start_pos, start_pos + Vector2(24 * TILE_SIZE, 24 * TILE_SIZE)])
			var found_count = 0
			for x in range(25):
				for y in range(25):
					var check_pos = start_pos + Vector2(x * TILE_SIZE, y * TILE_SIZE)
					if terrain and terrain.has_method("get_town_data_at_position"):
						var town_data = terrain.get_town_data_at_position(check_pos)
						if not town_data.is_empty():
							found_count += 1
							DebugLogger.info("*** FOUND TOWN #%s: %s at position: %s ***" % [found_count, town_data.get("name", "Unknown"), check_pos])

			# Also specifically test the known town position
			DebugLogger.info("=== TESTING KNOWN TOWN POSITION ===")
			var known_pos = Vector2(-192, -128)
			var known_town = null
			if terrain and terrain.has_method("get_town_data_at_position"):
				known_town = terrain.get_town_data_at_position(known_pos)
			if known_town and not known_town.is_empty():
				DebugLogger.info("SUCCESS: Found town at known position %s: %s" % [known_pos, known_town])
			else:
				DebugLogger.info("FAILED: No town found at known position %s" % known_pos)

			DebugLogger.info("=== FOUND %s TOWNS IN SEARCH AREA ===" % found_count)

			# Test specific positions to see if the function works at all
			DebugLogger.info("=== TESTING SPECIFIC POSITIONS ===")
			var test_positions = [
				Vector2(0, 0), Vector2(32, 32), Vector2(64, 64), Vector2(100, 100),
				Vector2(200, 200), Vector2(400, 400), Vector2(500, 500)
			]
			for test_pos in test_positions:
				var town_data = null
				if terrain and terrain.has_method("get_town_data_at_position"):
					town_data = terrain.get_town_data_at_position(test_pos)
				if town_data and not town_data.is_empty():
					DebugLogger.info("TOWN at test position %s: %s" % [test_pos, town_data])
				else:
					DebugLogger.info("No town at test position %s" % test_pos)


			# Try to get direct section information from the terrain system
			DebugLogger.info("=== DIRECT TERRAIN DEBUG ===")
			if terrain and terrain.has_method("print_section_towns"):
				terrain.print_section_towns(Vector2i(0, 0))
			else:
				DebugLogger.info("No print_section_towns method available")
			
			DebugLogger.info("=== END TOWN SEARCH ===")

func check_for_town_at_position(world_pos: Vector2):
	"""Check if the given position has a town and show dialog if found"""
	DebugLogger.info("=== CHECK_FOR_TOWN_AT_POSITION DEBUG ===")
	DebugLogger.info("DEBUG: Input world position: %s" % world_pos)
	DebugLogger.info("DEBUG: TILE_SIZE: %s" % TILE_SIZE)

	# Convert player center position to tile top-left corner position
	# Player position is center of tile, but towns are stored using top-left coordinates
	var tile_top_left = Vector2(
		floor(world_pos.x / TILE_SIZE) * TILE_SIZE,
		floor(world_pos.y / TILE_SIZE) * TILE_SIZE
	)
	DebugLogger.info("DEBUG: Converted to tile top-left: %s" % tile_top_left)

	# Also calculate the tile coordinates for debugging
	var tile_coords = Vector2i(int(tile_top_left.x / TILE_SIZE), int(tile_top_left.y / TILE_SIZE))
	DebugLogger.info("DEBUG: Tile coordinates: %s" % tile_coords)

	# Get terrain system (try both TileMap and legacy implementations)
	var terrain = get_parent().get_node_or_null("EnhancedTerrainTileMap")
	if not terrain:
		terrain = get_parent().get_node_or_null("EnhancedTerrain")

	DebugLogger.info("DEBUG: Terrain found: %s" % (terrain != null))
	if terrain and terrain.has_method("get_town_data_at_position"):
		DebugLogger.info("DEBUG: Calling get_town_data_at_position with tile top-left")
		var town_data = terrain.get_town_data_at_position(tile_top_left)
		DebugLogger.info("DEBUG: Town data result: %s" % town_data)
		if not town_data.is_empty():
			var town_name = town_data.get("name", "Unknown Town")
			DebugLogger.info("Player stepped on town: %s" % town_name)

			# Emit signal for town name display
			DebugLogger.info("DEBUG: About to emit town_name_display signal with: %s" % town_name)
			town_name_display.emit(town_name)
			DebugLogger.info("DEBUG: Signal emitted successfully")

			# Show dialog for town entry after a short delay (let welcome text show first)
			DebugLogger.info("DEBUG: About to show town entry dialog")
			await get_tree().create_timer(0.5).timeout  # Wait 0.5 seconds

			# Get GameController to show town dialog
			var game_controller = get_tree().get_first_node_in_group("game_controller")
			if not game_controller:
				# Try to find GameController by traversing up the scene tree
				var node = self
				while node and not node.has_method("show_town_dialog"):
					node = node.get_parent()
				game_controller = node

			DebugLogger.info("DEBUG: Found GameController: %s" % (game_controller != null))
			if game_controller and game_controller.has_method("show_town_dialog"):
				DebugLogger.info("DEBUG: Calling show_town_dialog")
				game_controller.show_town_dialog(town_data)
			else:
				DebugLogger.info("Could not find GameController to show town dialog")

func debug_teleport_to_town():
	"""Debug function to teleport player to a known town location"""
	DebugLogger.info("=== DEBUG TELEPORT TO TOWN ===")
	DebugLogger.info("Current player position BEFORE teleport: %s" % global_position)

	# Find an actual town to teleport to from the terrain data
	DebugLogger.info("Looking for terrain system...")
	var parent_node = get_parent()
	DebugLogger.info("Parent node: %s" % (parent_node.name if parent_node else "null"))
	var parent_children_names = []
	if parent_node:
		for child in parent_node.get_children():
			parent_children_names.append(child.name)
	DebugLogger.info("Parent children: %s" % [parent_children_names])

	var terrain = get_parent().get_node_or_null("EnhancedTerrainTileMap")
	DebugLogger.info("EnhancedTerrainTileMap found: %s" % (terrain != null))
	if not terrain:
		terrain = get_parent().get_node_or_null("EnhancedTerrain")
		DebugLogger.info("EnhancedTerrain found: %s" % (terrain != null))
	if not terrain:
		DebugLogger.error("ERROR: No terrain system found!")
		return

	DebugLogger.info("Terrain system found: %s (class: %s)" % [terrain.name, terrain.get_class()])
	# Search ALL sections for ANY town using direct access to terrain data
	DebugLogger.info("Searching ALL sections for towns...")
	var found_town = false
	var town_world_pos = Vector2.ZERO
	var town_name = "Unknown"
	var towns_found = []

	# Access map sections directly if possible
	if terrain.map_sections and terrain.map_sections.size() > 0:
		DebugLogger.info("Found %s map sections, searching for towns..." % terrain.map_sections.size())

		# Search through all sections for towns
		for section_id in terrain.map_sections.keys():
			var section = terrain.map_sections[section_id]

			# Check if section has town data (new format)
			var town_dict = section.get("town_data")
			if section and town_dict and town_dict is Dictionary and town_dict.size() > 0:
				DebugLogger.info("Section %s has %s towns" % [section_id, town_dict.size()])

				# Get the first available town
				for local_pos in town_dict.keys():
					var town_data = town_dict[local_pos]

					# Convert to world position using terrain's coordinate system
					var global_tile_pos = terrain.world_to_global_tile(local_pos, section_id)
					var world_pos = Vector2(global_tile_pos.x * TILE_SIZE, global_tile_pos.y * TILE_SIZE)

					town_name = town_data.get("name", "Found Town")
					town_world_pos = world_pos
					found_town = true
					towns_found.append({"name": town_name, "pos": world_pos})
					DebugLogger.info("*** FOUND TOWN: '%s' at position: %s ***" % [town_name, town_world_pos])
					break

			# Also check terrain_data for TOWN terrain type (fallback/legacy)
			if not found_town and section.terrain_data:
				DebugLogger.info("  Checking terrain_data for TOWN tiles...")
				for local_pos in section.terrain_data.keys():
					var terrain_type = section.terrain_data[local_pos]
					if terrain_type == terrain.TerrainType.TOWN:
						DebugLogger.info("    FOUND TOWN TERRAIN at local pos: %s" % local_pos)

						# Convert to world position using terrain's coordinate system
						var global_tile_pos = terrain.world_to_global_tile(local_pos, section_id)
						var world_pos = Vector2(global_tile_pos.x * TILE_SIZE, global_tile_pos.y * TILE_SIZE)

						town_name = "Town at " + str(global_tile_pos)
						town_world_pos = world_pos
						found_town = true
						towns_found.append({"name": town_name, "pos": world_pos})
						DebugLogger.info("*** FOUND TOWN TERRAIN: '%s' at position: %s ***" % [town_name, town_world_pos])
						break

			if found_town:
				break
	else:
		DebugLogger.info("No map_sections found or accessible, trying fallback method...")

		# Fallback: try the manual town at (5,5) that we know exists
		var manual_town_pos = Vector2(5 * TILE_SIZE, 5 * TILE_SIZE)
		if terrain.has_method("get_town_data_at_position"):
			var town_data = terrain.get_town_data_at_position(manual_town_pos)
			if not town_data.is_empty():
				town_name = town_data.get("name", "Manual Town")
				town_world_pos = manual_town_pos
				found_town = true
				towns_found.append({"name": town_name, "pos": manual_town_pos})
				DebugLogger.info("*** FOUND MANUAL TOWN: '%s' at position: %s ***" % [town_name, town_world_pos])

	if not found_town:
		DebugLogger.info("No towns found in any section! Creating fallback town at origin")
		town_world_pos = Vector2(0, 0)  # Fallback to origin
		town_name = "Debug Fallback Location"

	DebugLogger.info("TELEPORT SUMMARY:")
	DebugLogger.info("- Found %s towns total" % towns_found.size())
	DebugLogger.info("- Using town: '%s' at position: %s" % [town_name, town_world_pos])

	# Teleport to town center (positions are already treated as centered at tile origin)
	var new_pos = town_world_pos

	DebugLogger.info("Target town tile (top-left): %s" % town_world_pos)
	DebugLogger.info("Target player position (center): %s" % new_pos)

	global_position = new_pos
	current_target_position = new_pos  # Update target to match position
	is_moving = false  # Stop any current movement

	DebugLogger.info("Player teleported to position: %s" % global_position)
	DebugLogger.info("Target position set to: %s" % current_target_position)

	# Immediately center camera and update camera target
	if camera:
		camera.global_position = global_position
		if has_method("set_camera_target"):
			set_camera_target(global_position)

# Override level_up to use proper hit dice
func level_up():
	var old_level = level
	level += 1
	
	DebugLogger.info("LEVEL UP! %s is now level %s" % [character_name, level])
	
	# Roll for HP increase based on class hit die
	var hit_die_roll = 0
	if has_method("roll_class_hit_die"):
		hit_die_roll = call("roll_class_hit_die")
	else:
		# Fallback to a d8 roll
		hit_die_roll = randi() % 8 + 1
	var con_modifier = get_modifier(constitution)
	var hp_gain = hit_die_roll + con_modifier
	hp_gain = max(1, hp_gain)  # Minimum 1 HP per level
	
	max_health += hp_gain
	current_health += hp_gain  # Heal on level-up
	
	DebugLogger.info("Rolled %s on hit die + %s CON mod = %s HP gained!" % [hit_die_roll, con_modifier, hp_gain])
	DebugLogger.info("New max HP: %s" % max_health)
	
	# Recalculate all derived stats
	update_derived_stats()
	
	DebugLogger.info("Level %s -> %s complete!" % [old_level, level])

# Override the base character's gain_experience to add notifications
func gain_experience(xp_amount: int) -> bool:
	var leveled_up = super.gain_experience(xp_amount)
	
	# Show XP notification
	if has_method("show_xp_notification"):
		call("show_xp_notification", xp_amount)
	else:
		# If not present, log the XP gain
		DebugLogger.info("Gained %s XP" % xp_amount)
	
	# If we leveled up, show a level-up notification too
	if leveled_up:
		show_level_up_notification()
	
	return leveled_up

func show_level_up_notification():
	"""Show a prominent level-up notification"""
	var ui_layer = get_parent().get_node_or_null("UI")
	if not ui_layer:
		return
	
	# Create level-up notification
	var level_up_label = Label.new()
	level_up_label.text = "LEVEL UP!"
	level_up_label.add_theme_color_override("font_color", Color.GOLD)
	level_up_label.add_theme_font_size_override("font_size", 36)
	level_up_label.z_index = 101
	
	# Center it on screen
	var viewport_size = get_viewport().size
	level_up_label.position = viewport_size / 2 - Vector2(100, 0)
	
	ui_layer.add_child(level_up_label)
	
	# Animate the level-up notification
	var tween = create_tween()
	tween.tween_property(level_up_label, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(level_up_label, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_delay(1.0)
	tween.tween_property(level_up_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(level_up_label.queue_free)

# === ENHANCED RANDOM ENCOUNTER SYSTEM ===

func check_for_random_encounter(world_pos: Vector2, terrain_system):
	"""Check for random encounters based on terrain type and player level"""
	
	# Get terrain type at current position
	var terrain_type = get_terrain_type_at_position(world_pos, terrain_system)
	var encounter_chance = get_encounter_chance_for_terrain(terrain_type)
	
	# Scale encounter chance based on player level (higher level = slightly more encounters)
	var level_modifier = 1.0 + (level - 1) * 0.02  # +2% per level above 1
	encounter_chance *= level_modifier
	
	# Cap maximum encounter chance at 25%
	encounter_chance = min(encounter_chance, 0.25)
	
	DebugLogger.info("Encounter check: terrain=%s base_chance=%s final_chance=%s" % [str(terrain_type), str(get_encounter_chance_for_terrain(terrain_type)), str(encounter_chance)])
	
	if encounters_enabled and randf() < encounter_chance:
		DebugLogger.info("Random encounter triggered!")
		encounter_started.emit()

func get_terrain_type_at_position(world_pos: Vector2, terrain_system) -> int:
	"""Get the terrain type at a specific world position"""
	if not terrain_system:
		return 0  # Default to grass
	
	# Convert world position to tile coordinates
	var tile_pos = Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))
	
	# Try to get terrain type from the terrain system
	if terrain_system.has_method("get_terrain_type_at_tile"):
		return terrain_system.get_terrain_type_at_tile(tile_pos)
	elif terrain_system.has_method("get_terrain_at_position"):
		return terrain_system.get_terrain_at_position(world_pos)
	
	# Fallback: check global terrain_data if available (use get() for safe property access)
	var terrain_data = terrain_system.get("terrain_data")
	if terrain_data != null and terrain_data is Dictionary:
		if tile_pos in terrain_data:
			return terrain_data[tile_pos]
	
	# Default to grass
	return 0

func get_encounter_chance_for_terrain(terrain_type: int) -> float:
	"""Return encounter chance based on terrain type"""
	# These should match the TerrainType enum values
	match terrain_type:
		0: return 0.06   # GRASS - moderate encounters
		1: return 0.05   # DIRT - low encounters
		2: return 0.03   # STONE - very low encounters
		3: return 0.02   # WATER - very low encounters
		4: return 0.12   # TREE/FOREST - high encounters
		5: return 0.08   # MOUNTAIN - moderate-high encounters
		6: return 0.07   # VALLEY - moderate encounters
		7: return 0.04   # RIVER - low encounters
		8: return 0.03   # LAKE - low encounters
		9: return 0.01   # OCEAN - very low encounters
		10: return 0.15  # FOREST - highest encounters
		11: return 0.09  # HILLS - moderate-high encounters
		12: return 0.05  # BEACH - low encounters
		13: return 0.08  # SWAMP - moderate-high encounters
		14: return 0.01  # TOWN - very low encounters (civilized)
		_: return 0.06   # Default - moderate encounters

func get_encounter_difficulty_for_terrain(terrain_type: int) -> String:
	"""Return encounter difficulty modifier based on terrain"""
	match terrain_type:
		4, 10: return "forest"      # TREE/FOREST - wolves, bears, bandits
		5, 11: return "mountain"    # MOUNTAIN/HILLS - goblins, orcs, giants
		13: return "swamp"          # SWAMP - undead, reptiles
		3, 7, 8: return "water"     # WATER areas - aquatic creatures
		14: return "civilized"      # TOWN - bandits, guards
		_: return "wilderness"      # Default - standard wilderness encounters

func toggle_combat_log():
	"""Toggle the combat log visibility"""
	# Combat log UI removed; this is a harmless stub to keep older input bindings working.
	# It intentionally does nothing other than log to console for debugging.
	DebugLogger.info(str("toggle_combat_log called, but combat log UI has been removed. No action taken."))

func _exit_tree():
	# Clean up PlayerIconFactory if it exists
	if get_tree() and get_tree().get_root():
		var factory = get_tree().get_root().find_child("PlayerIconFactory", true, false)
		if factory and is_instance_valid(factory):
			if factory.get_parent():
				factory.get_parent().remove_child.call_deferred(factory)
			else:
				factory.queue_free()


