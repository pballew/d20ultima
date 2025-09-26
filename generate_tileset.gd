#!/usr/bin/env -S godot -s
# Simple script to run the TileSetGenerator

extends SceneTree

func _init():
	print("Starting TileSet generation...")
	
	# Create and run the generator
	var generator = preload("res://scripts/TileSetGenerator.gd").new()
	generator.generate_tileset()
	
	print("TileSet generation complete!")
	quit()