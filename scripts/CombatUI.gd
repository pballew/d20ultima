extends Control

@onready var player_health_label = $VBoxContainer/PlayerStats/HealthLabel
@onready var player_stats_label = $VBoxContainer/PlayerStats/StatsLabel
@onready var enemy_container = $VBoxContainer/EnemyStats/EnemyContainer
@onready var combat_log = $VBoxContainer/CombatLogContainer/CombatLog
@onready var combat_log_container = $VBoxContainer/CombatLogContainer
@onready var action_buttons = $VBoxContainer/ActionButtons
@onready var attack_button = $VBoxContainer/ActionButtons/AttackButton
@onready var defend_button = $VBoxContainer/ActionButtons/DefendButton

var player: Player
var combat_manager: CombatManager
var current_enemies: Array = []

func _ready():
	hide()
	attack_button.pressed.connect(_on_attack_pressed)
	defend_button.pressed.connect(_on_defend_pressed)

func setup_combat_ui(p: Player, cm: CombatManager):
	player = p
	combat_manager = cm
	
	player.health_changed.connect(_on_player_health_changed)
	combat_manager.turn_changed.connect(_on_turn_changed)
	combat_manager.combat_finished.connect(_on_combat_finished)
	combat_manager.combat_message.connect(_on_combat_message)

func show_combat(enemies: Array):
	current_enemies = enemies
	create_enemy_health_displays()
	update_ui()
	
	show()

func create_enemy_health_displays():
	# Clear existing enemy displays
	for child in enemy_container.get_children():
		child.queue_free()
	
	# Create health displays for each enemy
	for i in range(current_enemies.size()):
		var enemy = current_enemies[i]
		var enemy_label = RichTextLabel.new()
		enemy_label.name = "Enemy" + str(i) + "Label"
		enemy_label.custom_minimum_size = Vector2(0, 25)
		enemy_label.fit_content = true
		enemy_label.scroll_active = false
		enemy_container.add_child(enemy_label)
		
		# Connect to enemy health changes
		if not enemy.health_changed.is_connected(_on_enemy_health_changed):
			enemy.health_changed.connect(_on_enemy_health_changed)
	
	update_enemy_displays()

func update_enemy_displays():
	var labels = enemy_container.get_children()
	for i in range(min(current_enemies.size(), labels.size())):
		var enemy = current_enemies[i]
		var label = labels[i]
		
		if is_instance_valid(enemy):
			if enemy.current_health <= 0:
				label.text = enemy.character_name + " (Defeated)"
			else:
				label.text = enemy.character_name
			label.visible = true

func update_ui():
	if player:
		player_stats_label.text = "AC: %d | Level: %d" % [player.armor_class, player.level]
	
	update_enemy_displays()

func _on_player_health_changed(new_health: int, max_health: int):
	update_ui()

func _on_enemy_health_changed(new_health: int, max_health: int):
	update_enemy_displays()

func _on_turn_changed(current_character: Character):
	var is_player_turn = current_character is Player
	action_buttons.visible = is_player_turn
	
	if is_player_turn:
		add_combat_log(current_character.character_name + "'s turn")
	else:
		add_combat_log(current_character.character_name + "'s turn")

func _on_combat_finished(player_won: bool):
	if player_won:
		add_combat_log("Victory!")
	else:
		add_combat_log("Defeat!")
	
	# Clear enemy references to prevent accessing freed objects
	current_enemies.clear()
	
	# Clear enemy health displays
	for child in enemy_container.get_children():
		child.queue_free()
	
	# Hide combat UI after a delay
	await get_tree().create_timer(2.0).timeout
	hide()

func _on_attack_pressed():
	if current_enemies.size() > 0:
		# For simplicity, attack the first alive enemy
		var alive_enemies = current_enemies.filter(func(e): return is_instance_valid(e) and e.current_health > 0)
		if alive_enemies.size() > 0:
			var target = alive_enemies[0]
			combat_manager.player_attack(target)

func _on_defend_pressed():
	combat_manager.player_defend()

func _on_combat_message(message: String):
	add_combat_log(message)

func add_combat_log(text: String):
	combat_log.text += text + "\n"
	# Limit log size
	var lines = combat_log.text.split("\n")
	if lines.size() > 20:
		lines = lines.slice(-20)
		combat_log.text = "\n".join(lines)
	
	# Auto-scroll to bottom
	await get_tree().process_frame
	combat_log_container.scroll_vertical = combat_log_container.get_v_scroll_bar().max_value
