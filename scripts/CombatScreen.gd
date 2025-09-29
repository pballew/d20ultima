
extends Control

@export var tile_size: int = 32
@export var terrain_node_path: NodePath = "../EnhancedTerrainTileMap"
@export var player_node_path: NodePath = "../Player"
@export var monster_texture_path: String = "res://assets/player_sprites/monster_placeholder.png"

@onready var background = $Background
@onready var player_sprite = $PlayerSprite
@onready var monster_sprite = $MonsterSprite

var bandit_node: TextureRect = null


func _recursive_find(root, target_name: String):
    if not root:
        return null
    if root.name == target_name:
        return root
    for child in root.get_children():
        var found = _recursive_find(child, target_name)
        if found:
            return found
    return null


func _find_enemy_with_sprite(node):
    if not node:
        return null
    for c in node.get_children():
        if c is Node:
            if (c.get_class() == "Character" or c.get_class() == "Monster") and c.has_node("Sprite2D"):
                return c
            var r = _find_enemy_with_sprite(c)
            if r:
                return r
    return null

func _ready():
    visible = false
    if not background:
        print("CombatScreen: background missing")
    if not player_sprite:
        print("CombatScreen: player_sprite missing")
    if not monster_sprite:
        print("CombatScreen: monster_sprite missing")
    # allow this control to receive focus when requested
    set_focus_mode(Control.FOCUS_ALL)
    print("CombatScreen ready (hidden). Toggle with F6")

func toggle():
    visible = not visible
    if visible:
        _build_background()
        _setup_sprites()
        # take input focus so this control receives unhandled input
        set_process_unhandled_input(true)
        # Defer grabbing focus until after layout so we avoid warnings
        call_deferred("grab_focus")
        z_index = 1000
        # CombatScreen is anchored fullscreen via the scene, no manual sizing needed
        # Defer spawn so control has valid size after layout
        call_deferred("_spawn_bandit")
    else:
        # stop processing input when hidden
        set_process_unhandled_input(false)
        _remove_bandit()

    print("CombatScreen toggled - now visible=", visible)

func _build_background():
    # Locate terrain and player
    var terrain = get_node_or_null(terrain_node_path)
    var player_node = get_node_or_null(player_node_path)
    var root = get_tree().get_root()
    if not terrain:
        terrain = _recursive_find(root, "EnhancedTerrainTileMap")
        if not terrain:
            terrain = _recursive_find(root, "EnhancedTerrain")
    if not player_node:
        player_node = _recursive_find(root, "Player")

    var tex: Texture2D = null
    if terrain and player_node:
        # Try preferred API first
        if terrain.has_method("get_tile_texture_at_world_pos"):
            tex = terrain.get_tile_texture_at_world_pos(player_node.global_position)
        # Fallback: try to construct AtlasTexture from available atlas and map data
        else:
            var atlas = terrain.get("terrain_atlas_texture") if terrain else null
            if atlas:
                # compute tile coords and lookup terrain type if possible
                var tile_x = int(floor(player_node.global_position.x / tile_size))
                var tile_y = int(floor(player_node.global_position.y / tile_size))
                var info = null
                if terrain.has_method("global_tile_to_section_and_local"):
                    info = terrain.global_tile_to_section_and_local(Vector2i(tile_x, tile_y))
                if info:
                    var section_id = info.get("section_id", null)
                    var local_pos = info.get("local_pos", null)
                    var sections = terrain.get("map_sections") if terrain else null
                    if section_id != null and local_pos != null and sections:
                        if sections.has(section_id):
                            var section = sections[section_id]
                            if section and section.terrain_data.has(local_pos):
                                var terrain_type = int(section.terrain_data[local_pos])
                                var atlas_x = terrain_type % 8
                                var atlas_y = int(terrain_type / 8)
                                var region = Rect2(atlas_x * tile_size, atlas_y * tile_size, tile_size, tile_size)
                                var at = AtlasTexture.new()
                                at.atlas = atlas
                                at.region = region
                                tex = at
    # If no texture found, create a subtle fallback
    if tex:
        background.texture = tex
        background.stretch_mode = TextureRect.STRETCH_TILE
        background.expand = true
        background.modulate = Color(1,1,1,1)
        print("CombatScreen: sampled terrain tile texture for background")
    else:
        var img = Image.create(4,4,false,Image.FORMAT_RGBA8)
        img.fill(Color(1,1,1,1))
        var solid = ImageTexture.new()
        solid.set_image(img)
        background.texture = solid
        background.stretch_mode = TextureRect.STRETCH_TILE
        background.expand = true
        background.modulate = Color(0.06,0.06,0.06,0.95)
        print("CombatScreen: using generated fallback texture")

    # Debug layout
    print("CombatScreen: visible=", visible, " parent=", get_parent(), " name=", name)

func _setup_sprites():
    # Player sprite
    var player_node = get_node_or_null(player_node_path)
    if not player_node:
        player_node = _recursive_find(get_tree().get_root(), "Player")
    var found_player_tex: Texture2D = null
    if player_node:
        if player_node.has_node("Sprite2D"):
            var s = player_node.get_node("Sprite2D")
            if s and s.texture:
                found_player_tex = s.texture
        else:
            for child in player_node.get_children():
                if child is Sprite2D and child.texture:
                    found_player_tex = child.texture
                    break
    if found_player_tex:
        player_sprite.texture = found_player_tex
        player_sprite.visible = true
        # Size the TextureRect to the source texture (100% scale)
        var psize = found_player_tex.get_size()
        player_sprite.size = psize
        player_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        print("CombatScreen: using player texture for player_sprite (100% scale)")
    else:
        print("CombatScreen: could not find player texture")

    # Monster sprite: try provided path, then scene search, else generated placeholder
    var monster_tex: Texture2D = null
    if monster_texture_path != "" and FileAccess.file_exists(monster_texture_path):
        monster_tex = load(monster_texture_path)
    if not monster_tex:
        var enemy = _find_enemy_with_sprite(get_tree().get_root())
        if enemy:
            var es = enemy.get_node_or_null("Sprite2D")
            if es and es.texture:
                monster_tex = es.texture
    if not monster_tex:
        # Do not show a red placeholder; hide the monster sprite instead
        monster_sprite.visible = false
        print("CombatScreen: no monster texture found; hiding monster_sprite")
    else:
        monster_sprite.texture = monster_tex
        monster_sprite.visible = true
        var msize = monster_tex.get_size()
        # Use native size (100% scale) for the monster sprite as well
        monster_sprite.size = msize
        monster_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        print("CombatScreen: monster sprite set (100% scale)")

func _unhandled_input(event):
    # When the combat screen is visible, absorb movement/gameplay input
    if not visible:
        return
    # Consume movement actions so the map/player doesn't receive them
    if event is InputEventKey and event.pressed:
        var consumed = []
        if Input.is_action_pressed("move_up"):
            consumed.append("move_up")
        if Input.is_action_pressed("move_down"):
            consumed.append("move_down")
        if Input.is_action_pressed("move_left"):
            consumed.append("move_left")
        if Input.is_action_pressed("move_right"):
            consumed.append("move_right")
        if consumed.size() > 0:
            # If the event object supports accept(), call it safely; otherwise fall back to marking
            # the viewport input as handled. This avoids calling nonexistent methods on InputEventKey.
            if event and event.has_method("accept"):
                event.accept()
            else:
                get_viewport().set_input_as_handled()
            print("CombatScreen: consumed movement input -", consumed)

func _spawn_bandit():
    _remove_bandit()
    var rng = RandomNumberGenerator.new()
    rng.randomize()

    # Instead of random placement, position the bandit directly above the player
    var screen_size = size
    # Determine player's position relative to this control
    var player_local_pos = Vector2(screen_size.x / 2.0, screen_size.y * 0.85)
    if player_sprite and player_sprite.visible:
        # Use the player's local center position directly (player_sprite is a child of this Control)
        player_local_pos = player_sprite.position + player_sprite.size * 0.5

    # Place bandit one tile above the player's tile (clamped to top)
    var col = int(floor(player_local_pos.x / tile_size))
    var row = int(floor(player_local_pos.y / tile_size)) - 1
    if row < 0:
        row = 0

    # Prefer drawing the bandit exactly like the player to avoid loader/import issues
    var tex: Texture2D = null
    var bandit_png = "res://assets/monster_sprites/bandit.png"

    # 1) Use the player's texture (draw identical)
    if player_sprite and player_sprite.visible and player_sprite.texture:
        tex = player_sprite.texture
        print("CombatScreen: using player texture for bandit (draws identical to player)")

    # 2) If no player texture, try the raw PNG file (load may work if imported, else fall back to Image.load)
    if not tex and FileAccess.file_exists(bandit_png):
        var r2 = load(bandit_png)
        if r2 and r2 is Texture2D:
            tex = r2
            print("CombatScreen: loaded bandit.png directly as Texture2D")
        else:
            var img_fallback = Image.new()
            var err = img_fallback.load(bandit_png)
            if err == OK:
                var it_fallback = ImageTexture.new()
                it_fallback.create_from_image(img_fallback)
                tex = it_fallback
                print("CombatScreen: bandit image fallback created from PNG, img_size=", img_fallback.get_size(), " tex_get_size=", (tex.get_size() if tex.has_method("get_size") else Vector2.ZERO))
            else:
                print("CombatScreen: failed to load bandit PNG via Image.load(), err=", err)

    # fallback: if we couldn't create a proper texture, try using the monster_sprite's texture (if set)
    if not tex and monster_sprite and monster_sprite.visible and monster_sprite.texture:
        tex = monster_sprite.texture

    # final fallback: create a neutral, non-red placeholder ImageTexture (tile sized)
    if not tex or (tex and tex.has_method("get_size") and tex.get_size() == Vector2.ZERO):
        var placeholder = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
        placeholder.fill(Color(0.8, 0.8, 0.8, 1.0))
        var placeholder_tex = ImageTexture.new()
        placeholder_tex.create_from_image(placeholder)
        tex = placeholder_tex

    if not tex:
        # No real texture available; skip spawning the bandit instead of showing a colored square
        print("CombatScreen: no bandit texture found; skipping spawn")
        return

    var tr = TextureRect.new()
    tr.texture = tex
    tr.anchor_left = 0
    tr.anchor_top = 0
    tr.anchor_right = 0
    tr.anchor_bottom = 0

    var px = col * tile_size
    var py = row * tile_size
    # Size the bandit to match the displayed player size (if available)
    var player_display_size = Vector2(tile_size, tile_size)
    if player_sprite and player_sprite.visible and player_sprite.size.length() > 0:
        player_display_size = player_sprite.size
    tr.size = player_display_size
    tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tr.visible = true
    tr.modulate = Color(1,1,1,1)

    # Place the bandit centered above the player's center
    var player_center = player_local_pos
    var bandit_pos = player_center - Vector2(tr.size.x * 0.5, tr.size.y + 4)
    # Clamp inside the control bounds
    bandit_pos.x = clamp(bandit_pos.x, 0, max(0, screen_size.x - tr.size.x))
    bandit_pos.y = clamp(bandit_pos.y, 0, max(0, screen_size.y - tr.size.y))
    tr.position = bandit_pos
    # Ensure bandit renders above other UI elements
    tr.z_index = 1100
    add_child(tr)
    bandit_node = tr

    # Temporary visual debug marker (semi-transparent yellow) to confirm placement
    var debug_rect = ColorRect.new()
    debug_rect.color = Color(1, 1, 0, 0.6)
    debug_rect.size = tr.size
    debug_rect.position = tr.position
    debug_rect.anchor_left = 0
    debug_rect.anchor_top = 0
    debug_rect.anchor_right = 0
    debug_rect.anchor_bottom = 0
    debug_rect.z_index = tr.z_index + 5
    add_child(debug_rect)

    var t = Timer.new()
    t.wait_time = 1.5
    t.one_shot = true
    add_child(t)
    t.start()
    # Connect the timeout to free the debug rect and the timer itself (no binds required)
    # Use Callables so the signal signature matches and no extra args are required.
    t.connect("timeout", Callable(debug_rect, "queue_free"))
    t.connect("timeout", Callable(t, "queue_free"))
    # Diagnostics to help locate the bandit and verify the loaded texture
    var tex_size = Vector2()
    var tex_kind = "null"
    if tex:
        tex_kind = str(typeof(tex)) + "(" + str(tex.get_class()) + ")"
        tex_size = tex.get_size() if tex.has_method("get_size") else Vector2()
    print("CombatScreen: spawned bandit at col=", col, " row=", row, " px=", px, " py=", py, " screen_size=", screen_size)
    print("CombatScreen: player_local_pos=", player_local_pos, " player_sprite.position=", (player_sprite.position if player_sprite else "n/a"), " player_sprite.size=", (player_sprite.size if player_sprite else "n/a"))
    print("CombatScreen: bandit tex_kind=", tex_kind, " tex_size=", tex_size, " bandit_node.size=", tr.size, " bandit_node.position=", tr.position, " bandit_node.global_position=", tr.get_global_position(), " z_index=", tr.z_index)

    # Extra diagnostic: if the texture reports zero size, log a hint and ensure the placeholder is visible
    if tex_size == Vector2.ZERO:
        print("CombatScreen: WARNING: bandit texture reports zero size. Forcing visible placeholder of tile_size=", tile_size)

func _remove_bandit():
    if bandit_node and is_instance_valid(bandit_node):
        bandit_node.queue_free()
        bandit_node = null


# CombatScreen intentionally doesn't process input; Main.gd toggles it

