extends Control

signal character_created(character_data: CharacterData)
signal character_loaded(character_data: CharacterData)

@onready var name_input = $VBoxContainer/NameContainer/NameLineEdit
@onready var class_option = $VBoxContainer/ClassContainer/ClassOptionButton
@onready var class_description = $VBoxContainer/ClassContainer/ClassDescription
@onready var race_option = $VBoxContainer/RaceContainer/RaceOptionButton
@onready var race_description = $VBoxContainer/RaceContainer/RaceDescription

# Stat containers
@onready var str_label = $VBoxContainer/StatsContainer/StrContainer/StrValue
@onready var dex_label = $VBoxContainer/StatsContainer/DexContainer/DexValue
@onready var con_label = $VBoxContainer/StatsContainer/ConContainer/ConValue
@onready var int_label = $VBoxContainer/StatsContainer/IntContainer/IntValue
@onready var wis_label = $VBoxContainer/StatsContainer/WisContainer/WisValue
@onready var cha_label = $VBoxContainer/StatsContainer/ChaContainer/ChaValue

@onready var str_minus = $VBoxContainer/StatsContainer/StrContainer/StrMinus
@onready var str_plus = $VBoxContainer/StatsContainer/StrContainer/StrPlus
@onready var dex_minus = $VBoxContainer/StatsContainer/DexContainer/DexMinus
@onready var dex_plus = $VBoxContainer/StatsContainer/DexContainer/DexPlus
@onready var con_minus = $VBoxContainer/StatsContainer/ConContainer/ConMinus
@onready var con_plus = $VBoxContainer/StatsContainer/ConContainer/ConPlus
@onready var int_minus = $VBoxContainer/StatsContainer/IntContainer/IntMinus
@onready var int_plus = $VBoxContainer/StatsContainer/IntContainer/IntPlus
@onready var wis_minus = $VBoxContainer/StatsContainer/WisContainer/WisMinus
@onready var wis_plus = $VBoxContainer/StatsContainer/WisContainer/WisPlus
@onready var cha_minus = $VBoxContainer/StatsContainer/ChaContainer/ChaMinus
@onready var cha_plus = $VBoxContainer/StatsContainer/ChaContainer/ChaPlus

@onready var points_remaining = $VBoxContainer/StatsContainer/PointsLabel
@onready var roll_stats_btn = $VBoxContainer/StatsContainer/RollStatsButton
@onready var create_btn = $VBoxContainer/ButtonsContainer/CreateButton
@onready var load_btn = $VBoxContainer/ButtonsContainer/LoadButton

var character_data: CharacterData
var available_points: int = 27  # Point-buy system
var base_stats: Array = [8, 8, 8, 8, 8, 8]  # Starting point-buy values

func _ready():
	setup_character_creation()
	connect_signals()
	update_display()

func setup_character_creation():
	character_data = CharacterData.new()
	
	# Setup class options
	class_option.clear()
	class_option.add_item("Fighter")
	class_option.add_item("Rogue")
	class_option.add_item("Wizard")
	class_option.add_item("Cleric")
	class_option.add_item("Ranger")
	class_option.add_item("Barbarian")
	
	# Setup race options
	race_option.clear()
	race_option.add_item("Human")
	race_option.add_item("Elf")
	race_option.add_item("Dwarf")
	race_option.add_item("Halfling")
	race_option.add_item("Gnome")
	race_option.add_item("Half-Elf")
	race_option.add_item("Half-Orc")
	race_option.add_item("Dragonborn")
	race_option.add_item("Tiefling")
	
	# Set default descriptions
	class_description.text = character_data.get_class_description()
	race_description.text = character_data.get_race_description()
	
	# Set default values
	character_data.strength = base_stats[0]
	character_data.dexterity = base_stats[1]
	character_data.constitution = base_stats[2]
	character_data.intelligence = base_stats[3]
	character_data.wisdom = base_stats[4]
	character_data.charisma = base_stats[5]

func connect_signals():
	class_option.item_selected.connect(_on_class_selected)
	race_option.item_selected.connect(_on_race_selected)
	roll_stats_btn.pressed.connect(_on_roll_stats)
	create_btn.pressed.connect(_on_create_character)
	load_btn.pressed.connect(_on_load_character)
	
	# Connect stat adjustment buttons
	str_minus.pressed.connect(func(): adjust_stat(0, -1))
	str_plus.pressed.connect(func(): adjust_stat(0, 1))
	dex_minus.pressed.connect(func(): adjust_stat(1, -1))
	dex_plus.pressed.connect(func(): adjust_stat(1, 1))
	con_minus.pressed.connect(func(): adjust_stat(2, -1))
	con_plus.pressed.connect(func(): adjust_stat(2, 1))
	int_minus.pressed.connect(func(): adjust_stat(3, -1))
	int_plus.pressed.connect(func(): adjust_stat(3, 1))
	wis_minus.pressed.connect(func(): adjust_stat(4, -1))
	wis_plus.pressed.connect(func(): adjust_stat(4, 1))
	cha_minus.pressed.connect(func(): adjust_stat(5, -1))
	cha_plus.pressed.connect(func(): adjust_stat(5, 1))

func _on_class_selected(index: int):
	character_data.character_class = index as CharacterData.CharacterClass
	class_description.text = character_data.get_class_description()
	update_display()

func _on_race_selected(index: int):
	character_data.character_race = index as CharacterData.CharacterRace
	race_description.text = character_data.get_race_description()
	update_display()

func adjust_stat(stat_index: int, delta: int):
	var current_value = base_stats[stat_index]
	var new_value = current_value + delta
	
	# Point-buy costs: 8-13 costs 1 point each above 8, 14-15 costs 2 points each
	var old_cost = get_stat_cost(current_value)
	var new_cost = get_stat_cost(new_value)
	var cost_difference = new_cost - old_cost
	
	if new_value >= 8 and new_value <= 15 and available_points >= cost_difference:
		base_stats[stat_index] = new_value
		available_points -= cost_difference
		update_character_stats()
		update_display()

func get_stat_cost(value: int) -> int:
	if value <= 8:
		return 0
	elif value <= 13:
		return value - 8
	elif value <= 15:
		return 5 + (value - 13) * 2
	else:
		return 999  # Invalid

func _on_roll_stats():
	# Roll 4d6, drop lowest for each stat
	for i in range(6):
		var rolls = []
		for j in range(4):
			rolls.append(randi_range(1, 6))
		rolls.sort()
		rolls.reverse()  # Highest first
		base_stats[i] = rolls[0] + rolls[1] + rolls[2]  # Sum of 3 highest
	
	available_points = 0  # Disable point-buy when rolling
	update_character_stats()
	update_display()

func update_character_stats():
	character_data.strength = base_stats[0]
	character_data.dexterity = base_stats[1] 
	character_data.constitution = base_stats[2]
	character_data.intelligence = base_stats[3]
	character_data.wisdom = base_stats[4]
	character_data.charisma = base_stats[5]

func update_display():
	# Get racial bonuses for display
	var racial_bonuses = character_data.get_racial_stat_bonuses()
	
	# Display base stats + racial bonuses
	var str_final = base_stats[0] + racial_bonuses["str"]
	var dex_final = base_stats[1] + racial_bonuses["dex"] 
	var con_final = base_stats[2] + racial_bonuses["con"]
	var int_final = base_stats[3] + racial_bonuses["int"]
	var wis_final = base_stats[4] + racial_bonuses["wis"]
	var cha_final = base_stats[5] + racial_bonuses["cha"]
	
	# Show base stats and final stats with racial bonuses
	str_label.text = str(base_stats[0]) + ((" + " + str(racial_bonuses["str"]) + " = " + str(str_final)) if racial_bonuses["str"] > 0 else "")
	dex_label.text = str(base_stats[1]) + ((" + " + str(racial_bonuses["dex"]) + " = " + str(dex_final)) if racial_bonuses["dex"] > 0 else "")
	con_label.text = str(base_stats[2]) + ((" + " + str(racial_bonuses["con"]) + " = " + str(con_final)) if racial_bonuses["con"] > 0 else "")
	int_label.text = str(base_stats[3]) + ((" + " + str(racial_bonuses["int"]) + " = " + str(int_final)) if racial_bonuses["int"] > 0 else "")
	wis_label.text = str(base_stats[4]) + ((" + " + str(racial_bonuses["wis"]) + " = " + str(wis_final)) if racial_bonuses["wis"] > 0 else "")
	cha_label.text = str(base_stats[5]) + ((" + " + str(racial_bonuses["cha"]) + " = " + str(cha_final)) if racial_bonuses["cha"] > 0 else "")
	
	points_remaining.text = "Points Remaining: " + str(available_points)
	
	# Enable/disable buttons based on point-buy
	var using_point_buy = available_points > 0 or (available_points == 0 and base_stats.max() <= 15)
	str_minus.disabled = not using_point_buy or base_stats[0] <= 8 or get_stat_cost(base_stats[0] - 1) < 0
	str_plus.disabled = not using_point_buy or base_stats[0] >= 15 or available_points < (get_stat_cost(base_stats[0] + 1) - get_stat_cost(base_stats[0]))
	dex_minus.disabled = not using_point_buy or base_stats[1] <= 8 or get_stat_cost(base_stats[1] - 1) < 0
	dex_plus.disabled = not using_point_buy or base_stats[1] >= 15 or available_points < (get_stat_cost(base_stats[1] + 1) - get_stat_cost(base_stats[1]))
	con_minus.disabled = not using_point_buy or base_stats[2] <= 8 or get_stat_cost(base_stats[2] - 1) < 0
	con_plus.disabled = not using_point_buy or base_stats[2] >= 15 or available_points < (get_stat_cost(base_stats[2] + 1) - get_stat_cost(base_stats[2]))
	int_minus.disabled = not using_point_buy or base_stats[3] <= 8 or get_stat_cost(base_stats[3] - 1) < 0
	int_plus.disabled = not using_point_buy or base_stats[3] >= 15 or available_points < (get_stat_cost(base_stats[3] + 1) - get_stat_cost(base_stats[3]))
	wis_minus.disabled = not using_point_buy or base_stats[4] <= 8 or get_stat_cost(base_stats[4] - 1) < 0
	wis_plus.disabled = not using_point_buy or base_stats[4] >= 15 or available_points < (get_stat_cost(base_stats[4] + 1) - get_stat_cost(base_stats[4]))
	cha_minus.disabled = not using_point_buy or base_stats[5] <= 8 or get_stat_cost(base_stats[5] - 1) < 0
	cha_plus.disabled = not using_point_buy or base_stats[5] >= 15 or available_points < (get_stat_cost(base_stats[5] + 1) - get_stat_cost(base_stats[5]))

func _on_create_character():
	if name_input.text.strip_edges() == "":
		DebugLogger.info("Please enter a character name")
		return
	
	character_data.character_name = name_input.text.strip_edges()
	character_data.apply_class_bonuses()
	character_data.calculate_derived_stats()
	
	# Save character to disk
	save_character(character_data)
	
	character_created.emit(character_data)

func _on_load_character():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.add_filter("*.tres", "Character Files")
	file_dialog.current_dir = "user://characters/"
	
	add_child(file_dialog)
	file_dialog.file_selected.connect(_on_character_file_selected)
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_character_file_selected(path: String):
	var loaded_character = load(path) as CharacterData
	if loaded_character:
		# Set the UI to match the loaded character
		name_input.text = loaded_character.character_name
		class_option.selected = loaded_character.character_class
		race_option.selected = loaded_character.character_race
		class_description.text = loaded_character.get_class_description()
		race_description.text = loaded_character.get_race_description()
		
		character_loaded.emit(loaded_character)
	else:
		DebugLogger.info(str("Failed to load character from: ") + " " + str(path))

func save_character(char_data: CharacterData):
	# Ensure characters directory exists
	if not DirAccess.dir_exists_absolute("user://characters/"):
		DirAccess.open("user://").make_dir("characters")
	
	var save_path = "user://characters/" + char_data.character_name.to_lower().replace(" ", "_") + ".tres"
	var result = ResourceSaver.save(char_data, save_path)
	
	if result == OK:
		DebugLogger.info(str("Character saved to: ") + " " + str(save_path))
	else:
		DebugLogger.info("Failed to save character!")


