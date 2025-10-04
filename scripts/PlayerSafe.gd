class_name PlayerSafe
extends Node2D

# Very small safe player shim used during porting. Does not depend on Character.gd.

@export var movement_speed: float = 200.0

signal movement_finished
signal encounter_started
signal camping_started
signal town_name_display(town_name: String)

var _target_position: Vector2
var _is_moving: bool = false
var character_name: String = "Unnamed"
var level: int = 1
var max_health: int = 100
var current_health: int = 100
var experience: int = 0

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
    var d: Dictionary = {}
    d["character_name"] = character_name
    d["level"] = level
    d["max_health"] = max_health
    d["current_health"] = current_health
    d["experience"] = experience
    d["world_position"] = global_position
    return d

func move_to_tile(new_pos: Vector2) -> void:
    _target_position = new_pos
    _is_moving = true

func set_camera_target(pos: Vector2) -> void:
    pass

func _physics_process(delta: float) -> void:
    if _is_moving:
        global_position = global_position.move_toward(_target_position, movement_speed * delta)
        if global_position.distance_to(_target_position) < 1.0:
            global_position = _target_position
            _is_moving = false
            emit_signal("movement_finished")
