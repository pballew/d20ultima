extends Node2D

const TILE_SIZE = 32  # Match this with EnhancedTerrain.TILE_SIZE

@onready var player = $Player
@onready var combat_manager = $CombatManager
@onready var combat_ui = $UI/CombatUI
@onready var player_stats_ui = $UI/PlayerStatsUI
@onready var coordinate_overlay = $UI/CoordinateOverlay
@onready var terrain = $EnhancedTerrainTileMap
@onready var camera = $Camera2D

var starting_position: Vector2  # Store player's starting position for respawn
var debug_ui_scene = preload("res://scenes/MapDataDebugUI.tscn")
var town_name_label: Label  # Town name display label
var town_name_timer: Timer  # Timer to hide town name after a few seconds

func _ready():
	# Add to group for easy finding
	add_to_group("main")
	
	# Connect signals
	player.encounter_started.connect(_on_encounter_started)
	player.camping_started.connect(_on_camping_started)
	player.movement_finished.connect(_on_player_moved)
	player.town_name_display.connect(_on_town_name_display)
	combat_manager.combat_finished.connect(_on_combat_finished)

	# Wait for terrain to be fully generated before positioning camera
	await get_tree().process_frame
	
	# Ensure player starts on walkable terrain
	ensure_player_safe_starting_position()

	# Store the starting position for respawn
	starting_position = player.global_position

	# Now set camera position after terrain is ready and starting position determined
	camera.global_position = player.global_position
	
	# Add debug UI (hidden for cleaner gameplay)
	# var debug_ui = debug_ui_scene.instantiate()
	# add_child(debug_ui)
	
	# Set player camera target to prevent bounds constraints
	if player.has_method("set_camera_target"):
		player.set_camera_target(player.global_position)
	
	print("Camera positioned at: ", camera.global_position)
	print("Player position: ", player.global_position)

	# Initialize coordinate overlay
	if coordinate_overlay:
		var initial_pos = Vector2(int(player.global_position.x / TILE_SIZE), int(player.global_position.y / TILE_SIZE))
		coordinate_overlay.update_coordinates(initial_pos)

	# Create town name display label
	create_town_name_display()

	# Setup combat UI
	combat_ui.setup_combat_ui(player, combat_manager)

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
		# Preserve original node name so other scripts still find it (they look for "EnhancedTerrainTileMap")
		if terrain and terrain.name != "":
			new_terrain.name = terrain.name
		else:
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
		# Ensure camera target is synced to avoid smoothing lag
		if player and player.has_method("set_camera_target"):
			player.set_camera_target(player.global_position)

func find_nearest_safe_position(pos: Vector2) -> Vector2:
	if not terrain or not terrain.has_method("is_walkable"):
		return pos  # Already using tile-centered coordinates
	
	# Check if current position is already safe
	if terrain.is_walkable(pos):
		return pos  # Already centered
		
	# Search in expanding circles until we find a safe spot
	for radius in range(1, 10):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				if x*x + y*y <= radius*radius:  # Check in a circular pattern
					var check_pos = pos + Vector2(x * TILE_SIZE, y * TILE_SIZE)
					if terrain.is_walkable(check_pos):
						return check_pos  # Already centered
	
	# If no safe spot found, return center of map (centered on tile)
	return Vector2.ZERO

func ensure_player_safe_starting_position():
	# Find a safe starting position for the player (walkable terrain)
	if not terrain or not terrain.has_method("is_walkable"):
		return  # No terrain system, use default position
	
	var current_pos = player.global_position
	# If the current (saved) position is already walkable, keep it
	if terrain.is_walkable(current_pos):
		print("Player position is walkable; keeping saved position: ", current_pos)
		return
    
	# Otherwise, try to find a near safe tile around the current position first
	var near_safe = find_nearest_safe_position(current_pos)
	if near_safe != Vector2.ZERO:
		player.global_position = near_safe
		print("Player adjusted to nearest safe position: ", player.global_position)
		return
    
	# If none found nearby, continue with broader searches below
	print("Searching broader area for safe starting position...")
	
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
						player.global_position = test_pos  # Already centered
						print("Player moved to safe starting position: ", player.global_position)
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
				player.global_position = test_pos + Vector2(TILE_SIZE/2, TILE_SIZE/2)  # Center on tile
				print("Player moved to safe starting position: ", player.global_position)
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
			player.global_position = fallback_pos  # Already centered
			print("Player moved to fallback safe position: ", player.global_position)
			return
	
	print("Warning: Could not find safe starting position for player!")

func _on_encounter_started():
	print("A wild creature appears!")
	
	# Get terrain-based encounter difficulty
	var terrain_type = get_current_terrain_type()
	var difficulty_modifier = player.get_encounter_difficulty_for_terrain(terrain_type)
	
	var enemy = create_random_enemy(difficulty_modifier)
	
	# Enter combat mode - disable player movement
	player.enter_combat()
	
	# Start combat
	combat_manager.start_combat(player, [enemy])
	combat_ui.show_combat([enemy])
	
	# Connect to combat end to award XP
	if not combat_manager.combat_finished.is_connected(_on_combat_finished):
		combat_manager.combat_finished.connect(_on_combat_finished)

func get_current_terrain_type() -> int:
	"""Get the terrain type at player's current position"""
	var terrain = get_node("EnhancedTerrainTileMap")
	if not terrain:
		terrain = get_node("EnhancedTerrain")
	
	if terrain and player:
		return player.get_terrain_type_at_position(player.global_position, terrain)
	
	return 0  # Default to grass

func create_random_enemy(difficulty_modifier: String = "wilderness") -> Character:
	# Create a random D20 monster based on terrain and player level
	var monster = Monster.new()
	var monster_data = create_random_monster_data(difficulty_modifier)
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

func create_random_monster_data(difficulty_modifier: String = "wilderness") -> MonsterData:
	var monsters = []
	
	# Base encounters available everywhere
	var base_monsters = [
		create_goblin_data(),
		create_kobold_data(),
		create_giant_rat_data()
	]
	
	# Terrain-specific encounters
	match difficulty_modifier:
		"forest":
			monsters = [
				create_wolf_data(),
				create_wolf_data(),  # Wolves more common in forests
				create_dire_wolf_data(),
				create_bear_data(),
				create_goblin_data(),
				create_orc_data()
			]
		"mountain":
			monsters = [
				create_goblin_data(),
				create_hobgoblin_data(),
				create_orc_data(),
				create_ogre_data(),
				create_giant_rat_data()
			]
		"swamp":
			monsters = [
				create_skeleton_data(),
				create_zombie_data(),
				create_giant_rat_data(),
				create_stirge_data(),
				create_lizardfolk_data()
			]
		"water":
			monsters = [
				create_giant_rat_data(),  # Rats near water
				create_stirge_data(),
				create_lizardfolk_data()
			]
		"civilized":
			monsters = [
				create_bandit_data(),
				create_giant_rat_data(),
				create_kobold_data()
			]
		_: # "wilderness" or default
			monsters = [
				create_goblin_data(),
				create_kobold_data(),
				create_wolf_data(),
				create_giant_rat_data(),
				create_orc_data(),
				create_gnoll_data(),
				create_stirge_data()
			]
	
	# Add some base monsters to all encounter tables (10% chance each)
	if randf() < 0.3:
		monsters.append(base_monsters[randi() % base_monsters.size()])
	
	# Scale monster difficulty based on player level
	var selected_monster = monsters[randi() % monsters.size()]
	scale_monster_to_player_level(selected_monster)
	
	return selected_monster

func scale_monster_to_player_level(monster_data: MonsterData):
	"""Scale monster stats based on player level"""
	if player and player.level > 1:
		var level_bonus = player.level - 1
		
		# Increase challenge rating
		monster_data.challenge_rating += level_bonus / 2
		
		# Boost monster stats slightly
		var stat_bonus = level_bonus
		monster_data.strength += stat_bonus
		monster_data.constitution += stat_bonus
		
		# Increase HP
		var hp_bonus = level_bonus * 3
		var current_hp = monster_data.calculate_hit_points()
		# We can't directly modify calculated HP, but we can boost constitution
		monster_data.constitution += hp_bonus / 4  # Approximate HP boost via CON
		
		print("Scaled ", monster_data.monster_name, " to player level ", player.level)

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

# === NEW TERRAIN-SPECIFIC MONSTERS ===

func create_dire_wolf_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Dire Wolf"
	data.monster_type = MonsterData.MonsterType.ANIMAL
	data.size = MonsterData.Size.LARGE
	data.hit_dice = "6d8+18"
	data.challenge_rating = 3
	
	data.strength = 25
	data.dexterity = 15
	data.constitution = 17
	data.intelligence = 2
	data.wisdom = 12
	data.charisma = 10
	
	data.base_attack_bonus = 4
	data.natural_armor = 2
	data.damage_dice = "1d8+7"
	data.num_attacks = 1
	
	data.fortitude_base = 5
	data.reflex_base = 5
	data.will_base = 2
	
	data.skills = {"Hide": 2, "Listen": 7, "Move Silently": 4, "Spot": 7, "Survival": 7}
	data.special_attacks = ["Trip"]
	data.special_qualities = ["Scent", "Low-light Vision"]
	
	data.description = "Dire wolves are efficient pack hunters that kill anything they can catch."
	data.combat_behavior = "Dire wolves prefer to attack in packs, surrounding and attacking a single opponent."
	data.environment = "Temperate forests"
	
	return data

func create_bear_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Black Bear"
	data.monster_type = MonsterData.MonsterType.ANIMAL
	data.size = MonsterData.Size.MEDIUM
	data.hit_dice = "3d8+6"
	data.challenge_rating = 2
	
	data.strength = 19
	data.dexterity = 13
	data.constitution = 15
	data.intelligence = 2
	data.wisdom = 12
	data.charisma = 6
	
	data.base_attack_bonus = 2
	data.natural_armor = 2
	data.damage_dice = "1d4+4"
	data.num_attacks = 3  # 2 claws + 1 bite
	
	data.fortitude_base = 5
	data.reflex_base = 4
	data.will_base = 1
	
	data.skills = {"Listen": 4, "Spot": 4, "Swim": 8}
	data.special_attacks = []
	data.special_qualities = ["Scent", "Low-light Vision"]
	
	data.description = "Bears are omnivores with an exceptional sense of smell."
	data.combat_behavior = "Bears attack with claws and bite when threatened or protecting cubs."
	data.environment = "Temperate forests"
	
	return data

func create_ogre_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Ogre"
	data.monster_type = MonsterData.MonsterType.HUMANOID
	data.size = MonsterData.Size.LARGE
	data.hit_dice = "4d8+8"
	data.challenge_rating = 3
	
	data.strength = 21
	data.dexterity = 8
	data.constitution = 15
	data.intelligence = 6
	data.wisdom = 10
	data.charisma = 7
	
	data.base_attack_bonus = 3
	data.natural_armor = 5
	data.damage_dice = "2d6+7"
	data.num_attacks = 1
	
	data.fortitude_base = 4
	data.reflex_base = 1
	data.will_base = 1
	
	data.skills = {"Climb": 4, "Listen": 2, "Spot": 2}
	data.special_attacks = []
	data.special_qualities = ["Darkvision 60 ft.", "Low-light Vision"]
	
	data.description = "Ogres are big, ugly humanoids that stand over nine feet tall."
	data.combat_behavior = "Ogres fight with massive clubs, overwhelming opponents with brute strength."
	data.environment = "Temperate hills and mountains"
	
	return data

func create_lizardfolk_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Lizardfolk"
	data.monster_type = MonsterData.MonsterType.HUMANOID
	data.size = MonsterData.Size.MEDIUM
	data.hit_dice = "2d8+2"
	data.challenge_rating = 1
	
	data.strength = 13
	data.dexterity = 10
	data.constitution = 13
	data.intelligence = 9
	data.wisdom = 12
	data.charisma = 10
	
	data.base_attack_bonus = 1
	data.natural_armor = 5
	data.damage_dice = "1d6+1"
	data.num_attacks = 1
	
	data.fortitude_base = 3
	data.reflex_base = 0
	data.will_base = 3
	
	data.skills = {"Balance": 4, "Jump": 4, "Swim": 8}
	data.special_attacks = []
	data.special_qualities = ["Hold Breath"]
	
	data.description = "Lizardfolk are primitive reptilian humanoids that lurk in swamps and marshes."
	data.combat_behavior = "Lizardfolk fight with simple weapons, preferring ambush tactics."
	data.environment = "Temperate marshes"
	
	return data

func create_bandit_data() -> MonsterData:
	var data = MonsterData.new()
	data.monster_name = "Bandit"
	data.monster_type = MonsterData.MonsterType.HUMANOID
	data.size = MonsterData.Size.MEDIUM
	data.hit_dice = "1d8+1"
	data.challenge_rating = 1
	
	data.strength = 11
	data.dexterity = 12
	data.constitution = 12
	data.intelligence = 10
	data.wisdom = 11
	data.charisma = 10
	
	data.base_attack_bonus = 1
	data.natural_armor = 2  # Leather armor
	data.damage_dice = "1d6"
	data.num_attacks = 1
	
	data.fortitude_base = 0
	data.reflex_base = 2
	data.will_base = 0
	
	data.skills = {"Hide": 3, "Listen": 3, "Move Silently": 3, "Spot": 3}
	data.special_attacks = []
	data.special_qualities = []
	
	data.description = "Bandits are outlaws who prey on travelers and merchants."
	data.combat_behavior = "Bandits prefer ambush tactics and will flee if outmatched."
	data.environment = "Any land"
	
	return data

func create_monster_texture(monster_name: String) -> ImageTexture:
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	
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
		"Dire Wolf":
			primary_color = Color(0.2, 0.2, 0.2)  # Dark fur
			secondary_color = Color(0.1, 0.1, 0.1)  # Black fur
		"Black Bear":
			primary_color = Color(0.2, 0.1, 0.1)  # Black fur
			secondary_color = Color(0.3, 0.2, 0.1)  # Brown patches
		"Ogre":
			primary_color = Color(0.5, 0.4, 0.3)  # Rough skin
			secondary_color = Color(0.3, 0.2, 0.1)  # Crude clothing
		"Lizardfolk":
			primary_color = Color(0.3, 0.5, 0.3)  # Green scales
			secondary_color = Color(0.2, 0.4, 0.2)  # Darker green
		"Bandit":
			primary_color = Color(0.7, 0.6, 0.5)  # Human skin
			secondary_color = Color(0.4, 0.3, 0.2)  # Leather armor
		_:
			primary_color = Color(0.5, 0.5, 0.5)
			secondary_color = Color(0.3, 0.3, 0.3)
	
	# Fill background transparent
	for x in range(32):
		for y in range(32):
			image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var center_x = 16
	var center_y = 16
	
	if monster_name == "Wolf" or monster_name == "Giant Rat" or monster_name == "Dire Wolf" or monster_name == "Black Bear":
		# Draw quadruped creatures
		# Body (horizontal oval) - larger for dire wolf and bear
		var body_width = 14 if (monster_name == "Dire Wolf" or monster_name == "Black Bear") else 14
		var body_height = 4 if (monster_name == "Dire Wolf" or monster_name == "Black Bear") else 6
		
		for x in range(center_x - 8, center_x + 6):
			for y in range(center_y - 3, center_y + 3):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, primary_color)
		
		# Head - vary by creature type
		if monster_name == "Giant Rat":
			# Rat head with long snout
			for x in range(center_x + 4, center_x + 12):
				for y in range(center_y - 3, center_y + 1):
					if x >= 0 and x < 32 and y >= 0 and y < 32:
						image.set_pixel(x, y, primary_color)
		else:
			# Standard quadruped head
			for x in range(center_x + 4, center_x + 10):
				for y in range(center_y - 4, center_y + 2):
					if x >= 0 and x < 32 and y >= 0 and y < 32:
						image.set_pixel(x, y, primary_color)
		
		# Legs - shorter for rat, normal for others
		var leg_length = 3 if monster_name == "Giant Rat" else 5
		
		# Front legs
		for x in range(center_x + 2, center_x + 4):
			for y in range(center_y + 3, center_y + 3 + leg_length):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, secondary_color)
		
		# Back legs
		for x in range(center_x - 2, center_x):
			for y in range(center_y + 3, center_y + 3 + leg_length):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, secondary_color)
		
		# Ears - vary by creature
		if monster_name == "Giant Rat":
			# Small round rat ears
			for x in range(center_x + 7, center_x + 9):
				for y in range(center_y - 5, center_y - 3):
					if x >= 0 and x < 32 and y >= 0 and y < 32:
						image.set_pixel(x, y, secondary_color)
		elif monster_name == "Dire Wolf" or monster_name == "Wolf":
			# Pointed wolf ears
			for x in range(center_x + 6, center_x + 8):
				for y in range(center_y - 6, center_y - 4):
					if x >= 0 and x < 32 and y >= 0 and y < 32:
						image.set_pixel(x, y, secondary_color)
		else:
			# Bear ears (small and round)
			for x in range(center_x + 6, center_x + 8):
				for y in range(center_y - 5, center_y - 4):
					if x >= 0 and x < 32 and y >= 0 and y < 32:
						image.set_pixel(x, y, secondary_color)
		
		# Tail - vary by creature type
		if monster_name == "Wolf" or monster_name == "Dire Wolf":
			# Wolf tail (bushy)
			for x in range(center_x - 12, center_x - 8):
				for y in range(center_y - 2, center_y + 1):
					if x >= 0 and x < 32 and y >= 0 and y < 32:
						image.set_pixel(x, y, primary_color)
		elif monster_name == "Giant Rat":
			# Long thin rat tail
			for x in range(center_x - 14, center_x - 8):
				for y in range(center_y + 1, center_y + 2):
					if x >= 0 and x < 32 and y >= 0 and y < 32:
						image.set_pixel(x, y, secondary_color)
		elif monster_name == "Black Bear":
			# Short bear tail
			for x in range(center_x - 10, center_x - 8):
				for y in range(center_y - 1, center_y + 1):
					if x >= 0 and x < 32 and y >= 0 and y < 32:
						image.set_pixel(x, y, secondary_color)
	
	elif monster_name == "Stirge":
		# Draw flying creature
		# Body (larger oval)
		for x in range(center_x - 3, center_x + 3):
			for y in range(center_y - 2, center_y + 3):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, primary_color)
		
		# Large wings
		for x in range(center_x - 8, center_x - 3):
			for y in range(center_y - 4, center_y + 1):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, secondary_color)
		
		for x in range(center_x + 3, center_x + 8):
			for y in range(center_y - 4, center_y + 1):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, secondary_color)
		
		# Proboscis (longer)
		for x in range(center_x + 3, center_x + 6):
			for y in range(center_y, center_y + 1):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, primary_color)
		
		# Small legs
		for x in range(center_x - 1, center_x + 1):
			for y in range(center_y + 3, center_y + 5):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, secondary_color)
	else:
		# Draw humanoid enemies
		# Head (larger)
		for x in range(center_x - 4, center_x + 4):
			for y in range(center_y - 10, center_y - 4):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, primary_color)
		
		# Body (wider and taller)
		for x in range(center_x - 4, center_x + 4):
			for y in range(center_y - 4, center_y + 6):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, secondary_color)
		
		# Arms (longer)
		for x in range(center_x - 7, center_x - 3):
			for y in range(center_y - 2, center_y + 4):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, primary_color)
		
		for x in range(center_x + 3, center_x + 7):
			for y in range(center_y - 2, center_y + 4):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, primary_color)
		
		# Weapon in right hand (longer sword/club)
		for x in range(center_x + 7, center_x + 9):
			for y in range(center_y - 6, center_y + 2):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, weapon_color)
		
		# Legs (longer and wider)
		for x in range(center_x - 3, center_x - 1):
			for y in range(center_y + 6, center_y + 12):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, secondary_color)
		
		for x in range(center_x + 1, center_x + 3):
			for y in range(center_y + 6, center_y + 12):
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					image.set_pixel(x, y, secondary_color)
		
		# Eyes (simple dots)
		if center_x - 2 >= 0 and center_x - 2 < 32 and center_y - 8 >= 0 and center_y - 8 < 32:
			image.set_pixel(center_x - 2, center_y - 8, Color.BLACK)
		if center_x + 1 >= 0 and center_x + 1 < 32 and center_y - 8 >= 0 and center_y - 8 < 32:
			image.set_pixel(center_x + 1, center_y - 8, Color.BLACK)
		
		# Special features for specific monsters
		if monster_name == "Skeleton":
			# Add rib cage lines (more visible)
			for y in range(center_y - 2, center_y + 4):
				if y >= 0 and y < 32:
					if center_x - 3 >= 0 and center_x - 3 < 32:
						image.set_pixel(center_x - 3, y, Color(0.4, 0.4, 0.4))
					if center_x + 2 >= 0 and center_x + 2 < 32:
						image.set_pixel(center_x + 2, y, Color(0.4, 0.4, 0.4))
		
		elif monster_name == "Zombie":
			# Add decay spots (more visible)
			for i in range(6):
				var spot_x = center_x + randi_range(-3, 3)
				var spot_y = center_y + randi_range(-3, 4)
				if spot_x >= 0 and spot_x < 32 and spot_y >= 0 and spot_y < 32:
					image.set_pixel(spot_x, spot_y, Color(0.2, 0.3, 0.1))
		
		elif monster_name == "Kobold":
			# Add scale pattern (more visible on head)
			for x in range(center_x - 3, center_x + 3):
				for y in range(center_y - 8, center_y - 6):
					if (x + y) % 2 == 0 and x >= 0 and x < 32 and y >= 0 and y < 32:
						image.set_pixel(x, y, secondary_color)
		
		elif monster_name == "Gnoll":
			# Add hyena spots (more visible on head)
			for i in range(6):
				var spot_x = center_x + randi_range(-3, 3)
				var spot_y = center_y + randi_range(-8, -5)
				if spot_x >= 0 and spot_x < 32 and spot_y >= 0 and spot_y < 32:
					image.set_pixel(spot_x, spot_y, secondary_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _on_combat_finished(player_won: bool):
	# Exit combat mode - re-enable player movement
	player.exit_combat()
	
	# Handle combat outcome
	if player_won:
		# Award XP for victory - base amount varies by enemy type
		var xp_reward = 25 + randi() % 26  # 25-50 XP for winning
		player.gain_experience(xp_reward)
		print("Combat victory! Gained ", xp_reward, " XP")
	else:
		# Handle player defeat - respawn with full health
		respawn_player()
	
	# Clean up enemy nodes after combat
	var enemies = get_children().filter(func(child): return child is Character and child != player)
	for enemy in enemies:
		enemy.queue_free()

func _on_camping_started():
	print("Setting up campsite...")
	show_camping_overlay()

func _on_player_moved():
	# Update coordinate overlay when player moves
	if coordinate_overlay and player:
		var player_pos = Vector2(int(player.global_position.x / TILE_SIZE), int(player.global_position.y / TILE_SIZE))
		coordinate_overlay.update_coordinates(player_pos)

func _on_town_name_display(town_name: String):
	# Disabled - no longer showing large town name text
	print("DEBUG: _on_town_name_display called with: ", town_name, " (disabled)")
	return
	if town_name_label:
		# Update the text to include "Welcome to" prefix
		var display_text = "Welcome to " + town_name
		town_name_label.text = display_text
		print("DEBUG: Set label text to: ", town_name_label.text)
		
		# Wait one frame for the label to update its size, then center it
		await get_tree().process_frame
		
		# Get the actual text size for proper centering
		var text_size = town_name_label.get_theme_font("font").get_string_size(
			display_text, 
			HORIZONTAL_ALIGNMENT_LEFT, 
			-1, 
			town_name_label.get_theme_font_size("font_size")
		)
		
		# Get viewport size for centering
		var viewport_size = get_viewport().size
		
		# Center the label horizontally and position it in the upper third of the screen
		town_name_label.size = Vector2(text_size.x + 40, text_size.y + 20)  # Add padding
		town_name_label.position.x = (viewport_size.x - town_name_label.size.x) / 2  # Center horizontally
		town_name_label.position.y = viewport_size.y / 3  # Upper third of screen
		
		print("DEBUG: Text size: ", text_size)
		print("DEBUG: Label size: ", town_name_label.size)
		print("DEBUG: Viewport size: ", viewport_size)
		print("DEBUG: Label positioned at: ", town_name_label.position)
		
		town_name_label.show()
		print("DEBUG: Label shown, visible: ", town_name_label.visible)
		
		# Restart the timer to hide the label after 3 seconds
		if town_name_timer:
			town_name_timer.start()
			print("DEBUG: Timer started")

func create_town_name_display():
	# Create a label to display town names
	town_name_label = Label.new()
	town_name_label.text = ""
	
	# Style the label for better visibility
	town_name_label.add_theme_font_size_override("font_size", 28)  # Larger font
	town_name_label.add_theme_color_override("font_color", Color.WHITE)
	town_name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	town_name_label.add_theme_constant_override("shadow_offset_x", 3)
	town_name_label.add_theme_constant_override("shadow_offset_y", 3)
	
	# Center the text within the label
	town_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	town_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Add a background for better readability
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.7)  # Semi-transparent black background
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.YELLOW
	town_name_label.add_theme_stylebox_override("normal", style_box)
	
	# Set initial size and position (will be updated when shown)
	town_name_label.size = Vector2(300, 60)
	town_name_label.position = Vector2(100, 100)  # Will be repositioned when shown
	town_name_label.hide()  # Start hidden
	
	print("DEBUG: Created town_name_label with size: ", town_name_label.size)
	
	# Add to UI layer
	var ui_layer = $UI
	if ui_layer:
		ui_layer.add_child(town_name_label)
		print("DEBUG: Added town_name_label to UI layer")
	else:
		print("ERROR: No UI layer found for town_name_label")
	
	# Create timer to hide the label
	town_name_timer = Timer.new()
	town_name_timer.wait_time = 3.0
	town_name_timer.one_shot = true
	town_name_timer.timeout.connect(_on_town_name_timeout)
	add_child(town_name_timer)

func _on_town_name_timeout():
	# Hide the town name label after timeout
	if town_name_label:
		town_name_label.hide()

func _exit_tree():
	# Clean up resources when the scene exits
	if town_name_timer and is_instance_valid(town_name_timer):
		if town_name_timer.timeout.is_connected(_on_town_name_timeout):
			town_name_timer.timeout.disconnect(_on_town_name_timeout)
		if town_name_timer.get_parent():
			town_name_timer.get_parent().remove_child.call_deferred(town_name_timer)
		else:
			town_name_timer.queue_free()
		town_name_timer = null
	
	if town_name_label and is_instance_valid(town_name_label):
		if town_name_label.get_parent():
			town_name_label.get_parent().remove_child.call_deferred(town_name_label)
		else:
			town_name_label.queue_free()
		town_name_label = null
	
	# Disconnect all main signals if nodes still exist
	if player and is_instance_valid(player):
		if player.encounter_started.is_connected(_on_encounter_started):
			player.encounter_started.disconnect(_on_encounter_started)
		if player.camping_started.is_connected(_on_camping_started):
			player.camping_started.disconnect(_on_camping_started)
		if player.movement_finished.is_connected(_on_player_moved):
			player.movement_finished.disconnect(_on_player_moved)
		if player.town_name_display.is_connected(_on_town_name_display):
			player.town_name_display.disconnect(_on_town_name_display)
	
	if combat_manager and is_instance_valid(combat_manager):
		if combat_manager.combat_finished.is_connected(_on_combat_finished):
			combat_manager.combat_finished.disconnect(_on_combat_finished)

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
	
	# Find nearby towns with T key
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		find_nearby_towns()

func _close_camping_overlay():
	camping_overlay_active = false
	
	# Find and remove camping overlay
	var camping_overlays = get_children().filter(func(child): return child.has_meta("is_camping_overlay"))
	for overlay in camping_overlays:
		overlay.queue_free()

func find_nearby_towns():
	if !terrain or !player:
		print("Error: Missing terrain or player reference!")
		return
	
	print("=== NEARBY TOWNS ===")
	var player_tile_pos = Vector2i(int(player.global_position.x / TILE_SIZE), int(player.global_position.y / TILE_SIZE))
	print("Player position: Tile (", player_tile_pos.x, ", ", player_tile_pos.y, ") - World (", player.global_position.x, ", ", player.global_position.y, ")")
	
	var towns_found = []
	
	# Get all towns from terrain
	if terrain.has_method("get_all_towns"):
		towns_found = terrain.get_all_towns()
	else:
		print("Terrain doesn't have get_all_towns method - searching manually...")
		# Manual search through sections
		for section_id in terrain.map_sections.keys():
			var section = terrain.map_sections[section_id]
			for local_pos in section.town_data.keys():
				var world_tile_pos = terrain.world_to_global_tile(local_pos, section_id)
				var town_data = section.town_data[local_pos]
				var distance = player_tile_pos.distance_to(Vector2(world_tile_pos.x, world_tile_pos.y))
				towns_found.append({
					"name": town_data.get("name", "Unknown"),
					"world_pos": world_tile_pos,
					"distance": distance,
					"section": section_id
				})
	
	if towns_found.size() == 0:
		print("No towns found!")
		return
	
	# Sort towns by distance
	towns_found.sort_custom(func(a, b): return a.distance < b.distance)
	
	print("Found ", towns_found.size(), " towns:")
	for i in range(min(5, towns_found.size())):  # Show closest 5 towns
		var town = towns_found[i]
		print("  ", i + 1, ". ", town.name, " - Tile (", town.world_pos.x, ", ", town.world_pos.y, ") - Distance: ", "%.1f" % town.distance, " tiles")
		if i == 0:
			print("     ^^ CLOSEST TOWN ^^")
	
	print("Press T again to refresh town list")
	print("===================")
	
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
