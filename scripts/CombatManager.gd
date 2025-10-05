
"""
Minimal compatibility shim for CombatManager used while the C# implementation is in development.
This GDScript adds a small `start_combat` entry point and common signals so existing GDScript scenes
can call the same API expected from the C# version.
"""
extends Node

# Signals used by UI
signal combat_message(message)
signal turn_changed(current_character)
signal combat_finished(player_won: bool)

func _ready() -> void:
    # No-op; real logic lives in the C# implementation when Mono is enabled.
    return

func start_combat(player, enemies) -> void:
    # Best-effort shim: emit a message and a turn_changed signal for the player
    emit_signal("combat_message", "A wild creature appears!")
    emit_signal("turn_changed", player)

func StartCombat(player, enemies) -> void:
    # Alias for C#-style method name
    return start_combat(player, enemies)

func startCombat(player, enemies) -> void:
    # Additional camelCase alias
    return start_combat(player, enemies)

func ExecutePlayerAction(action: String, target = null) -> void:
    # Compatibility entrypoint: mirror the C# method name and a snake_case variant
    emit_signal("combat_message", "Player action: %s" % action)
    # Immediately end combat for stub behavior
    emit_signal("combat_finished", true)

func execute_player_action(action: String, target = null) -> void:
    # snake_case alias
    return ExecutePlayerAction(action, target)
