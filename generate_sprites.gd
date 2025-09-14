extends Node

# Simple script to generate all player sprites
# Run this in Godot by attaching it to a node and calling generate()

func _ready():
	generate()

func generate():
	print("Starting sprite generation...")
	
	# Load and create the factory
	var factory_script = load("res://scripts/PlayerIconFactory.gd")
	var factory = factory_script.new()
	
	# Generate and save all sprites
	var count = factory.export_all_player_sprites()
	
	print("Sprite generation complete! Generated ", count, " files.")
	print("Check the assets/player_sprites/ folder")
	
	# Exit after generation
	get_tree().quit()
