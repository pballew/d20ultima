class_name CharacterData
extends Resource

# D20 Character Classes
enum CharacterClass { 
	FIGHTER, ROGUE, WIZARD, CLERIC, RANGER, BARBARIAN 
}

# D20 Character Races
enum CharacterRace {
	HUMAN, ELF, DWARF, HALFLING, GNOME, HALF_ELF, HALF_ORC, DRAGONBORN, TIEFLING
}

@export var character_name: String = ""
@export var character_class: CharacterClass = CharacterClass.FIGHTER
@export var character_race: CharacterRace = CharacterRace.HUMAN
@export var level: int = 1

# Core stats (point-buy or rolled)
@export var strength: int = 10
@export var dexterity: int = 10
@export var constitution: int = 10
@export var intelligence: int = 10
@export var wisdom: int = 10
@export var charisma: int = 10

# Derived stats
@export var max_health: int = 10
@export var current_health: int = 10
@export var experience: int = 0
@export var gold: int = 100

# Class features
@export var attack_bonus: int = 0
@export var damage_dice: String = "1d4"
@export var armor_class: int = 10
@export var skill_points: int = 0

# Game progress
@export var world_position: Vector2 = Vector2.ZERO
@export var save_timestamp: String = ""
@export var explored_tiles: PackedVector2Array = PackedVector2Array() # Fog of war explored tile coordinates
@export var last_reveal_radius: int = 0  # For future scaling or compatibility

func _init():
	save_timestamp = Time.get_datetime_string_from_system()

func get_class_name() -> String:
	match character_class:
		CharacterClass.FIGHTER:
			return "Fighter"
		CharacterClass.ROGUE:
			return "Rogue"
		CharacterClass.WIZARD:
			return "Wizard"
		CharacterClass.CLERIC:
			return "Cleric"
		CharacterClass.RANGER:
			return "Ranger"
		CharacterClass.BARBARIAN:
			return "Barbarian"
		_:
			return "Unknown"

func get_race_name() -> String:
	match character_race:
		CharacterRace.HUMAN:
			return "Human"
		CharacterRace.ELF:
			return "Elf"
		CharacterRace.DWARF:
			return "Dwarf"
		CharacterRace.HALFLING:
			return "Halfling"
		CharacterRace.GNOME:
			return "Gnome"
		CharacterRace.HALF_ELF:
			return "Half-Elf"
		CharacterRace.HALF_ORC:
			return "Half-Orc"
		CharacterRace.DRAGONBORN:
			return "Dragonborn"
		CharacterRace.TIEFLING:
			return "Tiefling"
		_:
			return "Unknown"

func get_race_description() -> String:
	match character_race:
		CharacterRace.HUMAN:
			return "Versatile and ambitious, humans are the most adaptable race. +1 to all stats."
		CharacterRace.ELF:
			return "Graceful and long-lived, with keen senses. +2 Dex, +1 Int. Darkvision."
		CharacterRace.DWARF:
			return "Hardy mountain folk with strong constitutions. +2 Con, +1 Wis. Poison resistance."
		CharacterRace.HALFLING:
			return "Small but brave, with natural luck. +2 Dex, +1 Cha. Lucky trait."
		CharacterRace.GNOME:
			return "Small, clever, and magically inclined. +2 Int, +1 Con. Gnome cunning."
		CharacterRace.HALF_ELF:
			return "Mix of human and elf heritage. +2 Cha, +1 to two different stats."
		CharacterRace.HALF_ORC:
			return "Strong and fierce, with orcish blood. +2 Str, +1 Con. Relentless endurance."
		CharacterRace.DRAGONBORN:
			return "Draconic humanoids with breath weapons. +2 Str, +1 Cha. Breath weapon."
		CharacterRace.TIEFLING:
			return "Touched by infernal heritage. +2 Cha, +1 Int. Fire resistance."
		_:
			return "A mysterious heritage."

func get_class_description() -> String:
	match character_class:
		CharacterClass.FIGHTER:
			return "Masters of martial combat, skilled with many weapons and armor."
		CharacterClass.ROGUE:
			return "Sneaky and skilled, experts at dealing precise damage from shadows."
		CharacterClass.WIZARD:
			return "Scholarly magic-users capable of manipulating reality with spells."
		CharacterClass.CLERIC:
			return "Divine spellcasters who channel the power of their deity."
		CharacterClass.RANGER:
			return "Skilled hunters and trackers who protect the wilderness."
		CharacterClass.BARBARIAN:
			return "Fierce warriors who tap into primal fury in battle."
		_:
			return "A mysterious adventurer."

func apply_class_bonuses():
	# Apply racial bonuses first
	apply_racial_bonuses()
	
	# Then apply class bonuses
	match character_class:
		CharacterClass.FIGHTER:
			strength += 2
			constitution += 1
			attack_bonus = 1
			damage_dice = "1d8"
			armor_class = 12  # Chain mail
		CharacterClass.ROGUE:
			dexterity += 2
			intelligence += 1
			attack_bonus = 0
			damage_dice = "1d6"
			armor_class = 11  # Leather armor
		CharacterClass.WIZARD:
			intelligence += 2
			wisdom += 1
			attack_bonus = 0
			damage_dice = "1d4"
			armor_class = 10  # No armor
		CharacterClass.CLERIC:
			wisdom += 2
			strength += 1
			attack_bonus = 0
			damage_dice = "1d6"
			armor_class = 11  # Scale mail
		CharacterClass.RANGER:
			dexterity += 1
			wisdom += 1
			constitution += 1
			attack_bonus = 1
			damage_dice = "1d8"
			armor_class = 11  # Studded leather
		CharacterClass.BARBARIAN:
			strength += 2
			constitution += 2
			attack_bonus = 1
			damage_dice = "1d12"
			armor_class = 10  # Unarmored defense

func apply_racial_bonuses():
	match character_race:
		CharacterRace.HUMAN:
			strength += 1
			dexterity += 1
			constitution += 1
			intelligence += 1
			wisdom += 1
			charisma += 1
		CharacterRace.ELF:
			dexterity += 2
			intelligence += 1
		CharacterRace.DWARF:
			constitution += 2
			wisdom += 1
		CharacterRace.HALFLING:
			dexterity += 2
			charisma += 1
		CharacterRace.GNOME:
			intelligence += 2
			constitution += 1
		CharacterRace.HALF_ELF:
			charisma += 2
			# Half-elves get +1 to two different stats of choice
			# For simplicity, we'll add +1 Dex and +1 Wis
			dexterity += 1
			wisdom += 1
		CharacterRace.HALF_ORC:
			strength += 2
			constitution += 1
		CharacterRace.DRAGONBORN:
			strength += 2
			charisma += 1
		CharacterRace.TIEFLING:
			charisma += 2
			intelligence += 1

func calculate_derived_stats():
	# Calculate health based on class and constitution
	var con_modifier = (constitution - 10) / 2
	var base_hp = get_class_base_hp()
	max_health = base_hp + con_modifier + ((level - 1) * (get_class_hp_per_level() + con_modifier))
	current_health = max_health

func get_class_base_hp() -> int:
	match character_class:
		CharacterClass.FIGHTER, CharacterClass.BARBARIAN:
			return 10
		CharacterClass.CLERIC, CharacterClass.RANGER:
			return 8
		CharacterClass.ROGUE:
			return 6
		CharacterClass.WIZARD:
			return 4
		_:
			return 6

func get_class_hp_per_level() -> int:
	match character_class:
		CharacterClass.FIGHTER, CharacterClass.BARBARIAN:
			return 6
		CharacterClass.CLERIC, CharacterClass.RANGER:
			return 5
		CharacterClass.ROGUE:
			return 4
		CharacterClass.WIZARD:
			return 3
		_:
			return 4

# Roll hit dice based on character class for level-up HP gain
# Rerolls any 1s for better survivability
func roll_class_hit_die() -> int:
	var roll = 1
	match character_class:
		CharacterClass.BARBARIAN:
			while roll == 1:
				roll = randi() % 12 + 1  # d12 (2-12, reroll 1s)
		CharacterClass.FIGHTER, CharacterClass.RANGER:
			while roll == 1:
				roll = randi() % 10 + 1  # d10 (2-10, reroll 1s)
		CharacterClass.CLERIC, CharacterClass.ROGUE:
			while roll == 1:
				roll = randi() % 8 + 1   # d8 (2-8, reroll 1s)
		CharacterClass.WIZARD:
			while roll == 1:
				roll = randi() % 4 + 1   # d4 (2-4, reroll 1s)
		_:
			while roll == 1:
				roll = randi() % 8 + 1   # Default d8 (2-8, reroll 1s)
	return roll

func get_stat_limits() -> Dictionary:
	# Base D20 limits: 8-15 for point buy, but racial bonuses can push beyond 15
	var base_min = 8
	var base_max = 15
	var racial_max = 17  # Max after racial bonuses
	
	return {
		"min": base_min,
		"max": base_max,
		"racial_max": racial_max
	}

func get_racial_stat_bonuses() -> Dictionary:
	# Returns the stat bonuses for the current race
	match character_race:
		CharacterRace.HUMAN:
			return {"str": 1, "dex": 1, "con": 1, "int": 1, "wis": 1, "cha": 1}
		CharacterRace.ELF:
			return {"str": 0, "dex": 2, "con": 0, "int": 1, "wis": 0, "cha": 0}
		CharacterRace.DWARF:
			return {"str": 0, "dex": 0, "con": 2, "int": 0, "wis": 1, "cha": 0}
		CharacterRace.HALFLING:
			return {"str": 0, "dex": 2, "con": 0, "int": 0, "wis": 0, "cha": 1}
		CharacterRace.GNOME:
			return {"str": 0, "dex": 0, "con": 1, "int": 2, "wis": 0, "cha": 0}
		CharacterRace.HALF_ELF:
			return {"str": 0, "dex": 1, "con": 0, "int": 0, "wis": 1, "cha": 2}
		CharacterRace.HALF_ORC:
			return {"str": 2, "dex": 0, "con": 1, "int": 0, "wis": 0, "cha": 0}
		CharacterRace.DRAGONBORN:
			return {"str": 2, "dex": 0, "con": 0, "int": 0, "wis": 0, "cha": 1}
		CharacterRace.TIEFLING:
			return {"str": 0, "dex": 0, "con": 0, "int": 1, "wis": 0, "cha": 2}
		_:
			return {"str": 0, "dex": 0, "con": 0, "int": 0, "wis": 0, "cha": 0}

func get_character_summary() -> String:
	var summary = get_race_name() + " " + get_class_name() + "\n"
	summary += "Level " + str(level) + " (" + str(experience) + " XP)\n\n"
	
	# Display final stats with racial bonuses
	var racial_bonuses = get_racial_stat_bonuses()
	summary += "STR: " + str(strength) + " (base + racial)\n"
	summary += "DEX: " + str(dexterity) + " (base + racial)\n"
	summary += "CON: " + str(constitution) + " (base + racial)\n"
	summary += "INT: " + str(intelligence) + " (base + racial)\n"
	summary += "WIS: " + str(wisdom) + " (base + racial)\n"
	summary += "CHA: " + str(charisma) + " (base + racial)\n\n"
	
	summary += "HP: " + str(current_health) + "/" + str(max_health) + "\n"
	summary += "AC: " + str(armor_class) + "\n"
	summary += "Attack Bonus: +" + str(attack_bonus) + "\n"
	summary += "Damage: " + damage_dice + "\n"
	summary += "XP: " + str(experience) + "/" + str(get_xp_for_next_level()) + "\n"
	
	return summary

# === EXPERIENCE POINT SYSTEM ===

# D&D 5E-style XP progression table
func get_xp_for_level(target_level: int) -> int:
	if target_level <= 1:
		return 0
	
	# Standard D&D XP progression
	var xp_table = {
		2: 300,
		3: 900,
		4: 2700,
		5: 6500,
		6: 14000,
		7: 23000,
		8: 34000,
		9: 48000,
		10: 64000,
		11: 85000,
		12: 100000,
		13: 120000,
		14: 140000,
		15: 165000,
		16: 195000,
		17: 225000,
		18: 265000,
		19: 305000,
		20: 355000
	}
	
	if target_level in xp_table:
		return xp_table[target_level]
	else:
		# For levels beyond 20, use exponential growth
		return 355000 + (target_level - 20) * 50000

# Get XP required for the next level
func get_xp_for_next_level() -> int:
	return get_xp_for_level(level + 1)

# Get current XP progress as a percentage (0.0 to 1.0)
func get_xp_progress() -> float:
	var current_level_xp = get_xp_for_level(level)
	var next_level_xp = get_xp_for_next_level()
	var progress_in_level = experience - current_level_xp
	var xp_needed_for_level = next_level_xp - current_level_xp
	
	if xp_needed_for_level <= 0:
		return 1.0
	
	return float(progress_in_level) / float(xp_needed_for_level)

# Add experience points and handle level-ups
func gain_experience(xp_amount: int) -> bool:
	var old_level = level
	experience += xp_amount
	
	print("Gained ", xp_amount, " XP! Total: ", experience)
	
	# Check for level-ups
	while experience >= get_xp_for_next_level() and level < 20:
		level_up()
	
	# Return true if we leveled up
	return level > old_level

# Handle a single level-up
func level_up():
	var old_level = level
	level += 1
	
	print("LEVEL UP! ", character_name, " is now level ", level)
	
	# Roll for HP increase based on class hit die
	var hit_die_roll = roll_class_hit_die()
	var con_modifier = get_stat_modifier(constitution)
	var hp_gain = hit_die_roll + con_modifier
	hp_gain = max(1, hp_gain)  # Minimum 1 HP per level
	
	max_health += hp_gain
	current_health += hp_gain  # Heal on level-up
	
	print("Rolled ", hit_die_roll, " on hit die + ", con_modifier, " CON mod = ", hp_gain, " HP gained!")
	print("New max HP: ", max_health)
	
	# Increase attack bonus every few levels (class-dependent)
	var old_attack_bonus = attack_bonus
	calculate_attack_bonus()
	
	if attack_bonus > old_attack_bonus:
		print("Attack bonus increased to +", attack_bonus)
	
	# Recalculate all derived stats
	calculate_derived_stats()
	
	print("Level ", old_level, " -> ", level, " complete!")

# Calculate attack bonus based on level and class
func calculate_attack_bonus():
	match character_class:
		CharacterClass.FIGHTER, CharacterClass.RANGER, CharacterClass.BARBARIAN:
			# Full BAB progression
			attack_bonus = level + get_stat_modifier(strength)
		CharacterClass.CLERIC:
			# 3/4 BAB progression
			attack_bonus = int(level * 0.75) + get_stat_modifier(strength)
		CharacterClass.ROGUE, CharacterClass.WIZARD:
			# 1/2 BAB progression
			attack_bonus = int(level * 0.5) + get_stat_modifier(dexterity if character_class == CharacterClass.ROGUE else strength)

# Get stat modifier from ability score (D&D standard: -5 to +5)
func get_stat_modifier(stat_value: int) -> int:
	return (stat_value - 10) / 2

# Award XP for various activities
func award_xp_for_combat(enemy_level: int) -> int:
	var base_xp = enemy_level * 100
	var level_difference = enemy_level - level
	
	# Scale XP based on level difference
	if level_difference > 0:
		base_xp *= (1.0 + level_difference * 0.2)  # More XP for stronger enemies
	elif level_difference < -2:
		base_xp *= 0.5  # Less XP for much weaker enemies
	
	base_xp = max(10, int(base_xp))  # Minimum 10 XP
	gain_experience(base_xp)
	return base_xp

# Award XP for town discovery
func award_xp_for_exploration() -> int:
	var xp_amount = 50 + level * 10  # Scales with level
	gain_experience(xp_amount)
	return xp_amount

# Award XP for quest completion
func award_xp_for_quest(difficulty_level: int) -> int:
	var base_xp = difficulty_level * 200
	gain_experience(base_xp)
	return base_xp
