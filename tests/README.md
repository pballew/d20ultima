# UI Test Automation for Ultima-Style D20 RPG

This directory contains automated UI tests for the game's user interface components.

## Test Framework

The `UITestFramework.gd` provides a comprehensive testing framework with:
- Assertion functions (assert_true, assert_false, assert_equal, etc.)
- UI interaction helpers (click_button, set_line_edit_text, etc.)
- Control finding utilities
- Test result tracking and reporting

## Test Suites

### MainMenuTests.gd
Tests the main menu functionality including:
- Menu visibility and layout
- Button presence and functionality
- Character creation navigation
- Title display
- Menu transitions

### CombatUITests.gd
Tests the combat interface including:
- Combat UI visibility during combat
- Action buttons (Attack, Defend)
- Combat log functionality
- Player and enemy stat displays
- Combat flow simulation

### PlayerStatsUITests.gd
Tests the player statistics display including:
- Character name and level display
- Health and experience bars
- Attribute displays (STR, DEX, CON, INT, WIS, CHA)
- Combat stats (AC, Attack Bonus)
- Real-time stat updates

### GameFlowUITests.gd
Tests overall game flow and transitions including:
- Initial game state
- Menu to character creation transitions
- Character creation to game transitions
- Game to combat transitions
- Save system integration
- Camera integration

## Running Tests

### Automated Test Run
To run all tests automatically:
1. Set the main scene to `res://tests/UITestRunner.tscn`
2. Run the project
3. Tests will execute automatically and generate reports

### Manual Test Execution
To run individual test suites:
1. Load any individual test scene
2. Add it to your scene tree
3. The tests will run automatically

## Test Reports

Test reports are automatically generated and saved to:
- `user://test_reports_[suite_name]_[timestamp].txt` for individual suites
- `user://comprehensive_ui_test_report_[timestamp].txt` for full test runs

## Test Results

Reports include:
- Pass/Fail/Skip counts
- Success rates
- Failed test details with error messages
- Test execution time
- Quality assessment and recommendations
- Coverage analysis

## Best Practices

1. **Test Independence**: Each test should be independent and not rely on other tests
2. **Cleanup**: Tests clean up after themselves to avoid affecting other tests
3. **Realistic Data**: Tests use realistic test data that matches actual game scenarios
4. **Comprehensive Coverage**: Tests cover both positive and negative scenarios
5. **Clear Assertions**: Each assertion includes descriptive error messages

## Adding New Tests

To add new UI tests:
1. Create a new test file in the `tests/` directory
2. Extend Node and use UITestFramework for assertions
3. Follow the pattern of existing test files
4. Add your test file to the `test_classes` array in `UITestRunner.gd`

## Test Categories

- **Functional Tests**: Test that UI components work as expected
- **Visual Tests**: Test that UI elements are properly displayed
- **Integration Tests**: Test that UI components work together correctly
- **Flow Tests**: Test user workflows and transitions
- **Error Handling Tests**: Test UI behavior under error conditions

## Continuous Integration

These tests can be integrated into CI/CD pipelines by:
1. Running the UITestRunner scene in headless mode
2. Parsing the generated test reports
3. Failing the build if tests fail
4. Generating test result summaries for build reports
