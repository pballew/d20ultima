extends Node

const CharacterData = preload("res://scripts/CharacterData.gd")

func _ready():
	DebugLogger.info("Creating quick save character...")
	var c = CharacterData.new()
	c.character_name = "Quick Hero"
	c.character_race = CharacterData.CharacterRace.HUMAN
	c.character_class = CharacterData.CharacterClass.FIGHTER
	# Basic stats
	c.strength = 14
	c.dexterity = 12
	c.constitution = 12
	c.intelligence = 10
	c.wisdom = 10
	c.charisma = 10
	# Derived/simple defaults
	c.max_health = 12
	c.current_health = 12
	# Start at origin
	c.world_position = Vector2.ZERO
	# Save as last played character
	var ok = SaveSystem.save_game_state(c)
	DebugLogger.info(str("Quick save created:") + " " + str(ok))
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

