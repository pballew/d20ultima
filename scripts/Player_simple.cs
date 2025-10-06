using Godot;
using System;

public partial class Player : Character
{
    [Signal]
    public delegate void MovementFinishedEventHandler();

    [Signal]
    public delegate void EncounterStartedEventHandler();

    [Signal]
    public delegate void CampingStartedEventHandler();

    [Signal]
    public delegate void TownNameDisplayEventHandler(string townName);

    private const int TILE_SIZE = 64;
    private Vector2 _targetPosition;
    private bool _isMoving = false;
    private AnimatedSprite2D _anim;

    public override void _Ready()
    {
        base._Ready();
        _anim = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
    }

    public override void _Process(double delta)
    {
        if (_isMoving)
        {
            GlobalPosition = GlobalPosition.MoveToward(_targetPosition, 300.0f * (float)delta);
            if (GlobalPosition.DistanceTo(_targetPosition) < 1.0f)
            {
                GlobalPosition = _targetPosition;
                _isMoving = false;
                EmitSignal("MovementFinishedEventHandler");
            }
        }
    }

    public void MoveToTile(Vector2 tilePosition)
    {
        if (!_isMoving)
        {
            _targetPosition = tilePosition;
            _isMoving = true;
        }
    }

    public void load_from_character_data(Godot.Collections.Dictionary data)
    {
        // Basic implementation - can be expanded later
        if (data.ContainsKey("position"))
        {
            var pos = data["position"].AsVector2();
            GlobalPosition = pos;
        }
    }

    public Godot.Collections.Dictionary save_to_character_data()
    {
        var data = new Godot.Collections.Dictionary();
        data["position"] = GlobalPosition;
        return data;
    }

    // Wrapper methods for compatibility
    public void set_camera_target(Vector2 pos) 
    {
        // Basic implementation
    }

    public float get_encounter_difficulty_multiplier_for_terrain(int terrainType) 
    {
        return 1.0f; // Default difficulty
    }

    public string get_encounter_difficulty_for_terrain(int terrainType)
    {
        switch (terrainType)
        {
            case 4:
            case 10:
                return "forest";
            case 5:
            case 11:
                return "mountain";
            case 13:
                return "swamp";
            case 3:
            case 7:
            case 8:
                return "water";
            case 14:
                return "civilized";
            default:
                return "wilderness";
        }
    }
}