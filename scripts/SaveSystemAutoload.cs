using Godot;
using System;

public partial class SaveSystemAutoload : Node
{
    public override void _Ready()
    {
        // If a SaveSystem autoload exists as a scene, nothing to do; otherwise ensure SaveSystem node is available at /root/SaveSystem
        var existing = GetNodeOrNull("/root/SaveSystem");
        if (existing == null)
        {
            var ss = new SaveSystem();
            ss.Name = "SaveSystem";
            GetTree().Root.AddChild(ss);
        }
    }
}
