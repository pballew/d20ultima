# Minimal, clean Player.gd
class_name Player
extends Node2D

# Mirror key Character fields here so GDScript can parse and run even when C# base isn't loaded
@export var character_name: String = "Unnamed"
@export var strength: int = 10
@export var dexterity: int = 10
@export var constitution: int = 10
@export var intelligence: int = 10
@export var wisdom: int = 10
@export var charisma: int = 10

@export var max_health: int = 100
@export var current_health: int = 100
@export var armor_class: int = 10
@export var level: int = 1
@export var experience: int = 0

@export var attack_bonus: int = 0
@export var damage_dice: String = "1d6"

var initiative: int = 0
var weapon = null
var armor = null
var inventory: Array = []

@export var movement_speed: float = 200.0

signal movement_finished
signal encounter_started
signal camping_started
signal town_name_display(town_name: String)

var _target_position: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _is_in_combat: bool = false

func _ready() -> void:
	_target_position = global_position

func load_from_character_data(char_data) -> void:
	if typeof(char_data) == TYPE_DICTIONARY:
		character_name = char_data.get("character_name", character_name)
		level = int(char_data.get("level", level))
		max_health = int(char_data.get("max_health", max_health))
		current_health = int(char_data.get("current_health", current_health))
		experience = int(char_data.get("experience", experience))
		global_position = char_data.get("world_position", global_position)

func save_to_character_data() -> Dictionary:
	var d := {}
	d["character_name"] = character_name
	d["level"] = level
	d["max_health"] = max_health
	d["current_health"] = current_health
	d["experience"] = experience
	d["world_position"] = global_position
	return d

func enter_combat() -> void:
	_is_in_combat = true

func exit_combat() -> void:
	_is_in_combat = false

func move_to_tile(new_pos: Vector2) -> void:
	_target_position = new_pos
	_is_moving = true

func set_camera_target(pos: Vector2) -> void:
	# Minimal stub; Main checks for this method before calling
	pass

func get_encounter_difficulty_for_terrain(terrain_type: int) -> float:
	return 1.0

func _physics_process(delta: float) -> void:
	if _is_moving:
		global_position = global_position.move_toward(_target_position, movement_speed * delta)
		if global_position.distance_to(_target_position) < 1.0:
			global_position = _target_position
			_is_moving = false
			emit_signal("movement_finished")




