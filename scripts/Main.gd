extends Node2D

const TILE_SIZE = 32  # Match this with EnhancedTerrain.TILE_SIZE

@onready var player = $Player
@onready var combat_manager = $CombatManager
@onready var combat_ui = $UI/CombatUI
@onready var player_stats_ui = $UI/PlayerStatsUI
@onready var terrain = $EnhancedTerrain
@onready var camera = $Camera2D

var starting_position: Vector2  # Store player's starting position for respawn
var debug_ui_scene = preload("res://scenes/MapDataDebugUI.tscn")

func _ready():
	# Add to group for easy finding
	add_to_group("main")
	
	# Connect signals
	player.encounter_started.connect(_on_encounter_started)
	player.camping_started.connect(_on_camping_started)
	combat_manager.combat_finished.connect(_on_combat_finished)

	# Wait for terrain to be fully generated before positioning camera
	await get_tree().process_frame
	
	# Ensure player starts on walkable terrain
	ensure_player_safe_starting_position()

	# Store the starting position for respawn
	starting_position = player.global_position

	# Now set camera position after terrain is ready
	camera.global_position = player.global_position
	
	# Add debug UI
	var debug_ui = debug_ui_scene.instantiate()
	add_child(debug_ui)
	
	# Set player camera target to prevent bounds constraints
	if player.has_method("set_camera_target"):
		player.set_camera_target(player.global_position)
	
	print("Camera positioned at: ", camera.global_position)
	print("Player position: ", player.global_position)

	# Setup combat UI
	combat_ui.setup_combat_ui(player, combat_manager)

	# Hide main menu if present
	if has_node("../MainMenu"):
		get_node("../MainMenu").hide()

	print("Game scene ready!")

func regenerate_map():
	# Ensure we have references to key nodes
	if !player or !terrain:
		print("Error: Missing player or terrain node!")
		return
		
	# Store player's current state
	var current_pos = player.global_position
	var current_health = player.current_health
	
	# Temporarily remove player from scene tree to prevent it being freed
	remove_child(player)
	
	# Reset terrain
	if terrain:
		# Clear existing terrain
		terrain.queue_free()
		await get_tree().process_frame  # Wait for terrain to be fully freed
		
		# Create new terrain
		var new_terrain = load("res://scripts/EnhancedTerrain.gd").new()
		new_terrain.name = "EnhancedTerrain"
		add_child(new_terrain)
		# Make sure new terrain is fully initialized
		await get_tree().create_timer(0.1).timeout  # Give it time to generate
		# Update terrain reference
		terrain = new_terrain
		# The EnhancedTerrain _ready() auto-generates terrain (generate_enhanced_terrain)
		# Add player back to scene and restore state (ensure added AFTER terrain for draw order)
		add_child(player)
		var safe_pos = find_nearest_safe_position(current_pos)
		if safe_pos == Vector2.ZERO and not terrain.is_walkable(current_pos):
			print("Warning: Safe position fallback to (0,0)")
		player.global_position = safe_pos
		player.current_health = current_health
		if camera:
			camera.global_position = player.global_position
		print("Map regenerated successfully! Player at: ", player.global_position)

func find_nearest_safe_position(pos: Vector2) -> Vector2:
	if not terrain or not terrain.has_method("is_walkable"):
		return pos  # No terrain system, use original position
	
	# Check if current position is already safe
	if terrain.is_walkable(pos):
		return pos
		
	# Search in expanding circles until we find a safe spot
	for radius in range(1, 10):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				if x*x + y*y <= radius*radius:  # Check in a circular pattern
					var check_pos = pos + Vector2(x * TILE_SIZE, y * TILE_SIZE)
					if terrain.is_walkable(check_pos):
						return check_pos
	
	# If no safe spot found, return center of map
	return Vector2.ZERO

func ensure_player_safe_starting_position():
	# Find a safe starting position for the player (walkable terrain)
	if not terrain or not terrain.has_method("is_walkable"):
		return  # No terrain system, use default position
	
	var current_pos = player.global_position
	player.global_position = find_nearest_safe_position(current_pos)
	print("Player starting at safe position: ", player.global_position)
	
	# Try a more systematic search for walkable terrain
	# First try a grid pattern around the world center
	var center_pos = Vector2(0, 0)
	var max_search_range = 20
	
	# Search in expanding squares from center
	for search_size in range(1, max_search_range + 1):
		# Check the perimeter of each square
		for x in range(-search_size, search_size + 1):
			for y in range(-search_size, search_size + 1):
				# Only check perimeter points to avoid redundant checks
				if abs(x) == search_size or abs(y) == search_size:
					var test_pos = center_pos + Vector2(x * TILE_SIZE, y * TILE_SIZE)
					if terrain.is_walkable(test_pos):
						player.global_position = test_pos
						print("Player moved to safe starting position: ", test_pos)
						return
	
	# If still no luck, try a denser pattern around current position
	for radius in range(1, 15):
		for angle in range(0, 360, 30):  # Check every 30 degrees
			var offset = Vector2(
				cos(deg_to_rad(angle)) * radius * TILE_SIZE,
				sin(deg_to_rad(angle)) * radius * TILE_SIZE
			)
			var test_pos = current_pos + offset
			
			if terrain.is_walkable(test_pos):
				player.global_position = test_pos
				print("Player moved to safe starting position: ", test_pos)
				return
	
	# Last resort: try specific known-good positions
	var fallback_positions = [
		Vector2(5 * TILE_SIZE, 5 * TILE_SIZE),
		Vector2(-5 * TILE_SIZE, 5 * TILE_SIZE),
		Vector2(5 * TILE_SIZE, -5 * TILE_SIZE),
		Vector2(-5 * TILE_SIZE, -5 * TILE_SIZE),
		Vector2(10 * TILE_SIZE, 0),
		Vector2(-10 * TILE_SIZE, 0),
		Vector2(0, 10 * TILE_SIZE),
		Vector2(0, -10 * TILE_SIZE)
	]
	
	for fallback_pos in fallback_positions:
		if terrain.is_walkable(fallback_pos):
			player.global_position = fallback_pos
			print("Player moved to fallback safe position: ", fallback_pos)
			return
	
	print("Warning: Could not find safe starting position for player!")

func _on_encounter_started():
	print("A wild creature appears!")
	
	var enemy = create_random_enemy()
	
	# Enter combat mode - disable player movement
	player.enter_combat()
	
	# Start combat
	combat_manager.start_combat(player, [enemy])
	combat_ui.show_combat([enemy])

func create_random_enemy() -> Character:
	# Create a random D20 monster with 1-2 hit dice
	var monster = Monster.new()
	var monster_data = create_random_monster_data()
	monster.setup_from_monster_data(monster_data)
	
	# Add monster to scene tree
	add_child(monster)
	monster.name = monster_data.monster_name
	
	# Create pixel art sprite for monster
	var sprite = Sprite2D.new()
	sprite.texture = create_monster_texture(monster_data.monster_name)
	sprite.position = Vector2(600, 300)  # Position on right side
	monster.add_child(sprite)
	
	monster.global_position = Vector2(600, 300)
	
	print(monster_data.monster_name, " (", monster_data.get_type_name(), ") appears!")
	if monster_data.special_attacks.size() > 0:
		print("Special Attacks: ", ", ".join(monster_data.special_attacks))
	return monster

func create_random_monster_data() -> MonsterData:
	var monsters = [
		create_goblin_data(),
		create_kobold_data(),
		create_skeleton_data(),
		create_zombie_data(),
		create_wolf_data(),
		create_giant_rat_data(),
		create_orc_data(),
		create_hobgoblin_data(),
		create_gnoll_data(),
		create_stirge_data()
	]
	
	return monsters[randi() % monsters.size()]

func create_goblin_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Goblin"
	data.monster_type = MonsterData.MonsterType.HUMANOID
	data.size = MonsterData.Size.SMALL
	data.hit_dice = "1d8+1"
	data.challenge_rating = 1
	
	# 3.5 Ability Scores
	data.strength = 11
	data.dexterity = 13
	data.constitution = 12
	data.intelligence = 10
	data.wisdom = 11
	data.charisma = 8
	
	# 3.5 Combat Stats
	data.base_attack_bonus = 1
	data.natural_armor = 1
	data.damage_dice = "1d4"
	data.num_attacks = 1
	
	# 3.5 Saving Throws
	data.fortitude_base = 0
	data.reflex_base = 2
	data.will_base = 0
	
	# Skills
	data.skills = {"Hide": 4, "Listen": 2, "Move Silently": 6, "Ride": 4, "Spot": 2}
	
	data.special_attacks = ["Sneak Attack"]
	data.special_qualities = ["Darkvision 60 ft."]
	
	data.description = "Goblins are small, evil, grotesque humanoids that live by raiding and scavenging."
	data.combat_behavior = "Goblins prefer to attack from ambush or in great numbers. They use hit-and-run tactics when possible."
	data.environment = "Temperate plains"
	
	return data

func create_kobold_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Kobold"
	data.monster_type = MonsterData.MonsterType.HUMANOID
	data.size = MonsterData.Size.SMALL
	data.hit_dice = "1d8"
	data.challenge_rating = 1
	
	# 3.5 Ability Scores
	data.strength = 9
	data.dexterity = 13
	data.constitution = 10
	data.intelligence = 10
	data.wisdom = 9
	data.charisma = 8
	
	# 3.5 Combat Stats
	data.base_attack_bonus = 1
	data.natural_armor = 1
	data.damage_dice = "1d4-1"
	data.num_attacks = 1
	
	# 3.5 Saving Throws
	data.fortitude_base = 0
	data.reflex_base = 2
	data.will_base = 0
	
	# Skills
	data.skills = {"Craft (trapmaking)": 2, "Hide": 4, "Listen": 2, "Move Silently": 2, "Profession (miner)": 2, "Search": 2, "Spot": 2}
	
	data.special_attacks = []
	data.special_qualities = ["Darkvision 60 ft.", "Light Sensitivity"]
	
	data.description = "Kobolds are short, reptilian humanoids with cowardly and sadistic tendencies."
	data.combat_behavior = "Kobolds like to attack with overwhelming odds. They use traps extensively."
	data.environment = "Temperate underground"
	
	return data

func create_skeleton_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Human Skeleton"
	data.monster_type = MonsterData.MonsterType.UNDEAD
	data.size = MonsterData.Size.MEDIUM
	data.hit_dice = "1d12"
	data.challenge_rating = 1
	
	# 3.5 Ability Scores
	data.strength = 13
	data.dexterity = 13
	data.constitution = 0  # Undead have no Con score
	data.intelligence = 0  # Mindless
	data.wisdom = 10
	data.charisma = 1
	
	# 3.5 Combat Stats
	data.base_attack_bonus = 0
	data.natural_armor = 2
	data.damage_dice = "1d6+1"
	data.num_attacks = 1
	
	# 3.5 Saving Throws
	data.fortitude_base = 0
	data.reflex_base = 2
	data.will_base = 2
	
	data.special_attacks = []
	data.special_qualities = ["Darkvision 60 ft.", "Undead Traits"]
	data.damage_immunities = ["cold"]
	data.damage_resistances = {"slashing": 1, "piercing": 1}
	
	data.description = "Skeletons are among the most common undead found in old dungeons and ruins."
	data.combat_behavior = "Skeletons attack until destroyed. They never check morale."
	data.environment = "Any"
	
	return data

func create_zombie_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Human Zombie"
	data.monster_type = MonsterData.MonsterType.UNDEAD
	data.size = MonsterData.Size.MEDIUM
	data.hit_dice = "2d12+3"
	data.challenge_rating = 1
	
	# 3.5 Ability Scores
	data.strength = 15
	data.dexterity = 8
	data.constitution = 0  # Undead have no Con score
	data.intelligence = 0  # Mindless
	data.wisdom = 10
	data.charisma = 1
	
	# 3.5 Combat Stats
	data.base_attack_bonus = 1
	data.natural_armor = 2
	data.damage_dice = "1d6+2"
	data.num_attacks = 1
	
	# 3.5 Saving Throws
	data.fortitude_base = 0
	data.reflex_base = 0
	data.will_base = 3
	
	data.special_attacks = []
	data.special_qualities = ["Darkvision 60 ft.", "Undead Traits"]
	data.damage_reduction = "5/slashing"
	
	data.description = "Zombies are corpses reanimated through dark and sinister magic."
	data.combat_behavior = "Zombies attack by trying to grab enemies and bash them with their fists."
	data.environment = "Any"
	
	return data

func create_wolf_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Wolf"
	data.monster_type = MonsterData.MonsterType.ANIMAL
	data.size = MonsterData.Size.MEDIUM
	data.hit_dice = "2d8+4"
	data.challenge_rating = 1
	
	# 3.5 Ability Scores
	data.strength = 13
	data.dexterity = 15
	data.constitution = 15
	data.intelligence = 2
	data.wisdom = 12
	data.charisma = 6
	
	# 3.5 Combat Stats
	data.base_attack_bonus = 1
	data.natural_armor = 2
	data.damage_dice = "1d6+1"
	data.num_attacks = 1
	
	# 3.5 Saving Throws
	data.fortitude_base = 3
	data.reflex_base = 3
	data.will_base = 1
	
	# Skills
	data.skills = {"Hide": 1, "Listen": 3, "Move Silently": 2, "Spot": 3, "Survival": 1}
	
	data.special_attacks = ["Trip"]
	data.special_qualities = ["Low-light Vision", "Scent"]
	
	data.description = "Wolves are pack hunters known for their persistence and cunning."
	data.combat_behavior = "A favorite tactic is to send one or two wolves against the enemy's front while the rest of the pack circles and attacks from the flanks or rear."
	data.environment = "Temperate forests"
	
	return data

func create_giant_rat_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Dire Rat"
	data.monster_type = MonsterData.MonsterType.ANIMAL
	data.size = MonsterData.Size.SMALL
	data.hit_dice = "1d8+1"
	data.challenge_rating = 1
	
	# 3.5 Ability Scores
	data.strength = 10
	data.dexterity = 17
	data.constitution = 13
	data.intelligence = 2
	data.wisdom = 12
	data.charisma = 4
	
	# 3.5 Combat Stats
	data.base_attack_bonus = 0
	data.natural_armor = 1
	data.damage_dice = "1d4"
	data.num_attacks = 1
	
	# 3.5 Saving Throws
	data.fortitude_base = 2
	data.reflex_base = 2
	data.will_base = 1
	
	# Skills
	data.skills = {"Climb": 8, "Hide": 8, "Listen": 3, "Move Silently": 4, "Spot": 3, "Swim": 8}
	
	data.special_attacks = ["Disease"]
	data.special_qualities = ["Low-light Vision", "Scent"]
	
	data.description = "Dire rats are omnivorous scavengers, but will attack to defend their nests and territories."
	data.combat_behavior = "Dire rats attack fearlessly, biting and chewing with their sharp incisors."
	data.environment = "Temperate underground"
	
	return data

func create_orc_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Orc"
	data.monster_type = MonsterData.MonsterType.HUMANOID
	data.size = MonsterData.Size.MEDIUM
	data.hit_dice = "1d8+1"
	data.challenge_rating = 1
	
	# 3.5 Ability Scores
	data.strength = 15
	data.dexterity = 11
	data.constitution = 12
	data.intelligence = 9
	data.wisdom = 11
	data.charisma = 9
	
	# 3.5 Combat Stats
	data.base_attack_bonus = 1
	data.natural_armor = 0
	data.damage_dice = "1d12+3"  # Greataxe + Str
	data.num_attacks = 1
	
	# 3.5 Saving Throws
	data.fortitude_base = 2
	data.reflex_base = 0
	data.will_base = 0
	
	# Skills
	data.skills = {"Listen": 2, "Spot": 2}
	
	data.special_attacks = []
	data.special_qualities = ["Darkvision 60 ft.", "Light Sensitivity"]
	
	data.description = "Orcs are aggressive humanoids that raid, pillage, and battle other creatures."
	data.combat_behavior = "Orcs prefer overwhelming odds or ambushes. They flee if things go badly."
	data.environment = "Temperate hills"
	
	return data

func create_hobgoblin_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Hobgoblin"
	data.monster_type = MonsterData.MonsterType.HUMANOID
	data.size = MonsterData.Size.MEDIUM
	data.hit_dice = "1d8+1"
	data.challenge_rating = 1
	
	# 3.5 Ability Scores
	data.strength = 13
	data.dexterity = 13
	data.constitution = 12
	data.intelligence = 10
	data.wisdom = 10
	data.charisma = 9
	
	# 3.5 Combat Stats
	data.base_attack_bonus = 1
	data.natural_armor = 0
	data.damage_dice = "1d8+1"  # Longsword + Str
	data.num_attacks = 1
	
	# 3.5 Saving Throws
	data.fortitude_base = 2
	data.reflex_base = 0
	data.will_base = 0
	
	# Skills
	data.skills = {"Hide": 3, "Listen": 2, "Move Silently": 3, "Spot": 2}
	
	data.special_attacks = []
	data.special_qualities = ["Darkvision 60 ft."]
	
	data.description = "Hobgoblins are militaristic cousins of goblins, larger and stronger."
	data.combat_behavior = "Hobgoblins are disciplined and work together effectively in battle."
	data.environment = "Temperate hills"
	
	return data

func create_gnoll_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Gnoll"
	data.monster_type = MonsterData.MonsterType.HUMANOID
	data.size = MonsterData.Size.MEDIUM
	data.hit_dice = "2d8+2"
	data.challenge_rating = 1
	
	# 3.5 Ability Scores
	data.strength = 15
	data.dexterity = 12
	data.constitution = 13
	data.intelligence = 8
	data.wisdom = 11
	data.charisma = 8
	
	# 3.5 Combat Stats
	data.base_attack_bonus = 1
	data.natural_armor = 1
	data.damage_dice = "1d8+3"  # Battleaxe + Str
	data.num_attacks = 1
	
	# 3.5 Saving Throws
	data.fortitude_base = 3
	data.reflex_base = 0
	data.will_base = 0
	
	# Skills
	data.skills = {"Listen": 2, "Spot": 3}
	
	data.special_attacks = []
	data.special_qualities = ["Darkvision 60 ft."]
	
	data.description = "Gnolls are feral humanoids that attack settlements along the frontiers and borderlands."
	data.combat_behavior = "Gnolls prefer to attack in overwhelming numbers, using stealth and ambush."
	data.environment = "Warm plains"
	
	return data

func create_stirge_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Stirge"
	data.monster_type = MonsterData.MonsterType.MAGICAL_BEAST
	data.size = MonsterData.Size.TINY
	data.hit_dice = "1d10"
	data.challenge_rating = 1
	
	# 3.5 Ability Scores
	data.strength = 3
	data.dexterity = 19
	data.constitution = 10
	data.intelligence = 1
	data.wisdom = 12
	data.charisma = 6
	
	# 3.5 Combat Stats
	data.base_attack_bonus = 1
	data.natural_armor = 0
	data.damage_dice = "1d3-4"  # Touch attack
	data.num_attacks = 1
	
	# 3.5 Saving Throws
	data.fortitude_base = 2
	data.reflex_base = 2
	data.will_base = 1
	
	# Skills
	data.skills = {"Hide": 14, "Listen": 3, "Spot": 3}
	
	data.special_attacks = ["Attach", "Blood Drain"]
	data.special_qualities = ["Low-light Vision"]
	
	data.description = "A stirge attacks by landing on a victim, finding a vulnerable spot, and plunging its proboscis into the flesh."
	data.combat_behavior = "Once attached, it drains blood until sated or the victim dies."
	data.environment = "Temperate marshes"
	
	return data

func create_monster_texture(monster_name: String) -> ImageTexture:
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	
	# Colors for different enemy types
	var primary_color: Color
	var secondary_color: Color
	var weapon_color = Color(0.5, 0.5, 0.5)
	
	match monster_name:
		"Goblin":
			primary_color = Color(0.4, 0.6, 0.2)  # Green skin
			secondary_color = Color(0.3, 0.2, 0.1)  # Brown clothing
		"Kobold":
			primary_color = Color(0.4, 0.3, 0.2)  # Brown scales
			secondary_color = Color(0.2, 0.4, 0.2)  # Dark green clothing
		"Orc":
			primary_color = Color(0.3, 0.5, 0.2)  # Dark green
			secondary_color = Color(0.2, 0.1, 0.1)  # Dark clothing
		"Hobgoblin":
			primary_color = Color(0.6, 0.4, 0.2)  # Reddish-brown skin
			secondary_color = Color(0.4, 0.4, 0.4)  # Gray armor
		"Gnoll":
			primary_color = Color(0.6, 0.5, 0.3)  # Tan fur
			secondary_color = Color(0.3, 0.2, 0.1)  # Dark spots
		"Skeleton":
			primary_color = Color(0.9, 0.9, 0.8)  # Bone white
			secondary_color = Color(0.7, 0.7, 0.6)  # Aged bone
		"Zombie":
			primary_color = Color(0.4, 0.5, 0.3)  # Rotting flesh
			secondary_color = Color(0.2, 0.3, 0.2)  # Decayed clothing
		"Wolf":
			primary_color = Color(0.4, 0.3, 0.2)  # Brown fur
			secondary_color = Color(0.3, 0.2, 0.1)  # Dark fur
		"Giant Rat":
			primary_color = Color(0.3, 0.3, 0.3)  # Gray fur
			secondary_color = Color(0.2, 0.2, 0.2)  # Dark gray
		"Stirge":
			primary_color = Color(0.4, 0.2, 0.2)  # Dark red
			secondary_color = Color(0.2, 0.1, 0.1)  # Darker red
		_:
			primary_color = Color(0.5, 0.5, 0.5)
			secondary_color = Color(0.3, 0.3, 0.3)
	
	# Fill background transparent
	for x in range(64):
		for y in range(64):
			image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var center_x = 32
	var center_y = 32
	
	if monster_name == "Wolf" or monster_name == "Giant Rat":
		# Draw quadruped creatures
		# Body (horizontal)
		for x in range(center_x - 6, center_x + 6):
			for y in range(center_y - 2, center_y + 2):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, primary_color)
		
		# Head
		for x in range(center_x + 4, center_x + 8):
			for y in range(center_y - 3, center_y + 1):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, primary_color)
		
		# Legs
		for x in range(center_x - 4, center_x - 2):
			for y in range(center_y + 2, center_y + 6):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, secondary_color)
		
		for x in range(center_x + 2, center_x + 4):
			for y in range(center_y + 2, center_y + 6):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, secondary_color)
		
		# Tail
		if monster_name == "Wolf":
			for x in range(center_x - 8, center_x - 6):
				for y in range(center_y - 1, center_y + 1):
					if x >= 0 and x < 64 and y >= 0 and y < 64:
						image.set_pixel(x, y, primary_color)
		
		# Long tail for rat
		if monster_name == "Giant Rat":
			for x in range(center_x - 10, center_x - 6):
				for y in range(center_y, center_y + 1):
					if x >= 0 and x < 64 and y >= 0 and y < 64:
						image.set_pixel(x, y, secondary_color)
	
	elif monster_name == "Stirge":
		# Draw flying creature
		# Small body
		for x in range(center_x - 2, center_x + 2):
			for y in range(center_y - 1, center_y + 2):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, primary_color)
		
		# Wings
		for x in range(center_x - 5, center_x - 2):
			for y in range(center_y - 3, center_y + 1):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, secondary_color)
		
		for x in range(center_x + 2, center_x + 5):
			for y in range(center_y - 3, center_y + 1):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, secondary_color)
		
		# Proboscis
		for x in range(center_x + 2, center_x + 4):
			for y in range(center_y, center_y + 1):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, primary_color)
	else:
		# Draw humanoid enemies
		# Head
		for x in range(center_x - 3, center_x + 3):
			for y in range(center_y - 8, center_y - 3):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, primary_color)
		
		# Body
		for x in range(center_x - 3, center_x + 3):
			for y in range(center_y - 3, center_y + 5):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, secondary_color)
		
		# Arms
		for x in range(center_x - 5, center_x - 2):
			for y in range(center_y - 2, center_y + 3):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, primary_color)
		
		for x in range(center_x + 2, center_x + 5):
			for y in range(center_y - 2, center_y + 3):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, primary_color)
		
		# Weapon in right hand
		for x in range(center_x + 5, center_x + 7):
			for y in range(center_y - 4, center_y + 2):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, weapon_color)
		
		# Legs
		for x in range(center_x - 2, center_x):
			for y in range(center_y + 5, center_y + 10):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, secondary_color)
		
		for x in range(center_x, center_x + 2):
			for y in range(center_y + 5, center_y + 10):
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					image.set_pixel(x, y, secondary_color)
		
		# Special features for specific monsters
		if monster_name == "Skeleton":
			# Add rib cage lines
			for y in range(center_y - 1, center_y + 3):
				if y >= 0 and y < 32:
					image.set_pixel(center_x - 2, y, Color(0.5, 0.5, 0.5))
					image.set_pixel(center_x + 1, y, Color(0.5, 0.5, 0.5))
		
		elif monster_name == "Zombie":
			# Add decay spots
			for i in range(3):
				var spot_x = center_x + randi_range(-2, 2)
				var spot_y = center_y + randi_range(-2, 3)
				if spot_x >= 0 and spot_x < 32 and spot_y >= 0 and spot_y < 32:
					image.set_pixel(spot_x, spot_y, Color(0.2, 0.3, 0.1))
		
		elif monster_name == "Kobold":
			# Add scale pattern
			for x in range(center_x - 2, center_x + 2):
				for y in range(center_y - 6, center_y - 4):
					if (x + y) % 2 == 0 and x >= 0 and x < 64 and y >= 0 and y < 64:
						image.set_pixel(x, y, secondary_color)
		
		elif monster_name == "Gnoll":
			# Add hyena spots
			for i in range(4):
				var spot_x = center_x + randi_range(-2, 2)
				var spot_y = center_y + randi_range(-6, -2)
				if spot_x >= 0 and spot_x < 32 and spot_y >= 0 and spot_y < 32:
					image.set_pixel(spot_x, spot_y, secondary_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _on_combat_finished(player_won: bool):
	# Exit combat mode - re-enable player movement
	player.exit_combat()
	
	# Handle player defeat - respawn with full health
	if not player_won:
		respawn_player()
	
	# Clean up enemy nodes after combat
	var enemies = get_children().filter(func(child): return child is Character and child != player)
	for enemy in enemies:
		enemy.queue_free()

func _on_camping_started():
	print("Setting up campsite...")
	show_camping_overlay()

func respawn_player():
	print("Player defeated! Respawning at starting location...")
	
	# Reset player health to full using heal method
	var health_to_restore = player.max_health - player.current_health
	if health_to_restore > 0:
		player.heal(health_to_restore)
	
	# Move player back to starting position
	player.global_position = starting_position
	player.current_target_position = starting_position
	player.is_moving = false
	
	# Reset camera to starting position
	camera.global_position = starting_position
	
	# Show respawn message to player
	if combat_ui:
		combat_ui.add_combat_log("=== RESPAWN ===")
		combat_ui.add_combat_log("You have been defeated!")
		combat_ui.add_combat_log("Respawning at starting location with full health.")
		combat_ui.add_combat_log("===============")
	
	print("Player respawned with full health at: ", starting_position)

func show_camping_overlay():
	# Create camping overlay
	var camping_overlay = ColorRect.new()
	camping_overlay.name = "CampingOverlay"
	camping_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	camping_overlay.color = Color(0, 0, 0, 0.8)  # Semi-transparent background
	
	# Create the campsite illustration
	var campsite_container = Control.new()
	campsite_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	campsite_container.size = Vector2(600, 400)
	campsite_container.position = Vector2(-300, -200)  # Center it
	camping_overlay.add_child(campsite_container)
	
	# Create campsite texture
	var campsite_sprite = TextureRect.new()
	campsite_sprite.texture = create_campsite_texture()
	campsite_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	campsite_container.add_child(campsite_sprite)
	
	# Add camping text
	var camp_label = Label.new()
	camp_label.text = "Resting at Camp\n\nYou set up a cozy campsite and rest by the fire.\nYour hit points have been fully restored!\n\nPress any key to continue..."
	camp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	camp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	camp_label.add_theme_font_size_override("font_size", 18)
	camp_label.modulate = Color.WHITE
	camp_label.position = Vector2(150, 320)
	camp_label.size = Vector2(300, 120)
	campsite_container.add_child(camp_label)
	
	# Add to scene
	add_child(camping_overlay)
	
	# Store reference for cleanup and start input monitoring
	camping_overlay.set_meta("is_camping_overlay", true)
	_start_camping_input_monitor()

var camping_overlay_active = false

func _start_camping_input_monitor():
	camping_overlay_active = true

func _input(event):
	# Handle camping overlay input
	if camping_overlay_active and event is InputEventKey and event.pressed:
		_close_camping_overlay()
		return
		
	# Handle map regeneration with PageDown key
	if event.is_action_pressed("ui_page_down"):
		regenerate_map()

func _close_camping_overlay():
	camping_overlay_active = false
	
	# Find and remove camping overlay
	var camping_overlays = get_children().filter(func(child): return child.has_meta("is_camping_overlay"))
	for overlay in camping_overlays:
		overlay.queue_free()
	
	print("Camping overlay closed")

func create_campsite_texture() -> ImageTexture:
	# Create a 600x400 campsite scene
	var image = Image.create(600, 400, false, Image.FORMAT_RGB8)
	image.fill(Color(0.1, 0.2, 0.3))  # Night sky background
	
	# Ground
	for x in range(0, 600):
		for y in range(300, 400):
			var grass_color = Color(0.2, 0.4, 0.1) + Color(randf() * 0.1, randf() * 0.1, randf() * 0.05)
			image.set_pixel(x, y, grass_color)
	
	# Draw tent (triangular shape)
	draw_tent(image, Vector2i(450, 250), Color(0.6, 0.4, 0.2))
	
	# Draw campfire
	draw_campfire(image, Vector2i(300, 280))
	
	# Draw adventurer (player character)
	draw_adventurer(image, Vector2i(250, 260))
	
	# Add some trees in background
	draw_tree(image, Vector2i(100, 200))
	draw_tree(image, Vector2i(500, 180))
	
	# Add stars
	for i in range(50):
		var star_x = randi_range(0, 599)
		var star_y = randi_range(0, 150)
		image.set_pixel(star_x, star_y, Color.WHITE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func draw_tent(image: Image, pos: Vector2i, tent_color: Color):
	# Draw tent triangle
	var tent_width = 80
	var tent_height = 60
	
	for y in range(tent_height):
		var line_width = int((float(tent_height - y) / tent_height) * tent_width)
		var start_x = pos.x - line_width / 2
		var end_x = pos.x + line_width / 2
		
		for x in range(start_x, end_x):
			if x >= 0 and x < 600 and (pos.y + y) >= 0 and (pos.y + y) < 400:
				image.set_pixel(x, pos.y + y, tent_color)

func draw_campfire(image: Image, pos: Vector2i):
	# Draw fire pit (dark circle)
	var pit_radius = 25
	for x in range(pos.x - pit_radius, pos.x + pit_radius):
		for y in range(pos.y - pit_radius, pos.y + pit_radius):
			var dist = Vector2(x - pos.x, y - pos.y).length()
			if dist <= pit_radius and x >= 0 and x < 600 and y >= 0 and y < 400:
				image.set_pixel(x, y, Color(0.2, 0.1, 0.05))
	
	# Draw flames
	var flame_colors = [Color.RED, Color.ORANGE, Color.YELLOW]
	for i in range(15):
		var flame_x = pos.x + randi_range(-15, 15)
		var flame_y = pos.y + randi_range(-30, -5)
		var flame_color = flame_colors[randi() % flame_colors.size()]
		
		# Draw flame pixel cluster
		for fx in range(flame_x - 2, flame_x + 3):
			for fy in range(flame_y - 3, flame_y + 2):
				if fx >= 0 and fx < 600 and fy >= 0 and fy < 400:
					image.set_pixel(fx, fy, flame_color)
	
	# Draw cooking spit with meat
	var spit_y = pos.y - 20
	for x in range(pos.x - 20, pos.x + 20):
		if x >= 0 and x < 600 and spit_y >= 0 and spit_y < 400:
			image.set_pixel(x, spit_y, Color(0.4, 0.2, 0.1))  # Brown stick
	
	# Draw meat
	var meat_color = Color(0.6, 0.3, 0.2)
	for x in range(pos.x - 8, pos.x + 8):
		for y in range(spit_y - 5, spit_y + 5):
			if x >= 0 and x < 600 and y >= 0 and y < 400:
				image.set_pixel(x, y, meat_color)

func draw_adventurer(image: Image, pos: Vector2i):
	# Draw simple adventurer figure
	var head_color = Color(0.9, 0.7, 0.5)  # Skin tone
	var body_color = Color(0.4, 0.2, 0.6)  # Purple tunic
	var leg_color = Color(0.3, 0.2, 0.1)   # Brown pants
	
	# Head
	for x in range(pos.x - 4, pos.x + 4):
		for y in range(pos.y - 8, pos.y - 2):
			if x >= 0 and x < 600 and y >= 0 and y < 400:
				image.set_pixel(x, y, head_color)
	
	# Body
	for x in range(pos.x - 6, pos.x + 6):
		for y in range(pos.y - 2, pos.y + 8):
			if x >= 0 and x < 600 and y >= 0 and y < 400:
				image.set_pixel(x, y, body_color)
	
	# Legs
	for x in range(pos.x - 3, pos.x + 3):
		for y in range(pos.y + 8, pos.y + 16):
			if x >= 0 and x < 600 and y >= 0 and y < 400:
				image.set_pixel(x, y, leg_color)

func draw_tree(image: Image, pos: Vector2i):
	# Tree trunk
	var trunk_color = Color(0.4, 0.2, 0.1)
	for x in range(pos.x - 3, pos.x + 3):
		for y in range(pos.y + 30, pos.y + 60):
			if x >= 0 and x < 600 and y >= 0 and y < 400:
				image.set_pixel(x, y, trunk_color)
	
	# Tree foliage
	var leaf_color = Color(0.2, 0.6, 0.2)
	var foliage_radius = 20
	for x in range(pos.x - foliage_radius, pos.x + foliage_radius):
		for y in range(pos.y, pos.y + foliage_radius):
			var dist = Vector2(x - pos.x, y - pos.y).length()
			if dist <= foliage_radius and x >= 0 and x < 600 and y >= 0 and y < 400:
				image.set_pixel(x, y, leaf_color)
