using Godot;
using System;

public partial class PlayerStatsUI : Control
{
    public Character player;

    public override void _Ready()
    {
        // Minimal stub to be expanded; keep node safe for scenes
    }

    public void SetupPlayerStats(Character p)
    {
        player = p;
        UpdateAllStats();
    }

    public void UpdateAllStats()
    {
        if (player == null) return;
        // Update labels if connected - left as exercise when converting full UI
    }
}
