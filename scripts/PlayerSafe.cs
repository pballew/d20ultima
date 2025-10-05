using Godot;
using System;

public partial class PlayerSafe : Node2D
{
    [Signal] public delegate void movement_finished();
    [Signal] public delegate void encounter_started();

    public void load_from_character_data(object data) { }
    public Godot.Collections.Dictionary save_to_character_data() { return new Godot.Collections.Dictionary(); }
}
