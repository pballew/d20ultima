using Godot;
using System;

public partial class MonoSmoke : Node
{
	public override void _Ready()
	{
		GD.Print("[CS] MonoSmoke: C# runtime active and script _Ready called.");
	}
}
