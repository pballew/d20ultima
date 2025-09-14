extends SceneTree

func _init():
	print("Minimal test starting...")
	
	# Simple test without external dependencies
	var pass_count = 0
	var fail_count = 0
	
	# Test 1: Basic arithmetic
	print("Test 1: Basic arithmetic")
	if 2 + 2 == 4:
		print("  PASS")
		pass_count += 1
	else:
		print("  FAIL")
		fail_count += 1
	
	# Test 2: String operations
	print("Test 2: String operations")
	var test_string = "Hello"
	if test_string + " World" == "Hello World":
		print("  PASS")
		pass_count += 1
	else:
		print("  FAIL")
		fail_count += 1
	
	# Test 3: Node creation
	print("Test 3: Node creation")
	var node = Node.new()
	if node != null:
		print("  PASS")
		pass_count += 1
		node.queue_free()
	else:
		print("  FAIL")
		fail_count += 1
	
	print("\nTest Results:")
	print("Passed: " + str(pass_count))
	print("Failed: " + str(fail_count))
	print("Total: " + str(pass_count + fail_count))
	
	if fail_count == 0:
		print("All tests passed!")
	else:
		print("Some tests failed!")
	
	quit()
