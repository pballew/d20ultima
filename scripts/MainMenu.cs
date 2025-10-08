using Godot;
using System;

public partial class MainMenu : Control
{
    private Button _mapButton;
    private MapPanel _mapPanel;

    public override void _Ready()
    {
        // Wire up the Map button (if present) to toggle the MapPanel instance
        _mapButton = GetNodeOrNull<Button>("VBoxContainer/MapButton");
        _mapPanel = GetNodeOrNull<MapPanel>("MapPanel");
        if (_mapButton != null && _mapPanel != null)
        {
            _mapButton.Pressed += () => { _mapPanel.ToggleMap(); };
        }
    }

    // GDScript compatibility: methods expected by GameController and other callers
    // Keep them minimal to avoid changing runtime behavior.
    public void move_to_front()
    {
        // Ensure the menu is on top visually; match previous z_index used in logs
        this.ZIndex = 200;
        this.Show();
    }

    public void show_main_menu()
    {
        // Minimal implementation: ensure visible and ready state. Detailed UI setup
        // is handled by the C# port when needed.
        this.Show();
    }
}
