extends Control

@onready var action_buttons = $VBoxContainer/ActionButtons
@onready var attack_button = $VBoxContainer/ActionButtons/AttackButton
@onready var retreat_button = $VBoxContainer/ActionButtons/RetreatButton
# Combat log UI elements removed — combat messages will be logged to console only
@onready var panel = $Panel
@onready var vbox_container = $VBoxContainer

# Placeholders for removed combat log UI elements (kept as null-safe stubs)
var combat_log = null
var combat_log_container = null
var log_toggle_button = null

var player: Player
var combat_manager: CombatManager
var current_enemies: Array = []
var log_visible: bool = false

func _ready():
	# Only hide action buttons initially, keep log toggle available
	if action_buttons:
		action_buttons.hide()
	if attack_button:
		attack_button.pressed.connect(_on_attack_pressed)
	if retreat_button:
		retreat_button.pressed.connect(_on_retreat_pressed)
	# Log toggle removed; player toggles do nothing now
	
	# Set smaller font size and reduce vertical spacing for combat log
	if combat_log:
		combat_log.add_theme_font_size_override("font_size", 10)
		combat_log.add_theme_constant_override("line_spacing", -2)
	
	# Combat log UI removed — keep internal flag false
	log_visible = false

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

	# Show combat action buttons; combat messages will be printed to console
	show()
	action_buttons.show()

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
		# If the combat log UI does not exist, just log defeat to console.
		# Otherwise, avoid adding a duplicate "Defeat!" if the last message was a retreat.
		if combat_log and combat_log.text and combat_log.text.contains("retreat"):
			# retreat already logged, do nothing
			pass
		else:
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

	# Combat UI remains, but the combat log UI elements are removed — nothing to destroy

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
	# With the combat log removed, route messages to console
	if message == "CLEAR_LOG":
		print("[COMBAT LOG CLEARED]")
	else:
		add_combat_log(message)

func add_combat_log(text: String):
	# Console-only fallback: print the combat message so game logic still records events
	print("[COMBAT] ", text)

func _on_log_toggle_pressed():
	log_visible = !log_visible
	# Safely update display without touching destroyed nodes
	update_log_toggle_display()

func update_log_toggle_display():
	# Update the toggle button text even if the log container was destroyed.
	if log_toggle_button:
		log_toggle_button.text = ("▼ Combat Log" if log_visible else "▶ Combat Log")

	# If the combat log container doesn't exist (destroyed), avoid touching it and other UI pieces.
	if not combat_log_container:
		# Just update the button text and internal flag; safe exit.
		print("COMBAT LOG: ", ("SHOWN" if log_visible else "HIDDEN"))
		return

	# At this point, combat_log_container exists and it's safe to set visual properties.
	if log_visible:
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
		combat_log_container.visible = false
		combat_log_container.custom_minimum_size = Vector2(0, 0)
		combat_log_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Shrink panel to just show buttons, or hide it entirely if no combat
		if panel:
			if action_buttons and action_buttons.visible:
				# Combat is active, show smaller panel for buttons only
				panel.visible = true
				panel.offset_top = -80.0
			else:
				# No combat, hide the panel entirely
				panel.visible = false
		if vbox_container:
			vbox_container.offset_top = -60.0
		print("COMBAT LOG: HIDDEN")

# Permanently destroy the combat log UI so it can be recreated later
func destroy_combat_log():
	if combat_log and is_instance_valid(combat_log):
		combat_log.queue_free()
	# Also clear any children from the container so it's empty
	if combat_log_container and is_instance_valid(combat_log_container):
		for child in combat_log_container.get_children():
			child.queue_free()
	combat_log = null
	combat_log_container = null

# Rebuild the combat log UI from scratch (used when loading a map/game)
func build_combat_log():
	# Ensure the VBoxContainer exists
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		add_child(vbox)

	var container = vbox.get_node_or_null("CombatLogContainer")
	if not container:
		container = VBoxContainer.new()
		container.name = "CombatLogContainer"
		vbox.add_child(container)

	var label = container.get_node_or_null("CombatLog")
	if not label:
		label = Label.new()
		label.name = "CombatLog"
		label.autowrap = true
		container.add_child(label)

	# Re-assign references
	combat_log = label
	combat_log_container = container

	# Restore default visual settings
	if combat_log:
		combat_log.add_theme_font_size_override("font_size", 10)
		combat_log.add_theme_constant_override("line_spacing", -2)

	# Ensure container has reasonable size; visibility will be handled by show_combat
	if combat_log_container:
		combat_log_container.custom_minimum_size = Vector2(0, 240)
