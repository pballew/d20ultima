using Godot;
using System;

public partial class CoordinateOverlay : Control
{
    Label coordinate_label;
    Player player;

    public override void _Ready()
    {
        coordinate_label = GetNodeOrNull<Label>("CoordinateLabel");
        // Attempt to find player in the scene tree
        var main = GetTree().GetFirstNodeInGroup("main");
        if (main != null && main is Node mainNode)
        {
            player = mainNode.GetNodeOrNull<Player>("Player");
        }
    }

    public override void _Process(double delta)
    {
        if (player != null && coordinate_label != null)
        {
            var worldPos = player.GlobalPosition;
            var tileX = (int)(worldPos.x / 32);
            var tileY = (int)(worldPos.y / 32);
            coordinate_label.Text = $"World: ({worldPos.x:0},{worldPos.y:0})\nTile: ({tileX},{tileY})";
        }
    }

    public void UpdateCoordinates(Vector2 tilePosition)
    {
        if (coordinate_label != null)
        {
            var worldPos = new Vector2(tilePosition.x * 32, tilePosition.y * 32);
            coordinate_label.Text = $"World: ({worldPos.x:0},{worldPos.y:0})\nTile: ({(int)tilePosition.x},{(int)tilePosition.y})";
        }
    }
}
