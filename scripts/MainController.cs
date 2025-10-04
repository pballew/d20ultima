using Godot;
using System;

public partial class MainController : Node2D
{
    Player player;
    CombatManager combatManager;

    public override void _Ready()
    {
        AddToGroup("main");
        player = GetNodeOrNull<Player>("Player");
        combatManager = GetNodeOrNull<CombatManager>("CombatManager");
        if (player != null)
        {
            player.Connect("encounter_started", Callable.From(this, nameof(OnEncounterStarted)));
        }
    }

    public void OnEncounterStarted()
    {
        GD.Print("Encounter started (stub)");
    }
}
