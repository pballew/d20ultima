extends Node2D

@export var columns: int = 5
@export var cell_size: Vector2 = Vector2(128, 128)
@export var sprite_size: Vector2 = Vector2(96, 96)

var monsters := [
    "bandit.png",
    "black_bear.png",
    "dire_wolf.png",
    "giant_rat.png",
    "gnoll.png",
    "goblin.png",
    "hobgoblin.png",
    "human_skeleton.png",
    "kobold.png",
    "lizardfolk.png",
    "ogre.png",
    "orc.png",
    "stirge.png",
    "wolf.png",
    "zombie.png",
]

func _ready() -> void:
    # Create a simple alternating background grid so transparency is obvious
    for i in range(monsters.size()):
        var col = i % columns
        var row = int(i / columns)
        var pos = Vector2(col * cell_size.x, row * cell_size.y)

        var bg = ColorRect.new()
        bg.color = Color(0.85,0.85,0.85,1) if ((col + row) % 2 == 0) else Color(0.25,0.25,0.25,1)
        bg.rect_position = pos
        bg.rect_size = cell_size
        add_child(bg)

        # Load sprite texture (monster sprites folder)
        var path = "res://assets/monster_sprites/" + monsters[i]
        var tex = null
        if ResourceLoader.exists(path):
            tex = load(path)
        else:
            # fallback to null if missing (placeholder rendering handled elsewhere)
            tex = null

        var spr = Sprite2D.new()
        spr.texture = tex
        spr.position = pos + cell_size * 0.5
        # scale texture to fit sprite_size while preserving aspect
        if tex and tex.get_size().x > 0:
            var scale = Vector2(sprite_size.x / tex.get_size().x, sprite_size.y / tex.get_size().y)
            spr.scale = scale
        add_child(spr)

        var lbl = Label.new()
        lbl.text = monsters[i]
        lbl.position = pos + Vector2(6, cell_size.y - 20)
        lbl.modulate = Color(0,0,0,1) if ((col + row) % 2 == 0) else Color(1,1,1,1)
        add_child(lbl)
