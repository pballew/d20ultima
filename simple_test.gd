extends SceneTree

const CharacterData = preload("res://scripts/CharacterData.cs")

func _ready():
    DebugLogger.info("=== SIMPLE HIT DICE TEST ===")
    var char_data = CharacterData.new()
    char_data.character_class = CharacterData.CharacterClass.FIGHTER
    DebugLogger.info("Fighter hit die roll: %s" % char_data.roll_class_hit_die())
    char_data.character_class = CharacterData.CharacterClass.WIZARD
    DebugLogger.info("Wizard hit die roll: %s" % char_data.roll_class_hit_die())
    DebugLogger.info("=== TEST COMPLETE ===")
    quit()
