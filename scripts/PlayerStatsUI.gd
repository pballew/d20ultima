extends Control

@onready var toggle_button = $VBoxContainer/ToggleButton
@onready var name_label = $VBoxContainer/NameLabel
@onready var level_label = $VBoxContainer/LevelLabel
@onready var health_bar = $VBoxContainer/HealthContainer/HealthBar
@onready var health_label = $VBoxContainer/HealthContainer/HealthLabel
@onready var experience_bar = $VBoxContainer/ExperienceContainer/ExperienceBar
@onready var experience_label = $VBoxContainer/ExperienceContainer/ExperienceLabel

# Stat labels
@onready var strength_label = $VBoxContainer/StatsContainer/StrengthLabel
@onready var dexterity_label = $VBoxContainer/StatsContainer/DexterityLabel
@onready var constitution_label = $VBoxContainer/StatsContainer/ConstitutionLabel
@onready var intelligence_label = $VBoxContainer/StatsContainer/IntelligenceLabel
@onready var wisdom_label = $VBoxContainer/StatsContainer/WisdomLabel
@onready var charisma_label = $VBoxContainer/StatsContainer/CharismaLabel

@onready var armor_class_label = $VBoxContainer/CombatContainer/ArmorClassLabel
@onready var attack_bonus_label = $VBoxContainer/CombatContainer/AttackBonusLabel

var player: Character
var stats_visible: bool = true

func _ready():
	if toggle_button:
		toggle_button.pressed.connect(_on_toggle_pressed)

func setup_player_stats(p: Character):
	player = p
	if player:
		# Only connect signal if not already connected
		if not player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.connect(_on_player_health_changed)
		update_all_stats()

func update_all_stats():
	if not player:
		return
	
	# Basic info
	name_label.text = player.character_name
	level_label.text = "Level: " + str(player.level)
	
	# Health
	health_label.text = str(player.current_health) + "/" + str(player.max_health)
	health_bar.value = float(player.current_health) / float(player.max_health) * 100.0
	
	# Experience (for future use)
	experience_label.text = "XP: " + str(player.experience)
	experience_bar.value = float(player.experience % 1000) / 10.0  # Simple XP bar
	
	# Core stats with modifiers
	strength_label.text = "STR: " + str(player.strength) + " (" + format_modifier(player.get_modifier(player.strength)) + ")"
	dexterity_label.text = "DEX: " + str(player.dexterity) + " (" + format_modifier(player.get_modifier(player.dexterity)) + ")"
	constitution_label.text = "CON: " + str(player.constitution) + " (" + format_modifier(player.get_modifier(player.constitution)) + ")"
	intelligence_label.text = "INT: " + str(player.intelligence) + " (" + format_modifier(player.get_modifier(player.intelligence)) + ")"
	wisdom_label.text = "WIS: " + str(player.wisdom) + " (" + format_modifier(player.get_modifier(player.wisdom)) + ")"
	charisma_label.text = "CHA: " + str(player.charisma) + " (" + format_modifier(player.get_modifier(player.charisma)) + ")"
	
	# Combat stats
	armor_class_label.text = "AC: " + str(player.armor_class)
	attack_bonus_label.text = "Attack: +" + str(player.attack_bonus + player.get_modifier(player.strength))

func format_modifier(modifier: int) -> String:
	if modifier >= 0:
		return "+" + str(modifier)
	else:
		return str(modifier)

func _on_player_health_changed(new_health: int, max_health: int):
	health_label.text = str(new_health) + "/" + str(max_health)
	health_bar.value = float(new_health) / float(max_health) * 100.0
	
	# Change health bar color based on health percentage
	var health_percent = float(new_health) / float(max_health)
	if health_percent > 0.6:
		health_bar.modulate = Color.GREEN
	elif health_percent > 0.3:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED

func _on_toggle_pressed():
	stats_visible = !stats_visible
	
	# Toggle visibility of all stat elements except the button
	for child in $VBoxContainer.get_children():
		if child != toggle_button:
			child.visible = stats_visible
	
	# Update button text with arrows
	if stats_visible:
		toggle_button.text = "▲"  # Up arrow when stats are visible (click to hide)
	else:
		toggle_button.text = "▼"  # Down arrow when stats are hidden (click to show)
	
	# Reposition and resize the panel
	if stats_visible:
		# Restore original position (right side, middle)
		anchors_preset = 6  # Right center
		anchor_left = 1.0
		anchor_top = 0.5
		anchor_right = 1.0
		anchor_bottom = 0.5
		offset_left = -200.0
		offset_top = -300.0
		offset_right = -10.0
		offset_bottom = 300.0
	else:
		# Move to top right corner and make smaller
		anchors_preset = 2  # Top right
		anchor_left = 1.0
		anchor_top = 0.0
		anchor_right = 1.0
		anchor_bottom = 0.0
		offset_left = -40.0
		offset_top = 10.0
		offset_right = -10.0
		offset_bottom = 35.0
