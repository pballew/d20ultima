extends Node

func _ready():
	var data = MonsterData.new()
	data.monster_name = "Test Goblin"
	print("MonsterData test: ", data.monster_name)
