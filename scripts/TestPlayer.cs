using Godot;
using System;

public partial class TestPlayer : Node2D
{
    public override void _Ready()
    {
        GD.Print("TestPlayer: _Ready() called — C# script instantiated successfully.");
    }
}
