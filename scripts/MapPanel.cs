using Godot;
using System;

public partial class MapPanel : Control
{
    public override void _Ready()
    {
        // Ensure panel is hidden initially; MainMenu will toggle visibility
        Hide();
    }

    public void ShowMap()
    {
        Show();
        // Bring to front
        this.ZIndex = 1000;
    }

    public void HideMap()
    {
        Hide();
    }

    public void ToggleMap()
    {
        if (Visible)
            HideMap();
        else
            ShowMap();
    }
}
