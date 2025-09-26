extends Control

@onready var coordinate_label = $CoordinateLabel

var player: Player = null

func _ready():
	# Find the player node - it's in GameController/GameScene/Player
	var main_scene = get_tree().get_first_node_in_group("main")
	if main_scene:
		player = main_scene.get_node("Player")
	
	if not player:
		# Try alternative paths to find player
		player = get_tree().get_first_node_in_group("player")
	
	if not player:
		# Try direct path from GameController
		var game_controller = get_tree().get_nodes_in_group("game_controller")
		if game_controller.size() > 0:
			var game_scene = game_controller[0].get_node_or_null("GameScene")
			if game_scene:
				player = game_scene.get_node_or_null("Player")
	
	if player:
		# Connect to player's movement signals if available
		if player.has_signal("movement_finished"):
			if not player.movement_finished.is_connected(_on_player_moved):
				player.movement_finished.connect(_on_player_moved)
		print("CoordinateOverlay connected to player")
	else:
		print("CoordinateOverlay: Could not find player node")

func _process(delta):
	# Update coordinates every frame if we have a player
	if player:
		update_coordinate_display()

func update_coordinate_display():
	if player:
		var world_pos = player.global_position
		var tile_pos = Vector2i(int(world_pos.x / 32), int(world_pos.y / 32))
		
		coordinate_label.text = "World: (%.0f, %.0f)\nTile: (%d, %d)" % [
			world_pos.x, world_pos.y,
			tile_pos.x, tile_pos.y
		]

func _on_player_moved():
	# Update coordinates when player finishes moving
	update_coordinate_display()

func update_coordinates(tile_position: Vector2):
	"""Update coordinates display with given tile position"""
	var world_pos = Vector2(tile_position.x * 32, tile_position.y * 32)
	coordinate_label.text = "World: (%.0f, %.0f)\nTile: (%d, %d)" % [
		world_pos.x, world_pos.y,
		int(tile_position.x), int(tile_position.y)
	]

func set_player_reference(player_node: Player):
	"""Manually set player reference if automatic detection fails"""
	player = player_node
	if player.has_signal("movement_finished"):
		if not player.movement_finished.is_connected(_on_player_moved):
			player.movement_finished.connect(_on_player_moved)
	print("CoordinateOverlay: Player reference set manually")