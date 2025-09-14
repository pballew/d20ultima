class_name MonsterData
extends Resource

enum MonsterType {
	HUMANOID,
	ANIMAL,
	UNDEAD,
	MAGICAL_BEAST
}

enum Size {
	FINE,
	DIMINUTIVE,
	TINY,
	SMALL,
	MEDIUM,
	LARGE,
	HUGE,
	GARGANTUAN,
	COLOSSAL
}

@export var monster_name: String = ""
@export var monster_type: MonsterType = MonsterType.ANIMAL
@export var size: Size = Size.MEDIUM
@export var hit_dice: String = "1d8"
@export var challenge_rating: int = 1

# Ability Scores
@export var strength: int = 10
@export var dexterity: int = 10
@export var constitution: int = 10
@export var intelligence: int = 10
@export var wisdom: int = 10
@export var charisma: int = 10

# Combat Stats  
@export var base_attack_bonus: int = 0
@export var natural_armor: int = 0
@export var damage_dice: String = "1d6"
@export var num_attacks: int = 1

# Saving Throws
@export var fortitude_base: int = 0
@export var reflex_base: int = 0
@export var will_base: int = 0

# Special abilities
@export var skills: Dictionary = {}
@export var special_attacks: Array = []
@export var special_qualities: Array = []
@export var damage_reduction: String = ""
@export var damage_immunities: Array = []
@export var damage_resistances: Dictionary = {}

# Descriptions
@export var description: String = ""
@export var combat_behavior: String = ""
@export var environment: String = ""

func get_type_name() -> String:
	match monster_type:
		MonsterType.HUMANOID: return "Humanoid"
		MonsterType.ANIMAL: return "Animal" 
		MonsterType.UNDEAD: return "Undead"
		MonsterType.MAGICAL_BEAST: return "Magical Beast"
		_: return "Unknown"

func get_size_name() -> String:
	match size:
		Size.FINE: return "Fine"
		Size.DIMINUTIVE: return "Diminutive"
		Size.TINY: return "Tiny"
		Size.SMALL: return "Small"
		Size.MEDIUM: return "Medium"
		Size.LARGE: return "Large"
		Size.HUGE: return "Huge"
		Size.GARGANTUAN: return "Gargantuan"
		Size.COLOSSAL: return "Colossal"
		_: return "Unknown"

func get_size_modifier() -> int:
	match size:
		Size.FINE: return -8
		Size.DIMINUTIVE: return -4
		Size.TINY: return -2
		Size.SMALL: return -1
		Size.MEDIUM: return 0
		Size.LARGE: return 1
		Size.HUGE: return 2
		Size.GARGANTUAN: return 4
		Size.COLOSSAL: return 8
		_: return 0

func calculate_armor_class() -> int:
	# 3.5 AC = 10 + Dex modifier + natural armor + size modifier
	var dex_modifier = (dexterity - 10) / 2
	var size_mod = get_size_modifier()
	return 10 + dex_modifier + natural_armor + size_mod

func calculate_attack_bonus() -> int:
	# 3.5 Attack Bonus = BAB + Str modifier + size modifier
	var str_modifier = (strength - 10) / 2
	var size_mod = get_size_modifier()
	return base_attack_bonus + str_modifier + size_mod

func calculate_fortitude_save() -> int:
	# 3.5 Fortitude Save = base + Con modifier
	var con_modifier = (constitution - 10) / 2 if constitution > 0 else 0
	return fortitude_base + con_modifier

func calculate_reflex_save() -> int:
	# 3.5 Reflex Save = base + Dex modifier
	var dex_modifier = (dexterity - 10) / 2
	return reflex_base + dex_modifier

func calculate_will_save() -> int:
	# 3.5 Will Save = base + Wis modifier
	var wis_modifier = (wisdom - 10) / 2
	return will_base + wis_modifier

func get_ability_modifier(ability_score: int) -> int:
	# Standard D&D 3.5 ability modifier calculation
	return (ability_score - 10) / 2

func calculate_hit_points() -> int:
	# Parse hit dice string (e.g., "2d8+4", "1d12", "1d10+3")
	var hit_dice_parts = hit_dice.split("d")
	if hit_dice_parts.size() < 2:
		return 8  # Default fallback
	
	var num_dice = int(hit_dice_parts[0])
	var remaining = hit_dice_parts[1]
	
	# Check for modifier (+ or -)
	var die_size: int
	var modifier: int = 0
	
	if "+" in remaining:
		var plus_parts = remaining.split("+")
		die_size = int(plus_parts[0])
		if plus_parts.size() > 1:
			modifier = int(plus_parts[1])
	elif "-" in remaining:
		var minus_parts = remaining.split("-")
		die_size = int(minus_parts[0])
		if minus_parts.size() > 1:
			modifier = -int(minus_parts[1])
	else:
		die_size = int(remaining)
	
	# Calculate HP: average of dice + modifier + Con modifier per die
	var con_modifier = get_ability_modifier(constitution) if constitution > 0 else 0
	var average_per_die = (die_size / 2.0) + 0.5  # Average of 1dX
	var total_hp = int(num_dice * average_per_die) + modifier + (num_dice * con_modifier)
	
	# Minimum 1 HP per hit die
	return max(total_hp, num_dice)
