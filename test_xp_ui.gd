extends Node

# Test script to verify XP UI updating

func _ready():
	DebugLogger.info("=== XP UI Test Starting ===")
	
	# Wait for the game to fully load
	await get_tree().create_timer(2.0).timeout
	
	# Find the player and stats UI
	var player = get_tree().get_first_node_in_group("player")
	var stats_ui = get_tree().get_first_node_in_group("player_stats_ui")
	
	if not player:
		DebugLogger.error("ERROR: Could not find player node")
		return
		
	if not stats_ui:
		DebugLogger.error("ERROR: Could not find stats UI node")
		return
	
	DebugLogger.info("Found player: %s" % player.name)
	DebugLogger.info("Found stats UI: %s" % stats_ui.name)
	
	# Check initial XP
	DebugLogger.info("Initial XP: %s" % player.experience)
	DebugLogger.info("Initial Level: %s" % player.level)
	
	# Test XP gain
	DebugLogger.info("Testing XP gain...")
	var initial_xp = player.experience
	
	# Give player some XP
	player.gain_experience(50)
	
	# Wait a moment for UI to update
	await get_tree().create_timer(0.5).timeout
	
	DebugLogger.info("After gaining 50 XP:")
	DebugLogger.info("Player XP: %s" % player.experience)
	DebugLogger.info("Player Level: %s" % player.level)
	
	# Test if UI updated (we can check if the method exists)
	if stats_ui.has_method("update_all_stats"):
		DebugLogger.info("Stats UI has update_all_stats method")
	else:
		DebugLogger.warn("WARNING: Stats UI missing update_all_stats method")
	
	DebugLogger.info("=== XP UI Test Complete ===")
	
	# Quit after test
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()