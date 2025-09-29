extends Node
class_name SpriteManager

# SpriteManager
#
# Responsibilities:
# - Load textures for players, monsters, and generic sprites
# - Cache original and scaled textures to avoid repeated work
# - Provide helpers to set textures on Sprite2D nodes (create if needed)
#
# Usage:
#  - Add this script as an Autoload (singleton) named `SpriteManager` in Project Settings
#  - Call `SpriteManager.get_player_texture("hero", Vector2(32,32))` or
#    `SpriteManager.render_to_sprite($Sprite2D, "player", "hero", Vector2(32,32))`

@export var base_paths: Dictionary = {
    "player": "res://assets/player_sprites/",
    "monster": "res://assets/monster_sprites/",
    "other": "res://assets/sprites/"
}

var _cache: Dictionary = {}
var _placeholder_texture: Texture2D = null

func _ready() -> void:
    # Create a visible placeholder texture for missing sprites
    _placeholder_texture = _create_placeholder()

func _resolve_path(category: String, name: String) -> String:
    var base := base_paths.get(category, base_paths["other"])
    if name.begins_with("res://"):
        return name
    # Allow caller to include extension or not. If no extension, try .png
    if name.find(".") == -1:
        return base + name + ".png"
    return base + name

func _load_texture(path: String) -> Texture2D:
    if path == null or path == "":
        return _placeholder_texture
    if _cache.has(path):
        return _cache[path]
    var tex: Texture2D = ResourceLoader.load(path) as Texture2D
    if tex == null:
        push_warning("SpriteManager: failed to load '%s'" % path)
        _cache[path] = _placeholder_texture
        return _placeholder_texture
    _cache[path] = tex
    return tex

func get_texture(category: String, name: String) -> Texture2D:
    var path := _resolve_path(category, name)
    return _load_texture(path)

func get_player_texture(name: String, target_size: Vector2 = Vector2.ZERO) -> Texture2D:
    return get_scaled_texture("player", name, target_size)

func get_monster_texture(name: String, target_size: Vector2 = Vector2.ZERO) -> Texture2D:
    return get_scaled_texture("monster", name, target_size)

func get_scaled_texture(category: String, name: String, target_size: Vector2) -> Texture2D:
    # If no scaling requested, return the original texture
    var path: String = _resolve_path(category, name)
    var original: Texture2D = _load_texture(path)
    if target_size == Vector2.ZERO or original == _placeholder_texture:
        return original
    var key: String = "%s|%s|%d|%d" % [category, name, int(target_size.x), int(target_size.y)]
    if _cache.has(key):
        return _cache[key]

    # Attempt to get image from texture
    var img: Image = null
    if original is Texture2D:
        img = original.get_image()
    if img == null:
        # Can't resize; return original texture
        return original

    # Duplicate to avoid mutating cached Image inside texture
    img = img.duplicate()
    img.lock()
    img.resize(int(target_size.x), int(target_size.y), Image.INTERPOLATE_LANCZOS)
    img.unlock()

    var scaled: ImageTexture = ImageTexture.create_from_image(img)
    _cache[key] = scaled
    return scaled

func render_to_sprite(sprite_node: Sprite2D = null, category: String = "other", name: String = "", target_size: Vector2 = Vector2.ZERO, modulate: Color = Color(1,1,1,1), centered: bool = true) -> Sprite2D:
    # If caller didn't pass a Sprite2D node, create one and return it
    var created: bool = false
    if sprite_node == null:
        sprite_node = Sprite2D.new()
        created = true

    var tex: Texture2D = get_scaled_texture(category, name, target_size)
    if tex == null:
        tex = _placeholder_texture

    sprite_node.texture = tex
    sprite_node.modulate = modulate
    sprite_node.centered = centered

    # When a target_size is given, scale the sprite so the texture fills the area
    if target_size != Vector2.ZERO and tex.get_size() != Vector2.ZERO:
        var scale: Vector2 = Vector2( target_size.x / tex.get_size().x, target_size.y / tex.get_size().y )
        sprite_node.scale = scale
    else:
        sprite_node.scale = Vector2.ONE

    if created:
        return sprite_node
    return sprite_node

func _create_placeholder() -> Texture2D:
    var img := Image.new()
    img.create(8, 8, false, Image.FORMAT_RGBA8)
    img.lock()
    # checkerboard magenta/black to make missing sprites obvious
    for y in range(img.get_height()):
        for x in range(img.get_width()):
            var c = Color(1,0,1,1) if ((x + y) % 2 == 0) else Color(0,0,0,1)
            img.set_pixel(x, y, c)
    img.unlock()
    return ImageTexture.create_from_image(img)
