extends Node

# Simple test to verify town generation works

func _ready():
	print("=== TOWN GENERATION TEST ===")
	
	# Test the town name generator
	var TownNameGen = load("res://scripts/TownNameGenerator.gd")
	
	for i in range(5):
		var town_name = TownNameGen.generate_town_name(i)
		print("Generated town name: ", town_name)
	
	# Test town data generation
	var town_data = TownNameGen.generate_town_data(Vector2i(10, 10), 12345)
	print("Generated town data: ", town_data)
	
	print("=== TOWN TEST COMPLETE ===")