extends Control

signal town_entered(town_data: Dictionary)
signal dialog_cancelled

@onready var town_label = $DialogPanel/VBoxContainer/TownLabel
@onready var message_label = $DialogPanel/VBoxContainer/MessageLabel

var current_town_data: Dictionary = {}

func _ready():
	# Hide dialog initially
	visible = false
	
	# Ensure dialog appears above other elements
	z_index = 1000
	
	# Allow processing when paused so buttons work
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	print("DEBUG TownDialog: _ready called, z_index set to: ", z_index)
	print("DEBUG TownDialog: process_mode set to PROCESS_MODE_WHEN_PAUSED")

func show_town_dialog(town_data: Dictionary):
	print("DEBUG TownDialog: show_town_dialog called with: ", town_data)
	current_town_data = town_data
	
	var viewport_size = get_viewport().size
	print("DEBUG TownDialog: Viewport size: ", viewport_size)
	
	# Get the camera position to position dialog relative to current view
	var camera_position = Vector2.ZERO
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera_position = camera.get_screen_center_position()
		print("DEBUG TownDialog: Camera center position: ", camera_position)
	else:
		print("DEBUG TownDialog: No camera found, using Vector2.ZERO")
	
	# Position the entire dialog at the camera's view center
	var dialog_screen_pos = camera_position - viewport_size / 2.0
	position = dialog_screen_pos
	size = viewport_size
	
	print("DEBUG TownDialog: Dialog positioned at: ", position)
	print("DEBUG TownDialog: Dialog size: ", size)
	
	# Ensure background fills the dialog area (which now covers the screen)
	var background = $Background
	if background:
		background.position = Vector2.ZERO
		background.size = viewport_size
		background.anchors_preset = Control.PRESET_FULL_RECT
		print("DEBUG TownDialog: Background position: ", background.position)
		print("DEBUG TownDialog: Background size: ", background.size)
	
	if town_data.has("name"):
		town_label.text = "Welcome to " + town_data.name + "!"
		print("DEBUG TownDialog: Set town label to: ", town_label.text)
	else:
		town_label.text = "Welcome to this town!"
		print("DEBUG TownDialog: Set town label to default")
	
	message_label.text = "Do you want to enter the town?"
	print("DEBUG TownDialog: Set message label to: ", message_label.text)
	
	# Dialog is already centered via scene anchoring - no manual positioning needed
	print("DEBUG TownDialog: Dialog using scene-defined centering")
	
	# Check if buttons exist and are connected
	var enter_button = $DialogPanel/VBoxContainer/ButtonContainer/EnterButton
	var cancel_button = $DialogPanel/VBoxContainer/ButtonContainer/CancelButton
	print("DEBUG TownDialog: Enter button found: ", enter_button != null)
	print("DEBUG TownDialog: Cancel button found: ", cancel_button != null)
	if enter_button:
		print("DEBUG TownDialog: Enter button disabled: ", enter_button.disabled)
		# Ensure button can process when paused
		enter_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		# Connect manually as backup
		if not enter_button.pressed.is_connected(_on_enter_button_pressed):
			enter_button.pressed.connect(_on_enter_button_pressed)
			print("DEBUG TownDialog: Manually connected Enter button")
	if cancel_button:
		print("DEBUG TownDialog: Cancel button disabled: ", cancel_button.disabled)
		# Ensure button can process when paused
		cancel_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		# Connect manually as backup
		if not cancel_button.pressed.is_connected(_on_cancel_button_pressed):
			cancel_button.pressed.connect(_on_cancel_button_pressed)
			print("DEBUG TownDialog: Manually connected Cancel button")
	
	visible = true
	print("DEBUG TownDialog: Dialog set to visible: ", visible)
	
	# Center the dialog panel within the dialog area
	var dialog_panel = $DialogPanel
	if dialog_panel:
		var panel_size = Vector2(400, 200)
		
		# Calculate center position within the dialog (which now covers the screen)
		var center_x = (viewport_size.x - panel_size.x) / 2.0
		var center_y = (viewport_size.y - panel_size.y) / 2.0
		
		# Position the panel in the center of the dialog
		dialog_panel.position = Vector2(center_x, center_y)
		dialog_panel.size = panel_size
		
		print("DEBUG TownDialog: Panel centered at: ", dialog_panel.position)
		print("DEBUG TownDialog: Viewport size: ", viewport_size)
		print("DEBUG TownDialog: Panel size: ", panel_size)
	
	# Pause the game while dialog is shown
	get_tree().paused = true
	print("DEBUG TownDialog: Game paused: ", get_tree().paused)

func hide_dialog():
	print("DEBUG TownDialog: hide_dialog() called - hiding dialog and unpausing game")
	visible = false
	get_tree().paused = false
	print("DEBUG TownDialog: Dialog hidden, visible = ", visible, ", paused = ", get_tree().paused)

func _on_enter_button_pressed():
	print("DEBUG TownDialog: Enter button pressed!")
	hide_dialog()
	town_entered.emit(current_town_data)

func _on_cancel_button_pressed():
	print("DEBUG TownDialog: Cancel button pressed!")
	hide_dialog()
	dialog_cancelled.emit()

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel_button_pressed()

func _exit_tree():
	# Disconnect any manually connected signals
	if has_node("DialogPanel/VBoxContainer/ButtonContainer/EnterButton"):
		var enter_button = $DialogPanel/VBoxContainer/ButtonContainer/EnterButton
		if enter_button and is_instance_valid(enter_button) and enter_button.pressed.is_connected(_on_enter_button_pressed):
			enter_button.pressed.disconnect(_on_enter_button_pressed)
	
	if has_node("DialogPanel/VBoxContainer/ButtonContainer/CancelButton"):
		var cancel_button = $DialogPanel/VBoxContainer/ButtonContainer/CancelButton
		if cancel_button and is_instance_valid(cancel_button) and cancel_button.pressed.is_connected(_on_cancel_button_pressed):
			cancel_button.pressed.disconnect(_on_cancel_button_pressed)