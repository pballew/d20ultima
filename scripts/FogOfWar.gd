extends Node2D

# Fog of War system with "memory" fog.
# Categories:
#  - Unseen (never explored): opaque fog (unseen_fog_color)
#  - Explored but not currently visible: lighter memory fog (memory_fog_color)
#  - Currently visible: fully clear

@export var tile_size: int = 32
@export var reveal_radius_tiles: int = 6
@export var unseen_fog_color: Color = Color(0, 0, 0, 0.80)
@export var memory_fog_color: Color = Color(0, 0, 0, 0.40)
@export var edge_softening: bool = true  # If true, soften the hard edge around visible area
@export var enabled: bool = true

var explored := {}          # Set of tiles ever seen
var visible_tiles := {}           # Set of tiles currently visible (recomputed each move)
var terrain: Node = null
var player: Node = null
var last_used_rect: Rect2i = Rect2i(0,0,0,0)
var needs_full_redraw: bool = true

func _ready():
    # Find terrain (kept name EnhancedTerrainTileMap for compatibility)
    terrain = get_tree().get_root().find_child("EnhancedTerrainTileMap", true, false)
    if terrain and terrain.has_method("get_used_rect"):
        last_used_rect = terrain.get_used_rect()
        # React to later section generation (multi-map signal)
        if terrain.has_signal("sections_generated"):
            terrain.sections_generated.connect(_on_sections_generated)

    # Find player node
    player = get_tree().get_root().find_child("Player", true, false)
    if player:
        # Reveal initial area after a short delay to ensure player positioned
        await get_tree().process_frame
        reveal_around_position(player.global_position)
        # Connect movement_finished if available
        if player.has_signal("movement_finished"):
            player.movement_finished.connect(_on_player_moved)

    set_process(false)  # Not needed every frame; we redraw only when needed

func _on_sections_generated():
    if terrain and terrain.has_method("get_used_rect"):
        last_used_rect = terrain.get_used_rect()
        needs_full_redraw = true
        queue_redraw()

func _on_player_moved():
    if not player: return
    reveal_around_position(player.global_position)

func reveal_around_position(world_pos: Vector2):
    if not enabled:
        return
    var center_tile = Vector2i(int(floor(world_pos.x / tile_size)), int(floor(world_pos.y / tile_size)))
    var r = reveal_radius_tiles
    var r_sq = r * r
    visible_tiles.clear()
    var any_change := false
    for dx in range(-r, r + 1):
        for dy in range(-r, r + 1):
            var dist_sq = dx * dx + dy * dy
            if dist_sq <= r_sq:
                var t = Vector2i(center_tile.x + dx, center_tile.y + dy)
                visible_tiles[t] = true
                if not explored.has(t):
                    explored[t] = true
                    any_change = true
    # Redraw if visibility region changed or new tiles explored
    if any_change or true: # Always redraw on move for memory fog correctness
        queue_redraw()

func clear_all():
    explored.clear()
    visible_tiles.clear()
    needs_full_redraw = true
    queue_redraw()

func _unhandled_input(event):
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_F8:
                enabled = not enabled
                print("FogOfWar enabled:", enabled)
                queue_redraw()
            KEY_F7:
                print("FogOfWar: clearing explored tiles")
                clear_all()

func _draw():
    if not enabled:
        return
    if last_used_rect.size == Vector2i.ZERO:
        if terrain and terrain.has_method("get_used_rect"):
            last_used_rect = terrain.get_used_rect()
        else:
            return

    var start_x = last_used_rect.position.x
    var start_y = last_used_rect.position.y
    var end_x = start_x + last_used_rect.size.x
    var end_y = start_y + last_used_rect.size.y

    for tx in range(start_x, end_x):
        for ty in range(start_y, end_y):
            var tile = Vector2i(tx, ty)
            if visible_tiles.has(tile):
                continue # Fully revealed right now
            var rect_pos = Vector2(tx * tile_size, ty * tile_size)
            var color: Color
            if explored.has(tile):
                color = memory_fog_color
                if edge_softening:
                    # If adjacent to a currently visible tile, soften even more
                    var near_visible := false
                    for nx in range(-1, 2):
                        for ny in range(-1, 2):
                            if nx == 0 and ny == 0: continue
                            var n = Vector2i(tile.x + nx, tile.y + ny)
                            if visible_tiles.has(n):
                                near_visible = true
                                break
                        if near_visible: break
                    if near_visible:
                        color = Color(color.r, color.g, color.b, color.a * 0.6)
            else:
                color = unseen_fog_color
                if edge_softening:
                    # If adjacent to explored tile (memory), reduce alpha slightly
                    var near_memory := false
                    for nx in range(-1, 2):
                        for ny in range(-1, 2):
                            if nx == 0 and ny == 0: continue
                            var n = Vector2i(tile.x + nx, tile.y + ny)
                            if explored.has(n):
                                near_memory = true
                                break
                        if near_memory: break
                    if near_memory:
                        color = Color(color.r, color.g, color.b, color.a * 0.85)
            draw_rect(Rect2(rect_pos, Vector2(tile_size, tile_size)), color, true)

func debug_stats() -> Dictionary:
    return {
        "explored_tiles": explored.size(),
    "visible_tiles": visible_tiles.size(),
        "bounds": last_used_rect,
        "enabled": enabled,
        "radius": reveal_radius_tiles
    }
