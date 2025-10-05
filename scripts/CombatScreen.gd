extends Control

# CombatScreen UI script (cleaned up)
var combat_manager = null
var msg_label = null
var btn_attack = null
var btn_defend = null
var btn_run = null

func _ready() -> void:
    # Resolve UI nodes at runtime (avoid 'onready' parser issues)
    msg_label = get_node_or_null("VBoxContainer/MessageLabel")
    btn_attack = get_node_or_null("VBoxContainer/HBox/Attack")
    btn_defend = get_node_or_null("VBoxContainer/HBox/Defend")
    btn_run = get_node_or_null("VBoxContainer/HBox/Run")

    # Try common absolute paths first, then fall back to safe lookups
    combat_manager = get_node_or_null("/root/Main/CombatManager")
    if combat_manager == null:
        combat_manager = get_tree().get_root().get_node_or_null("Main/CombatManager")

    # Connect signals if available
    if combat_manager != null:
        if not combat_manager.is_connected("combat_message", self, "_on_combat_message"):
            combat_manager.connect("combat_message", self, "_on_combat_message")
        if not combat_manager.is_connected("turn_changed", self, "_on_turn_changed"):
            combat_manager.connect("turn_changed", self, "_on_turn_changed")

    # Connect buttons defensively using explicit signal names (works reliably)
    if btn_attack:
        btn_attack.connect("pressed", self, "_on_attack_pressed")
    if btn_defend:
        btn_defend.connect("pressed", self, "_on_defend_pressed")
    if btn_run:
        btn_run.connect("pressed", self, "_on_run_pressed")

func _on_combat_message(message: String) -> void:
    msg_label.text = msg_label.text + "%s\n" % message

func _on_turn_changed(current_character) -> void:
    # Enable the action buttons when it's the player's turn (best-effort)
    if btn_attack:
        btn_attack.disabled = false
    if btn_defend:
        btn_defend.disabled = false
    if btn_run:
        btn_run.disabled = false

func _on_attack_pressed() -> void:
    if combat_manager:
        if combat_manager.has_method("ExecutePlayerAction"):
            combat_manager.call("ExecutePlayerAction", "attack")
        elif combat_manager.has_method("execute_player_action"):
            combat_manager.call("execute_player_action", "attack")

func _on_defend_pressed() -> void:
    if combat_manager:
        if combat_manager.has_method("ExecutePlayerAction"):
            combat_manager.call("ExecutePlayerAction", "defend")
        elif combat_manager.has_method("execute_player_action"):
            combat_manager.call("execute_player_action", "defend")

func _on_run_pressed() -> void:
    if combat_manager:
        if combat_manager.has_method("ExecutePlayerAction"):
            combat_manager.call("ExecutePlayerAction", "run")
        elif combat_manager.has_method("execute_player_action"):
            combat_manager.call("execute_player_action", "run")
