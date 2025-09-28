class_name Character
extends Node2D

# Character Identity
@export var character_name: String = "Unnamed"

# D20 System Character Stats
@export var strength: int = 10
@export var dexterity: int = 10
@export var constitution: int = 10
@export var intelligence: int = 10
@export var wisdom: int = 10
@export var charisma: int = 10

# Derived Stats
@export var max_health: int = 100
@export var current_health: int = 100
@export var armor_class: int = 10
@export var level: int = 1
@export var experience: int = 0

# Combat Stats
@export var attack_bonus: int = 0
@export var damage_dice: String = "1d6"
var initiative: int = 0  # 3.5 Initiative value

# Equipment
var weapon: Item = null
var armor: Item = null
var inventory: Array[Item] = []

signal health_changed(new_health: int, max_health: int)
signal experience_changed(new_xp: int, level: int)
signal died

func _ready():
	update_derived_stats()

func get_modifier(stat: int) -> int:
	return (stat - 10) / 2

func update_derived_stats():
	# Update AC with dexterity modifier
	armor_class = 10 + get_modifier(dexterity)
	if armor:
		armor_class += armor.armor_bonus
	
	# Update health with constitution modifier
	max_health = 100 + (get_modifier(constitution) * level * 10)
	if current_health > max_health:
		current_health = max_health

func roll_d20() -> int:
	return randi_range(1, 20)

func roll_dice(dice_string: String) -> int:
	# Parse dice strings like "1d6", "2d8+3", etc.
	var parts = dice_string.split("+")
	var base_roll = 0
	var modifier = 0
	
	if parts.size() > 1:
		modifier = parts[1].to_int()
	
	var dice_part = parts[0]
	var dice_components = dice_part.split("d")
	var num_dice = dice_components[0].to_int()
	var die_size = dice_components[1].to_int()
	
	for i in range(num_dice):
		base_roll += randi_range(1, die_size)
	
	return base_roll + modifier

func make_attack_roll(target: Character) -> bool:
	var roll = roll_d20()
	var total = roll + attack_bonus + get_modifier(strength)
	print("Attack roll: ", roll, " + ", attack_bonus, " + ", get_modifier(strength), " = ", total)
	return total >= target.armor_class

func deal_damage(target: Character):
	var damage = roll_dice(damage_dice) + get_modifier(strength)
	target.take_damage(damage)
	print("Dealt ", damage, " damage to ", target.name)

func take_damage(amount: int, damage_type: String = "physical"):
	current_health -= amount
	current_health = max(0, current_health)
	health_changed.emit(current_health, max_health)
	
	# Print health description for non-player characters
	if not self is Player:
		print(character_name, " ", get_health_description())
	
	if current_health <= 0:
		die()

func get_health_description(show_hp: bool = false) -> String:
	var health_percent = float(current_health) / float(max_health)
	var hp_text = ""
	
	if show_hp:
		hp_text = "(" + str(current_health) + "/" + str(max_health) + " HP) "
	
	if current_health <= 0:
		return hp_text + "lies motionless on the ground, defeated."
	elif health_percent >= 0.95:
		return hp_text + "appears unharmed and ready for battle."
	elif health_percent >= 0.85:
		return hp_text + "has a few minor scratches but looks determined."
	elif health_percent >= 0.7:
		return hp_text + "is barely wounded but still strong."
	elif health_percent >= 0.55:
		return hp_text + "is moderately wounded but fighting on."
	elif health_percent >= 0.4:
		return hp_text + "is bloodied but still fighting strong."
	elif health_percent >= 0.25:
		return hp_text + "is badly wounded and staggering."
	elif health_percent >= 0.1:
		return hp_text + "is barely standing, gasping for breath."
	else:
		return hp_text + "is on the verge of collapse, near death."

func heal(amount: int):
	current_health += amount
	current_health = min(max_health, current_health)
	health_changed.emit(current_health, max_health)

func die():
	print(character_name, " has died!")
	died.emit()

func make_saving_throw(type: String, difficulty_class: int) -> bool:
	var roll = roll_d20()
	var modifier = 0
	
	match type.to_lower():
		"strength":
			modifier = get_modifier(strength)
		"dexterity":
			modifier = get_modifier(dexterity)
		"constitution":
			modifier = get_modifier(constitution)
		"intelligence":
			modifier = get_modifier(intelligence)
		"wisdom":
			modifier = get_modifier(wisdom)
		"charisma":
			modifier = get_modifier(charisma)
	
	var total = roll + modifier
	print("Saving throw (", type, "): ", roll, " + ", modifier, " = ", total, " vs DC ", difficulty_class)
	return total >= difficulty_class

func add_item(item: Item):
	inventory.append(item)

func remove_item(item: Item):
	inventory.erase(item)

func equip_weapon(new_weapon: Item):
	if weapon:
		add_item(weapon)
	weapon = new_weapon
	remove_item(new_weapon)
	update_derived_stats()

func equip_armor(new_armor: Item):
	if armor:
		add_item(armor)
	armor = new_armor
	remove_item(new_armor)
	update_derived_stats()

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
	
	# Emit signal to update UI
	experience_changed.emit(experience, level)
	
	# Return true if we leveled up
	return level > old_level

# Handle a single level-up
func level_up():
	var old_level = level
	level += 1
	
	print("LEVEL UP! ", character_name, " is now level ", level)
	
	# Increase HP based on constitution modifier + base HP per level
	var hp_gain = 6 + get_modifier(constitution)  # Assumes fighter-like progression
	hp_gain = max(1, hp_gain)  # Minimum 1 HP per level
	
	max_health += hp_gain
	current_health += hp_gain  # Heal on level-up
	
	print("HP increased by ", hp_gain, "! New max HP: ", max_health)
	
	# Recalculate all derived stats
	update_derived_stats()
	
	print("Level ", old_level, " -> ", level, " complete!")

# Award XP for various activities
func award_xp_for_exploration() -> int:
	var xp_amount = 50 + level * 10  # Scales with level
	gain_experience(xp_amount)
	return xp_amount

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

func award_xp_for_quest(difficulty_level: int) -> int:
	var base_xp = difficulty_level * 200
	gain_experience(base_xp)
	return base_xp
