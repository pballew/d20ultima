extends RefCounted
class_name UITestFramework

# UI Test Framework for automated testing of game UI components
# This framework provides utilities for simulating user interactions and validating UI states

static var test_results: Array[Dictionary] = []
static var current_test_name: String = ""

# Test result tracking
enum TestResult { PASS, FAIL, SKIP }

# Start a new test
static func start_test(test_name: String):
	if test_name == null or test_name == "":
		test_name = "Unnamed Test"
	current_test_name = test_name
	print("Starting test: ", test_name)

# End current test and record result
static func end_test(result: TestResult, message: String = ""):
	if current_test_name == null or current_test_name == "":
		current_test_name = "Unnamed Test"
	
	var test_data = {
		"name": current_test_name,
		"result": result,
		"message": message,
		"timestamp": Time.get_unix_time_from_system()
	}
	test_results.append(test_data)
	
	var result_text = "PASS" if result == TestResult.PASS else ("FAIL" if result == TestResult.FAIL else "SKIP")
	print("Test ", current_test_name, ": ", result_text)
	if message != "":
		print("  Message: ", message)

# Assert functions
static func assert_true(condition: bool, error_message: String = "Assertion failed"):
	if not condition:
		end_test(TestResult.FAIL, error_message)
		return false
	return true

static func assert_false(condition: bool, error_message: String = "Assertion failed"):
	return assert_true(not condition, error_message)

static func assert_equal(expected, actual, error_message: String = "Values not equal"):
	var result = expected == actual
	if not result:
		var msg = "%s - Expected: %s, Actual: %s" % [error_message, str(expected), str(actual)]
		end_test(TestResult.FAIL, msg)
	return result

static func assert_not_null(value, error_message: String = "Value is null"):
	return assert_true(value != null, error_message)

static func assert_null(value, error_message: String = "Value is not null"):
	return assert_true(value == null, error_message)

# UI interaction helpers
static func click_button(button: Button) -> bool:
	if not button or not button.is_visible_in_tree():
		return false
	
	if button.disabled:
		return false
	
	# Simulate button press
	button.pressed.emit()
	return true

static func set_line_edit_text(line_edit: LineEdit, text: String) -> bool:
	if not line_edit or not line_edit.is_visible_in_tree():
		return false
	
	line_edit.text = text
	line_edit.text_changed.emit(text)
	return true

static func get_label_text(label: Label) -> String:
	if not label:
		return ""
	return label.text

static func is_control_visible(control: Control) -> bool:
	if not control:
		return false
	return control.is_visible_in_tree()

static func wait_frames(scene_tree: SceneTree, frames: int = 1):
	for i in range(frames):
		await scene_tree.process_frame

static func wait_seconds(scene_tree: SceneTree, seconds: float):
	await scene_tree.create_timer(seconds).timeout

# Find controls by name pattern
static func find_control_by_name(root: Node, name_pattern: String) -> Control:
	for child in root.get_children():
		if child.name.find(name_pattern) != -1 and child is Control:
			return child as Control
		
		var found = find_control_by_name(child, name_pattern)
		if found:
			return found
	
	return null

# Find buttons by text
static func find_button_by_text(root: Node, button_text: String) -> Button:
	for child in root.get_children():
		if child is Button and (child as Button).text == button_text:
			return child as Button
		
		var found = find_button_by_text(child, button_text)
		if found:
			return found
	
	return null

# Simulate key press
static func simulate_key_press(viewport: Viewport, keycode: Key, pressed: bool = true):
	var event = InputEventKey.new()
	event.keycode = keycode
	event.pressed = pressed
	viewport.push_input(event)

# Generate test report
static func generate_report() -> String:
	var report = "UI Test Report\n"
	report += "=" * 50 + "\n"
	report += "Test run completed at: " + Time.get_datetime_string_from_system() + "\n\n"
	
	var pass_count = 0
	var fail_count = 0
	var skip_count = 0
	
	for test in test_results:
		match test.result:
			TestResult.PASS:
				pass_count += 1
				report += "✓ PASS: " + test.name + "\n"
			TestResult.FAIL:
				fail_count += 1
				report += "✗ FAIL: " + test.name
				if test.message != "":
					report += " - " + test.message
				report += "\n"
			TestResult.SKIP:
				skip_count += 1
				report += "- SKIP: " + test.name + "\n"
	
	report += "\n" + "=" * 50 + "\n"
	report += "Total Tests: %d\n" % test_results.size()
	report += "Passed: %d\n" % pass_count
	report += "Failed: %d\n" % fail_count
	report += "Skipped: %d\n" % skip_count
	report += "Success Rate: %.1f%%\n" % (float(pass_count) / test_results.size() * 100.0 if test_results.size() > 0 else 0.0)
	
	return report

# Clear test results
static func clear_results():
	test_results.clear()
	current_test_name = ""
