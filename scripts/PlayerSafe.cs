using Godot;
using System;

public partial class PlayerSafe : Node2D
{
    [Signal] public delegate void MovementFinishedEventHandler();
    [Signal] public delegate void EncounterStartedEventHandler();

    public void load_from_character_data(object data) { }
    public Godot.Collections.Dictionary save_to_character_data() { return new Godot.Collections.Dictionary(); }
}
