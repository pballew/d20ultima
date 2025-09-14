extends Node

# Combat UI Tests
# Tests combat interface functionality including combat log, health displays, and action buttons

var test_scene: PackedScene
var test_instance: Node
var game_scene: Node
var combat_ui: Control
var player: Player
var combat_manager: CombatManager

func _ready():
	run_all_tests()

func run_all_tests():
	UITestFramework.clear_results()
	print("Starting Combat UI Tests...")
	
	# Load the main game controller scene
	test_scene = load("res://scenes/GameController.tscn")
	test_instance = test_scene.instantiate()
	get_tree().root.add_child(test_instance)
	
	# Wait for scene to initialize
	await UITestFramework.wait_frames(get_tree(), 3)
	
	# Get references
	game_scene = test_instance.get_node("GameScene")
	combat_ui = game_scene.get_node("UI/CombatUI")
	player = game_scene.get_node("Player")
	combat_manager = game_scene.get_node("CombatManager")
	
	# Start a test game to access combat UI
	await setup_test_game()
	
	# Run individual tests
	await test_combat_ui_visibility()
	await test_combat_log_functionality()
	await test_action_buttons()
	await test_player_stats_display()
	await test_enemy_display()
	await test_combat_flow()
	
	# Cleanup
	test_instance.queue_free()
	
	# Generate and save report
	var report = UITestFramework.generate_report()
	print(report)
	save_test_report(report, "combat_ui_tests")
	
	print("Combat UI Tests completed!")

func setup_test_game():
	# Create a test character
	var char_data = CharacterData.new()
	char_data.character_name = "TestWarrior"
	char_data.level = 1
	char_data.max_health = 100
	char_data.current_health = 100
	char_data.strength = 15
	char_data.dexterity = 12
	char_data.constitution = 14
	char_data.intelligence = 10
	char_data.wisdom = 13
	char_data.charisma = 8
	
	# Load character into player
	player.load_from_character_data(char_data)
	
	# Show game scene
	var game_controller = test_instance
	game_controller._on_start_game(char_data)
	
	await UITestFramework.wait_frames(get_tree(), 2)

func test_combat_ui_visibility():
	UITestFramework.start_test("Combat UI Initial Visibility")
	
	if not UITestFramework.assert_not_null(combat_ui, "Combat UI not found"):
		return
	
	# Combat UI should be initially hidden
	if not UITestFramework.assert_false(UITestFramework.is_control_visible(combat_ui), "Combat UI should be hidden initially"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_combat_log_functionality():
	UITestFramework.start_test("Combat Log Functionality")
	
	# Show combat UI
	combat_ui.show()
	await UITestFramework.wait_frames(get_tree(), 1)
	
	var combat_log = combat_ui.get_node("VBoxContainer/CombatLogContainer/CombatLog")
	
	if not UITestFramework.assert_not_null(combat_log, "Combat log not found"):
		return
	
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(combat_log), "Combat log not visible"):
		return
	
	# Test log text
	var initial_text = UITestFramework.get_label_text(combat_log as Label)
	if not UITestFramework.assert_true(initial_text.length() > 0, "Combat log has no initial text"):
		return
	
	# Test scrolling container
	var scroll_container = combat_ui.get_node("VBoxContainer/CombatLogContainer")
	if not UITestFramework.assert_not_null(scroll_container, "Combat log scroll container not found"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_action_buttons():
	UITestFramework.start_test("Action Buttons")
	
	combat_ui.show()
	await UITestFramework.wait_frames(get_tree(), 1)
	
	var attack_button = combat_ui.get_node("VBoxContainer/ActionButtons/AttackButton")
	var defend_button = combat_ui.get_node("VBoxContainer/ActionButtons/DefendButton")
	
	if not UITestFramework.assert_not_null(attack_button, "Attack button not found"):
		return
	
	if not UITestFramework.assert_not_null(defend_button, "Defend button not found"):
		return
	
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(attack_button), "Attack button not visible"):
		return
	
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(defend_button), "Defend button not visible"):
		return
	
	# Test button text
	if not UITestFramework.assert_equal("Attack", (attack_button as Button).text, "Attack button text incorrect"):
		return
	
	if not UITestFramework.assert_equal("Defend", (defend_button as Button).text, "Defend button text incorrect"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_player_stats_display():
	UITestFramework.start_test("Player Stats Display")
	
	combat_ui.show()
	await UITestFramework.wait_frames(get_tree(), 1)
	
	var health_label = combat_ui.get_node("VBoxContainer/PlayerStats/HealthLabel")
	var stats_label = combat_ui.get_node("VBoxContainer/PlayerStats/StatsLabel")
	
	if not UITestFramework.assert_not_null(health_label, "Health label not found"):
		return
	
	if not UITestFramework.assert_not_null(stats_label, "Stats label not found"):
		return
	
	# Test health display
	var health_text = UITestFramework.get_label_text(health_label as Label)
	if not UITestFramework.assert_true(health_text.contains("HP"), "Health text doesn't contain 'HP'"):
		return
	
	# Test stats display
	var stats_text = UITestFramework.get_label_text(stats_label as Label)
	if not UITestFramework.assert_true(stats_text.contains("AC") or stats_text.contains("Level"), "Stats text doesn't contain expected information"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_enemy_display():
	UITestFramework.start_test("Enemy Display")
	
	combat_ui.show()
	await UITestFramework.wait_frames(get_tree(), 1)
	
	var enemy_container = combat_ui.get_node("VBoxContainer/EnemyStats/EnemyContainer")
	var enemy_title = combat_ui.get_node("VBoxContainer/EnemyStats/EnemyTitle")
	
	if not UITestFramework.assert_not_null(enemy_container, "Enemy container not found"):
		return
	
	if not UITestFramework.assert_not_null(enemy_title, "Enemy title not found"):
		return
	
	var title_text = UITestFramework.get_label_text(enemy_title as Label)
	if not UITestFramework.assert_true(title_text.contains("Enemies"), "Enemy title text incorrect"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_combat_flow():
	UITestFramework.start_test("Combat Flow Simulation")
	
	# Set up combat UI
	combat_ui.setup_combat_ui(player, combat_manager)
	combat_ui.show()
	await UITestFramework.wait_frames(get_tree(), 1)
	
	# Create a test enemy
	var enemy = Monster.new()
	var enemy_data = MonsterData.new()
	enemy_data.monster_name = "Test Goblin"
	enemy_data.hit_dice = 1
	enemy.setup_from_monster_data(enemy_data)
	
	# Show combat with test enemy
	combat_ui.show_combat([enemy])
	await UITestFramework.wait_frames(get_tree(), 1)
	
	# Test that combat UI is properly set up
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(combat_ui), "Combat UI not visible during combat"):
		return
	
	# Test attack button functionality
	var attack_button = combat_ui.get_node("VBoxContainer/ActionButtons/AttackButton")
	if UITestFramework.assert_not_null(attack_button, "Attack button not found during combat"):
		var click_success = UITestFramework.click_button(attack_button as Button)
		UITestFramework.assert_true(click_success, "Failed to click attack button")
		await UITestFramework.wait_frames(get_tree(), 2)
	
	# Test defend button functionality
	var defend_button = combat_ui.get_node("VBoxContainer/ActionButtons/DefendButton")
	if UITestFramework.assert_not_null(defend_button, "Defend button not found during combat"):
		var click_success = UITestFramework.click_button(defend_button as Button)
		UITestFramework.assert_true(click_success, "Failed to click defend button")
		await UITestFramework.wait_frames(get_tree(), 2)
	
	# Clean up enemy
	enemy.queue_free()
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func save_test_report(report: String, filename: String):
	var file = FileAccess.open("user://test_reports_%s_%d.txt" % [filename, Time.get_unix_time_from_system()], FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
		print("Test report saved to: user://test_reports_%s_%d.txt" % [filename, Time.get_unix_time_from_system()])
