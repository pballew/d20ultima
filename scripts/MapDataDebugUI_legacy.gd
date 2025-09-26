extends Control

var terrain
var info_label: Label

func _ready():
	# Find the terrain node - try different paths
	terrain = get_node_or_null("/root/Main/EnhancedTerrain")
	if not terrain:
		terrain = get_node_or_null("../EnhancedTerrain")
	if not terrain:
		# Try searching for it
		var main = get_tree().get_first_node_in_group("main")
		if main:
			terrain = main.get_node_or_null("EnhancedTerrain")
	
	if not terrain:
		print("Warning: MapDataDebugUI could not find EnhancedTerrain node")
		return
	else:
		print("MapDataDebugUI found terrain node at: ", terrain.get_path())
	
	# Create UI
	setup_ui()
	
	# Update every second
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_display)
	timer.autostart = true
	add_child(timer)

func setup_ui():
	# Main container
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Map Data Debug Info"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	# Info display
	info_label = Label.new()
	info_label.text = "Loading..."
	info_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(info_label)
	
	# Buttons
	var button_container = HBoxContainer.new()
	vbox.add_child(button_container)
	
	var clear_btn = Button.new()
	clear_btn.text = "Clear All Saves"
	clear_btn.pressed.connect(_clear_all_saves)
	button_container.add_child(clear_btn)
	
	var force_save_btn = Button.new()
	force_save_btn.text = "Force Save"
	force_save_btn.pressed.connect(_force_save)
	button_container.add_child(force_save_btn)
	
	# Position in top-right corner
	anchors_preset = Control.PRESET_TOP_RIGHT
	position = Vector2(-200, 10)

func _update_display():
	if not terrain:
		return
	
	var stats = terrain.get_map_save_statistics()
	var saved_sections = terrain.get_saved_sections()
	
	var text = ""
	text += "Sections in Memory: %d\n" % terrain.map_sections.size()
	text += "Current Sections: %d\n" % terrain.current_sections.size()
	text += "Saved Sections: %d\n" % saved_sections.size()
	text += "Total Save Files: %d\n" % stats.get("total_files", 0)
	text += "Total Data Size: %s\n" % _format_bytes(stats.get("total_size", 0))
	
	# Show current sections
	text += "\nCurrent Sections:\n"
	for section_id in terrain.current_sections:
		text += "  (%d, %d)\n" % [section_id.x, section_id.y]
	
	info_label.text = text

func _format_bytes(bytes: int) -> String:
	if bytes < 1024:
		return "%d B" % bytes
	elif bytes < 1024 * 1024:
		return "%.1f KB" % (bytes / 1024.0)
	else:
		return "%.1f MB" % (bytes / (1024.0 * 1024.0))

func _clear_all_saves():
	if terrain:
		terrain.clear_all_saved_maps()

func _force_save():
	if terrain:
		terrain.force_save_current_sections()