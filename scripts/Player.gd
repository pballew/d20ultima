class_name Player
extends Character

@export var movement_speed: float = 200.0
@export var encounters_enabled: bool = false  # Temporarily disable encounters (set true to re-enable)
@export var camera_smooth_speed: float = 6.0  # Higher = snappier, lower = slower
const TILE_SIZE = 32
var current_target_position: Vector2
var is_moving: bool = false
var is_in_combat: bool = false
var camera: Camera2D
var edge_threshold: int = 5  # Number of tiles from edge to start scrolling (was 8)
var frames_to_ignore_input: int = 0
var camera_target: Vector2
var initial_setup_complete: bool = false  # Flag to delay world bounds checking

signal movement_finished
signal encounter_started
signal camping_started

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
	global_position = char_data.world_position
	frames_to_ignore_input = 1
	print("Loaded character: ", character_name, " - Level ", level, " ", char_data.get_class_name())

func save_to_character_data() -> CharacterData:
	var char_data = CharacterData.new()
	char_data.character_name = character_name
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
	char_data.world_position = global_position
	char_data.save_timestamp = Time.get_datetime_string_from_system()
	
	return char_data

func create_player_sprite():
	# Create a pixel art player character
	var sprite = get_node("Sprite2D")
	var race_name = "Human"
	var player_class_name = "Fighter"
	
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
		current_target_position = new_position
		is_moving = true
		
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
	var terrain = get_parent().get_node_or_null("EnhancedTerrain")
	if not terrain:
		terrain = get_tree().get_root().find_child("EnhancedTerrain", true, false)
	if not terrain or not terrain.has_method("get_used_rect"):
		return

	# Get conservative bounds around current player position instead of full world
	var player_section = terrain.get_section_id_from_world_pos(player_pos) if terrain.has_method("get_section_id_from_world_pos") else Vector2i(0, 0)
	
	# Create bounds that include current section and immediate neighbors
	var conservative_bounds = Rect2i(
		Vector2i((player_section.x - 1) * 50 - 25, (player_section.y - 1) * 40 - 20),  # Position
		Vector2i(150, 120)  # Size: 3x3 sections
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
		
		# Check for map debug info (F11 key)
		if Input.is_key_pressed(KEY_F11):
			var terrain = get_parent().get_node("EnhancedTerrain")
			if terrain and terrain.has_method("print_map_debug_info"):
				terrain.print_map_debug_info()
				if terrain.has_method("test_coordinate_conversions"):
					terrain.test_coordinate_conversions()
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
		var new_position = global_position + (input_vector * TILE_SIZE)
		
		# Check if the new position is walkable
		var terrain = get_parent().get_node("EnhancedTerrain")
		if terrain and terrain.has_method("is_walkable"):
			# Ensure needed map sections are loaded around new position
			if terrain.has_method("ensure_sections_loaded_around_position"):
				terrain.ensure_sections_loaded_around_position(new_position)
			
			if terrain.is_walkable(new_position):
				move_to_tile(new_position)
				
				# Check for random encounters (10% chance)
				if encounters_enabled and randf() < 0.1:
					encounter_started.emit()
		else:
			# If no terrain, allow movement (fallback)
			move_to_tile(new_position)
			
			# Check for random encounters (10% chance)
			if encounters_enabled and randf() < 0.1:
				encounter_started.emit()

func enable_encounters():
	encounters_enabled = true
	print("Encounters enabled")

func disable_encounters():
	encounters_enabled = false
	print("Encounters disabled")

func enter_combat():
	is_in_combat = true
	print("Player entered combat - movement disabled")

func exit_combat():
	is_in_combat = false
	print("Player exited combat - movement enabled")

func start_camping():
	print("Hole up and Camp")
	
	# Restore player to full health
	if current_health < max_health:
		var health_to_restore = max_health - current_health
		heal(health_to_restore)
		print("Rested and recovered ", health_to_restore, " hit points")
	else:
		print("Already at full health, but enjoyed a good rest")
	
	# Emit camping signal for UI overlay
	camping_started.emit()

func generate_all_sprites():
	print("Generating all player sprite combinations...")
	
	# Load and create the factory
	var factory_script = load("res://scripts/PlayerIconFactory.gd")
	if factory_script:
		var factory = factory_script.new()
		if factory.has_method("export_all_player_sprites"):
			var count = factory.export_all_player_sprites()
			print("Generated ", count, " sprite files!")
		else:
			print("Factory missing export method")
	else:
		print("Could not load PlayerIconFactory script")
