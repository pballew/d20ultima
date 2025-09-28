extends Node

# Test script to verify XP UI updating

func _ready():
	print("=== XP UI Test Starting ===")
	
	# Wait for the game to fully load
	await get_tree().create_timer(2.0).timeout
	
	# Find the player and stats UI
	var player = get_tree().get_first_node_in_group("player")
	var stats_ui = get_tree().get_first_node_in_group("player_stats_ui")
	
	if not player:
		print("ERROR: Could not find player node")
		return
		
	if not stats_ui:
		print("ERROR: Could not find stats UI node")
		return
	
	print("Found player: ", player.name)
	print("Found stats UI: ", stats_ui.name)
	
	# Check initial XP
	print("Initial XP: ", player.experience)
	print("Initial Level: ", player.level)
	
	# Test XP gain
	print("Testing XP gain...")
	var initial_xp = player.experience
	
	# Give player some XP
	player.gain_experience(50)
	
	# Wait a moment for UI to update
	await get_tree().create_timer(0.5).timeout
	
	print("After gaining 50 XP:")
	print("Player XP: ", player.experience)
	print("Player Level: ", player.level)
	
	# Test if UI updated (we can check if the method exists)
	if stats_ui.has_method("update_all_stats"):
		print("Stats UI has update_all_stats method")
	else:
		print("WARNING: Stats UI missing update_all_stats method")
	
	print("=== XP UI Test Complete ===")
	
	# Quit after test
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()