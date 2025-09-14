extends Node

func _ready():
	print("Simple test runner starting...")
	
	# Test basic Godot functionality
	var test_count = 0
	var pass_count = 0
	
	# Test 1: Basic node operations
	test_count += 1
	print("Test 1: Node creation and naming")
	var test_node = Node.new()
	test_node.name = "TestNode"
	if test_node.name == "TestNode":
		print("  PASS: Node naming works")
		pass_count += 1
	else:
		print("  FAIL: Node naming failed")
	test_node.free()
	
	# Test 2: String concatenation (this might be causing the original error)
	test_count += 1
	print("Test 2: String concatenation")
	var str1 = "Hello"
	var str2 = "World"
	var result = str1 + " " + str2
	if result == "Hello World":
		print("  PASS: String concatenation works")
		pass_count += 1
	else:
		print("  FAIL: String concatenation failed")
	
	# Test 3: Time functions (this might be the culprit)
	test_count += 1
	print("Test 3: Time functions")
	var unix_time = Time.get_unix_time_from_system()
	if unix_time > 0:
		print("  PASS: Unix time function works")
		pass_count += 1
	else:
		print("  FAIL: Unix time function failed")
	
	# Test 4: DateTime string (this is likely causing the nil + string error)
	test_count += 1
	print("Test 4: DateTime string function")
	var datetime_str = Time.get_datetime_string_from_system()
	if datetime_str != null and datetime_str != "":
		print("  PASS: DateTime string function works: " + str(datetime_str))
		pass_count += 1
	else:
		print("  FAIL: DateTime string function returned null or empty")
		print("  Actual value: " + str(datetime_str))
	
	print("\nTest Summary:")
	print("Tests run: " + str(test_count))
	print("Tests passed: " + str(pass_count))
	print("Tests failed: " + str(test_count - pass_count))
	
	if pass_count == test_count:
		print("All basic tests passed!")
	else:
		print("Some basic tests failed - this may explain the UI test issues")
	
	# Exit
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
