extends Node

# Simple script to generate all player sprites
# Run this in Godot by attaching it to a node and calling generate()

func _ready():
	generate()

func generate():
	DebugLogger.info("Starting sprite generation...")
	
	# Load and create the factory
	var factory_script = load("res://scripts/PlayerIconFactory.cs")
	var factory = factory_script.new()
	
	# Generate and save all sprites
	var count = factory.export_all_player_sprites()
	
	DebugLogger.info(str("Sprite generation complete! Generated ") + " " + str(count) + " " + str(" files."))
	DebugLogger.info("Check the assets/player_sprites/ folder")
	
	# Exit after generation
	get_tree().quit()


