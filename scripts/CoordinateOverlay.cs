using Godot;
using System;

public partial class CoordinateOverlay : Control
{
    private Label _coordinateLabel;
    private Node2D _player;
    private const int TILE_SIZE = 32;

    public override void _Ready()
    {
        _coordinateLabel = GetNodeOrNull<Label>("CoordinateLabel");
        // Try to find a Player node in the active scene (best-effort)
        // First try the common absolute path (fast)
        _player = GetTree().Root.GetNodeOrNull<Node2D>("/root/GameController/Main/Game/Player");

        // If not found, recursively search for a node named "Player"
        if (_player == null)
            _player = FindPlayer(GetTree().Root);

        // Runtime fallback: ensure the label is placed at a visible top-left position
        if (_coordinateLabel != null)
        {
            try {
                // Pin label to top-left as a runtime fallback
                _coordinateLabel.AnchorLeft = 0f;
                _coordinateLabel.AnchorTop = 0f;
                _coordinateLabel.AnchorRight = 0f;
                _coordinateLabel.AnchorBottom = 0f;
                _coordinateLabel.OffsetLeft = 8f;
                _coordinateLabel.OffsetTop = 8f;
            } catch { }
        }
    }

    private Node2D FindPlayer(Node start)
    {
        foreach (var child in start.GetChildren())
        {
            if (child == null) continue;
            if (child.Name == "Player" && child is Node2D asNode2D)
                return asNode2D;
            var found = FindPlayer(child);
            if (found != null)
                return found;
        }
        return null;
    }

    public override void _Process(double delta)
    {
        if (_player == null || _coordinateLabel == null)
            return;

    var worldPos = _player.GlobalPosition;
    var tileX = (int)(worldPos.X / TILE_SIZE);
    var tileY = (int)(worldPos.Y / TILE_SIZE);
    _coordinateLabel.Text = $"World: ({worldPos.X:0},{worldPos.Y:0})\nTile: ({tileX},{tileY})";
    }

    // Compatibility wrapper used by other scripts
    public void update_coordinates(Vector2 tile_pos)
    {
        if (_coordinateLabel == null) return;
    var worldPos = new Vector2(tile_pos.X * TILE_SIZE, tile_pos.Y * TILE_SIZE);
    _coordinateLabel.Text = $"World: ({worldPos.X:0},{worldPos.Y:0})\nTile: ({(int)tile_pos.X},{(int)tile_pos.Y})";
    }
}
