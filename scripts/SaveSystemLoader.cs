using Godot;
using System;

public partial class SaveSystemLoader : Node
{
    public void LoadFromScene(string tscnPath)
    {
        try
        {
            if (string.IsNullOrEmpty(tscnPath)) return;
            if (!FileAccess.FileExists(tscnPath)) return;
            var ps = GD.Load<PackedScene>(tscnPath);
            if (ps == null) return;
            var inst = ps.Instantiate();
            if (inst != null)
                GetTree().Root.AddChild(inst);
        }
        catch { }
    }
}
