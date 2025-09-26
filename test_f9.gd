extends Node

func _ready():
	print("=== F9 TEST SCRIPT STARTING ===")
	# Wait for game to fully initialize
	await get_tree().create_timer(5.0).timeout
	
	# Try to simulate pressing F9 key
	print("Simulating F9 key press...")
	var input_event = InputEventKey.new()
	input_event.keycode = KEY_F9
	input_event.pressed = true
	
	# Send to viewport
	get_viewport().push_input(input_event)
	
	# Also try with T key
	await get_tree().create_timer(1.0).timeout
	print("Simulating T key press...")
	var t_event = InputEventKey.new()
	t_event.keycode = KEY_T
	t_event.pressed = true
	get_viewport().push_input(t_event)
	
	# Also try with P key
	await get_tree().create_timer(1.0).timeout
	print("Simulating P key press...")
	var p_event = InputEventKey.new()
	p_event.keycode = KEY_P
	p_event.pressed = true
	get_viewport().push_input(p_event)
	
	print("=== F9 TEST COMPLETE ===")
	
	# Quit after a moment
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()