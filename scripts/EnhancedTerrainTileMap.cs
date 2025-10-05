using Godot;
using System;

public partial class EnhancedTerrainTileMap : Node
{
    // Best-effort compatibility methods used by GDScript/C# Player and Main
    public bool is_walkable(Vector2 pos)
    {
        // Try to find a TileMap child and check cell at position
        var tilemap = GetNodeOrNull<TileMap>("Section_0_0");
        if (tilemap != null)
        {
            var local = tilemap.WorldToMap(pos - tilemap.Position);
            var cell = tilemap.GetCell(0, local);
            // If cell < 0, consider non-walkable; otherwise walkable
            return cell >= 0;
        }
        // Fallback: assume walkable
        return true;
    }

    public int get_terrain_type_at_tile(Vector2i tilePos)
    {
        // Try to find a tile under the sections; naive mapping: use Section_0_0
        var tilemap = GetNodeOrNull<TileMap>("Section_0_0");
        if (tilemap != null)
        {
            var cell = tilemap.GetCell(0, tilePos);
            return (int)cell;
        }
        return 0;
    }

    public Godot.Collections.Dictionary get_town_data_at_position(Vector2 worldPos)
    {
        // Best-effort: look for town data stored on this node as a dictionary property
        try
        {
            var prop = Get("town_data");
            if (prop is Godot.Collections.Dictionary dict)
                return dict;
        }
        catch { }
        return null;
    }
}
