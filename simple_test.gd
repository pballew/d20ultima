extends SceneTree
func _ready():
    print("=== SIMPLE HIT DICE TEST ===")
    var char_data = CharacterData.new()
    char_data.character_class = CharacterData.CharacterClass.FIGHTER
    print("Fighter hit die roll: ", char_data.roll_class_hit_die())
    char_data.character_class = CharacterData.CharacterClass.WIZARD
    print("Wizard hit die roll: ", char_data.roll_class_hit_die())
    print("=== TEST COMPLETE ===")
    quit()
