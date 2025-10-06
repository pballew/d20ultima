using Godot;
using System.Collections.Generic;

public partial class TileCentersOverlay : Node2D
{
    [Export] public Color dot_color = new Color(1,1,1,0.45f);
    [Export] public int dot_size = 3;
    [Export] public int max_dots = 0;

    private Node terrain_ref;
    private List<Vector2> dot_points = new List<Vector2>();
    private const int DEFAULT_TILE_SIZE = 32;

    public override void _Ready()
    {
        terrain_ref = GetTree().Root.FindChild("EnhancedTerrainTileMap", true, false) ?? GetTree().Root.FindChild("EnhancedTerrain", true, false);
        if (terrain_ref != null && terrain_ref.HasSignal("sections_generated"))
            terrain_ref.Connect("sections_generated", new Callable(this, nameof(OnSectionsGenerated)));
        BuildPoints();
        QueueRedraw();
        SetProcessInput(true);
    }

    private void OnSectionsGenerated()
    {
        BuildPoints();
        QueueRedraw();
    }

    private void BuildPoints()
    {
        // For now build a minimal empty points list to avoid complex interop with existing terrain types.
        dot_points.Clear();
        // Keep the list empty unless a robust C# path is needed later.
    }

    public override void _Draw()
    {
        if (dot_size <= 0) return;
        float half = dot_size * 0.5f;
        foreach (var p in dot_points)
        {
            DrawRect(new Rect2(p - new Vector2(half, half), new Vector2(dot_size, dot_size)), dot_color);
        }
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventKey ek && ek.Pressed)
        {
            if (ek.Keycode == Key.F9)
            {
                Visible = !Visible;
                var logger = GetTree()?.Root?.GetNodeOrNull<DebugLogger>("DebugLogger");
                logger?.Info($"TileCentersOverlay visibility: {Visible}");
            }
            else if (ek.Keycode == Key.F10)
            {
                BuildPoints();
                QueueRedraw();
                var logger = GetTree()?.Root?.GetNodeOrNull<DebugLogger>("DebugLogger");
                logger?.Info($"TileCentersOverlay rebuilt ({dot_points.Count} dots)");
            }
        }
    }
}
