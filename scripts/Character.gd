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
