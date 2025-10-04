using Godot;
using System;

public partial class Player : Character
{
    [Export] public float movement_speed = 200.0f;
    [Export] public bool encounters_enabled = false;
    [Export] public float camera_smooth_speed = 8.0f;

    public Vector2 current_target_position;
    public bool is_moving = false;
    public bool is_in_combat = false;

    public override void _Ready()
    {
        base._Ready();
        current_target_position = GlobalPosition;
    }

    public void LoadFromCharacterData(Resource charData)
    {
        // Minimal stub: real CharacterData conversion would go here
        GD.Print("LoadFromCharacterData called (stub)");
    }

    public Resource SaveToCharacterData()
    {
        GD.Print("SaveToCharacterData called (stub)");
        return null;
    }

    public void EnterCombat()
    {
        is_in_combat = true;
    }

    public void ExitCombat()
    {
        is_in_combat = false;
    }

    public void MoveToTile(Vector2 newPos)
    {
        if (!is_moving)
        {
            current_target_position = newPos;
            is_moving = true;
        }
    }
}
