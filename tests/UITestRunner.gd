extends Node

# UI Test Runner
# Orchestrates all UI tests and generates comprehensive reports

var test_classes = [
	"res://tests/MainMenuTests.gd",
	"res://tests/CombatUITests.gd", 
	"res://tests/PlayerStatsUITests.gd",
	"res://tests/GameFlowUITests.gd"
]

func _ready():
	print("UI Test Runner Starting...")
	print("=" * 60)
	run_all_test_suites()

func run_all_test_suites():
	var start_time = Time.get_unix_time_from_system()
	
	# Clear any previous results
	UITestFramework.clear_results()
	
	for test_class_path in test_classes:
		await run_test_suite(test_class_path)
		
		# Wait between test suites
		await UITestFramework.wait_seconds(get_tree(), 1.0)
	
	var end_time = Time.get_unix_time_from_system()
	var total_time = end_time - start_time
	
	# Generate comprehensive report
	generate_comprehensive_report(total_time)
	
	print("=" * 60)
	print("All UI tests completed!")
	
	# Exit after tests
	await UITestFramework.wait_seconds(get_tree(), 2.0)
	get_tree().quit()

func run_test_suite(test_class_path: String):
	print("\nRunning test suite: ", test_class_path)
	print("-" * 40)
	
	var test_script = load(test_class_path)
	if not test_script:
		print("ERROR: Could not load test script: ", test_class_path)
		return
	
	var test_instance = test_script.new()
	add_child(test_instance)
	
	# Wait for test to complete
	var timeout = 30.0  # 30 second timeout per test suite
	var start_time = Time.get_unix_time_from_system()
	
	while test_instance and is_instance_valid(test_instance):
		await UITestFramework.wait_frames(get_tree(), 10)
		
		var current_time = Time.get_unix_time_from_system()
		if current_time - start_time > timeout:
			print("WARNING: Test suite timed out: ", test_class_path)
			break
	
	if test_instance and is_instance_valid(test_instance):
		test_instance.queue_free()

func generate_comprehensive_report(total_time: float):
	var report = "\n" + "=" * 80 + "\n"
	report += "COMPREHENSIVE UI TEST REPORT\n"
	report += "=" * 80 + "\n"
	report += "Test run completed at: " + Time.get_datetime_string_from_system() + "\n"
	report += "Total execution time: %.2f seconds\n" % total_time
	report += "\n"
	
	# Count results by test suite
	var suite_results = {}
	var total_pass = 0
	var total_fail = 0
	var total_skip = 0
	
	for test in UITestFramework.test_results:
		if test == null or not test.has("name") or test.name == null:
			continue
			
		var suite_name = extract_suite_name(test.name)
		
		if not suite_results.has(suite_name):
			suite_results[suite_name] = {"pass": 0, "fail": 0, "skip": 0, "tests": []}
		
		suite_results[suite_name].tests.append(test)
		
		match test.result:
			UITestFramework.TestResult.PASS:
				suite_results[suite_name].pass += 1
				total_pass += 1
			UITestFramework.TestResult.FAIL:
				suite_results[suite_name].fail += 1
				total_fail += 1
			UITestFramework.TestResult.SKIP:
				suite_results[suite_name].skip += 1
				total_skip += 1
	
	# Generate suite-by-suite breakdown
	for suite_name in suite_results.keys():
		var suite = suite_results[suite_name]
		report += "Test Suite: " + suite_name + "\n"
		report += "-" * 40 + "\n"
		report += "  Passed: %d\n" % suite.pass
		report += "  Failed: %d\n" % suite.fail
		report += "  Skipped: %d\n" % suite.skip
		
		if suite.fail > 0:
			report += "  Failed Tests:\n"
			for test in suite.tests:
				if test.result == UITestFramework.TestResult.FAIL:
					report += "    ✗ " + test.name
					if test.message != "":
						report += " - " + test.message
					report += "\n"
		
		var suite_success_rate = float(suite.pass) / (suite.pass + suite.fail + suite.skip) * 100.0 if (suite.pass + suite.fail + suite.skip) > 0 else 0.0
		report += "  Success Rate: %.1f%%\n" % suite_success_rate
		report += "\n"
	
	# Overall summary
	report += "=" * 80 + "\n"
	report += "OVERALL SUMMARY\n"
	report += "=" * 80 + "\n"
	report += "Total Tests: %d\n" % UITestFramework.test_results.size()
	report += "Passed: %d\n" % total_pass
	report += "Failed: %d\n" % total_fail
	report += "Skipped: %d\n" % total_skip
	
	var overall_success_rate = float(total_pass) / UITestFramework.test_results.size() * 100.0 if UITestFramework.test_results.size() > 0 else 0.0
	report += "Overall Success Rate: %.1f%%\n" % overall_success_rate
	
	# Test quality assessment
	report += "\nTEST QUALITY ASSESSMENT:\n"
	if overall_success_rate >= 95.0:
		report += "✅ EXCELLENT - UI is highly stable and functional\n"
	elif overall_success_rate >= 85.0:
		report += "✅ GOOD - UI is mostly functional with minor issues\n"
	elif overall_success_rate >= 70.0:
		report += "⚠️  FAIR - UI has several issues that need attention\n"
	else:
		report += "❌ POOR - UI has major issues requiring immediate fixes\n"
	
	# Coverage analysis
	report += "\nCOVERAGE ANALYSIS:\n"
	var covered_areas = []
	if has_tests_for_area("Main Menu"):
		covered_areas.append("✓ Main Menu Navigation")
	if has_tests_for_area("Combat"):
		covered_areas.append("✓ Combat Interface")
	if has_tests_for_area("Player Stats"):
		covered_areas.append("✓ Player Statistics Display")
	if has_tests_for_area("Game Flow"):
		covered_areas.append("✓ Game State Transitions")
	
	for area in covered_areas:
		report += area + "\n"
	
	report += "\nRECOMMENDATIONS:\n"
	if total_fail > 0:
		report += "• Fix failing tests before release\n"
	if total_skip > 0:
		report += "• Investigate and enable skipped tests\n"
	if overall_success_rate < 90.0:
		report += "• Improve UI stability and error handling\n"
	if UITestFramework.test_results.size() < 20:
		report += "• Consider adding more comprehensive test coverage\n"
	
	print(report)
	
	# Save comprehensive report
	var filename = "comprehensive_ui_test_report_%d.txt" % Time.get_unix_time_from_system()
	var file = FileAccess.open("user://" + filename, FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
		print("Comprehensive test report saved to: user://" + filename)

func extract_suite_name(test_name: String) -> String:
	# Extract test suite name from test name
	if test_name == null or test_name == "":
		return "Unknown Tests"
	
	if test_name.begins_with("Main Menu"):
		return "Main Menu Tests"
	elif test_name.begins_with("Combat") or test_name.contains("Combat"):
		return "Combat UI Tests"
	elif test_name.begins_with("Player Stats") or test_name.contains("Stats"):
		return "Player Stats Tests"
	elif test_name.begins_with("Game") or test_name.contains("Flow"):
		return "Game Flow Tests"
	else:
		return "Other Tests"

func has_tests_for_area(area: String) -> bool:
	for test in UITestFramework.test_results:
		if test.name.to_lower().contains(area.to_lower()):
			return true
	return false
