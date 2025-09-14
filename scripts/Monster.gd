class_name Monster
extends Character

var monster_data: MonsterData
var attacks_per_turn: int = 1
var special_attack_uses: Dictionary = {}
var grapple_bonus: int = 0

# 3.5 Saving Throws
var fortitude_save: int = 0
var reflex_save: int = 0
var will_save: int = 0

func setup_from_monster_data(data: MonsterData):
	monster_data = data
	
	# Set basic stats
	character_name = data.monster_name
	strength = data.strength
	dexterity = data.dexterity
	constitution = data.constitution
	intelligence = data.intelligence
	wisdom = data.wisdom
	charisma = data.charisma
	
	# Calculate 3.5 combat stats
	armor_class = data.calculate_armor_class()
	attack_bonus = data.calculate_attack_bonus()
	damage_dice = data.damage_dice
	attacks_per_turn = data.num_attacks
	
	# Calculate 3.5 saving throws
	fortitude_save = data.calculate_fortitude_save()
	reflex_save = data.calculate_reflex_save()
	will_save = data.calculate_will_save()
	
	# Calculate grapple bonus (BAB + Str modifier + size modifier)
	var str_modifier = data.get_ability_modifier(strength)
	var size_modifier = get_grapple_size_modifier(data.size)
	grapple_bonus = data.base_attack_bonus + str_modifier + size_modifier
	
	# Calculate and set hit points
	max_health = data.calculate_hit_points()
	current_health = max_health
	print("Monster ", data.monster_name, " calculated health: ", max_health)
	
	# Initialize special attack uses (3.5 style)
	for attack in data.special_attacks:
		# Different attacks have different usage limits
		match attack:
			"Breath Weapon":
				special_attack_uses[attack] = 1  # Once per encounter
			"Spell-like Ability":
				special_attack_uses[attack] = 3  # 3/day typical
			"Energy Drain":
				special_attack_uses[attack] = 2  # Limited uses
			_:
				special_attack_uses[attack] = 99  # At-will abilities

func get_grapple_size_modifier(size: MonsterData.Size) -> int:
	match size:
		MonsterData.Size.FINE: return -16
		MonsterData.Size.DIMINUTIVE: return -12
		MonsterData.Size.TINY: return -8
		MonsterData.Size.SMALL: return -4
		MonsterData.Size.MEDIUM: return 0
		MonsterData.Size.LARGE: return 4
		MonsterData.Size.HUGE: return 8
		MonsterData.Size.GARGANTUAN: return 12
		MonsterData.Size.COLOSSAL: return 16
		_: return 0

func get_monster_description() -> String:
	if monster_data:
		return monster_data.get_full_description()
	return "Unknown monster"

func has_special_quality(quality_type: String) -> bool:
	if monster_data:
		return quality_type in monster_data.special_qualities
	return false

func has_damage_immunity(damage_type: String) -> bool:
	if monster_data:
		return damage_type in monster_data.damage_immunities
	return false

func has_damage_resistance(damage_type: String) -> bool:
	if monster_data:
		return damage_type in monster_data.damage_resistances
	return false

func get_damage_resistance_value(damage_type: String) -> int:
	if monster_data and has_damage_resistance(damage_type):
		return monster_data.damage_resistances.get(damage_type, 0)
	return 0

func can_use_special_attack(attack_name: String) -> bool:
	return special_attack_uses.get(attack_name, 0) > 0

func use_special_attack(attack_name: String):
	if can_use_special_attack(attack_name):
		if special_attack_uses[attack_name] < 99:  # Don't decrease at-will abilities
			special_attack_uses[attack_name] -= 1

func get_available_special_attacks() -> Array[String]:
	var available: Array[String] = []
	for attack in monster_data.special_attacks:
		if can_use_special_attack(attack):
			available.append(attack)
	return available

# 3.5 Saving Throw rolls
func make_fortitude_save(dc: int) -> bool:
	var roll = randi_range(1, 20)
	return (roll + fortitude_save) >= dc

func make_reflex_save(dc: int) -> bool:
	var roll = randi_range(1, 20)
	return (roll + reflex_save) >= dc

func make_will_save(dc: int) -> bool:
	var roll = randi_range(1, 20)
	return (roll + will_save) >= dc

# Override take_damage to handle 3.5 damage reduction and immunities
func take_damage(amount: int, damage_type: String = "physical"):
	var final_damage = amount
	
	if not monster_data:
		super.take_damage(final_damage)
		return
	
	# Check for damage immunity
	if has_damage_immunity(damage_type):
		print(character_name + " is immune to " + damage_type + " damage!")
		return
	
	# Apply damage resistance
	if has_damage_resistance(damage_type):
		var resistance = get_damage_resistance_value(damage_type)
		final_damage = max(0, final_damage - resistance)
		if final_damage < amount:
			print(character_name + " resists " + str(amount - final_damage) + " points of " + damage_type + " damage!")
	
	# Apply damage reduction (e.g., "5/magic")
	if monster_data.damage_reduction != "":
		var dr_parts = monster_data.damage_reduction.split("/")
		if dr_parts.size() >= 2:
			var dr_amount = dr_parts[0].to_int()
			var dr_type = dr_parts[1]
			
			# For simplicity, assume most attacks don't bypass DR
			if damage_type == "physical":
				final_damage = max(0, final_damage - dr_amount)
				if final_damage < amount:
					print(character_name + "'s damage reduction absorbs " + str(amount - final_damage) + " damage!")
	
	super.take_damage(final_damage)

# Override for spell resistance
func resist_spell(spell_level: int, caster_level: int) -> bool:
	if monster_data.spell_resistance > 0:
		var roll = randi_range(1, 20)
		return (roll + caster_level) < monster_data.spell_resistance
	return false
