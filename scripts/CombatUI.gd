extends Control

@onready var combat_log = $VBoxContainer/CombatLogContainer/CombatLog
@onready var combat_log_container = $VBoxContainer/CombatLogContainer
@onready var action_buttons = $VBoxContainer/ActionButtons
@onready var attack_button = $VBoxContainer/ActionButtons/AttackButton
@onready var retreat_button = $VBoxContainer/ActionButtons/RetreatButton
@onready var log_toggle_button = $VBoxContainer/LogToggleContainer/LogToggleButton
@onready var panel = $Panel
@onready var vbox_container = $VBoxContainer

var player: Player
var combat_manager: CombatManager
var current_enemies: Array = []
var log_visible: bool = true

func _ready():
	# Only hide action buttons initially, keep log toggle available
	if action_buttons:
		action_buttons.hide()
	if attack_button:
		attack_button.pressed.connect(_on_attack_pressed)
	if retreat_button:
		retreat_button.pressed.connect(_on_retreat_pressed)
	if log_toggle_button:
		log_toggle_button.pressed.connect(_on_log_toggle_pressed)
	
	# Set smaller font size and reduce vertical spacing for combat log
	if combat_log:
		combat_log.add_theme_font_size_override("font_size", 14)
		combat_log.add_theme_constant_override("line_spacing", -2)
	
	# Initially show the log
	log_visible = true
	combat_log_container.custom_minimum_size = Vector2(0, 240)

# Method to hide combat action buttons when combat is not in progress, but keep log visible
func force_hide_combat_ui():
	if action_buttons.visible:
		print("Hiding combat action buttons - combat not in progress")
		action_buttons.hide()
		current_enemies.clear()

# Check if combat action buttons should be visible based on combat state
func validate_visibility():
	if player and player.has_method("get") and not player.get("is_in_combat"):
		force_hide_combat_ui()

func setup_combat_ui(p: Player, cm: CombatManager):
	player = p
	combat_manager = cm
	
	# Connect signals only if not already connected
	if not player.health_changed.is_connected(_on_player_health_changed):
		player.health_changed.connect(_on_player_health_changed)
	if not combat_manager.turn_changed.is_connected(_on_turn_changed):
		combat_manager.turn_changed.connect(_on_turn_changed)
	if not combat_manager.combat_finished.is_connected(_on_combat_finished):
		combat_manager.combat_finished.connect(_on_combat_finished)
	if not combat_manager.combat_message.is_connected(_on_combat_message):
		combat_manager.combat_message.connect(_on_combat_message)

func show_combat(enemies: Array):
	current_enemies = enemies
	
	# Auto-show the combat log when combat begins
	if not log_visible:
		log_visible = true
		update_log_toggle_display()
		print("COMBAT LOG: Auto-shown for new combat")
	
	# Don't clear the combat log here - the CombatManager has already sent initial messages
	# The combat_message signal has populated the log with initiative and combat info
	show()
	action_buttons.show()  # Ensure action buttons are visible for new combat

# Player and enemy health changes are now handled by combat log messages
func _on_player_health_changed(new_health: int, max_health: int):
	# Health changes will be logged via combat messages
	pass

func _on_enemy_health_changed(new_health: int, max_health: int):
	# Health changes will be logged via combat messages
	pass

func _on_turn_changed(current_character: Character):
	var is_player_turn = current_character is Player
	action_buttons.visible = is_player_turn
	
	# Turn messages are now handled by CombatManager via combat_message signal

func _on_combat_finished(player_won: bool):
	if player_won:
		add_combat_log("Victory!")
	else:
		# Check if this was a retreat (last message contains "retreat")
		var last_message = combat_log.text.split("\n")[-2] if combat_log.text.contains("retreat") else ""
		if not last_message.contains("retreat"):
			add_combat_log("Defeat!")
		# If it was a retreat, the retreat message is already shown
	
	# Clear enemy references to prevent accessing freed objects
	current_enemies.clear()
	
	# Hide only action buttons after combat, keep log visible
	await get_tree().create_timer(1.0).timeout
	action_buttons.hide()
	
	# Ensure player exits combat state
	if player and player.has_method("exit_combat"):
		player.exit_combat()

func _on_attack_pressed():
	if current_enemies.size() > 0:
		# For simplicity, attack the first alive enemy
		var alive_enemies = current_enemies.filter(func(e): return is_instance_valid(e) and e.current_health > 0)
		if alive_enemies.size() > 0:
			var target = alive_enemies[0]
			combat_manager.player_attack(target)

func _on_retreat_pressed():
	combat_manager.player_retreat()

func _on_combat_message(message: String):
	if message == "CLEAR_LOG":
		combat_log.text = ""
	else:
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

func _on_log_toggle_pressed():
	log_visible = !log_visible
	update_log_toggle_display()

func update_log_toggle_display():
	if log_visible:
		log_toggle_button.text = "▼ Combat Log"
		combat_log_container.visible = true
		combat_log_container.custom_minimum_size = Vector2(0, 240)
		combat_log_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# Show full panel
		if panel:
			panel.visible = true
			panel.offset_top = -300.0
		if vbox_container:
			vbox_container.offset_top = -280.0
		print("COMBAT LOG: SHOWN")
	else:
		log_toggle_button.text = "▶ Combat Log"
		combat_log_container.visible = false
		combat_log_container.custom_minimum_size = Vector2(0, 0)
		combat_log_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Shrink panel to just show buttons, or hide it entirely if no combat
		if panel:
			if action_buttons.visible:
				# Combat is active, show smaller panel for buttons only
				panel.visible = true
				panel.offset_top = -80.0
			else:
				# No combat, hide the panel entirely
				panel.visible = false
		if vbox_container:
			vbox_container.offset_top = -60.0
		print("COMBAT LOG: HIDDEN")
