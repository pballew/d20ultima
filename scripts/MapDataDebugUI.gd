extends Control

# Minimal stub for MapDataDebugUI so scenes referencing it don't error if the full script is missing.
# Add UI logic here later as needed.

func _ready():
	# Keep the UI hidden by default; it's optional in the project
	visible = false
	set_process(false)

func show_map_debug(info: Dictionary) -> void:
	# Placeholder for showing debug info
	visible = true

func hide_map_debug() -> void:
	visible = false
	set_process(false)
