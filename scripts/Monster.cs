using Godot;
using System;

public partial class Monster : Character
{
    public void setup_from_monster_data(object data)
    {
        if (data == null) return;

        // Support both GDScript MonsterData instances and C# equivalents by using dynamic Get calls
        try
        {
            var name = data.Get("monster_name"); if (name != null) character_name = name.ToString();
            var hd = data.Get("hit_dice"); if (hd != null) damage_dice = hd.ToString();
            var cr = data.Get("challenge_rating"); if (cr != null) { /* can be used for scaling */ }
            var str = data.Get("strength"); if (str != null) strength = Convert.ToInt32(str);
            var con = data.Get("constitution"); if (con != null) constitution = Convert.ToInt32(con);
            var dex = data.Get("dexterity"); if (dex != null) dexterity = Convert.ToInt32(dex);
            // Recompute derived stats
            UpdateDerivedStats();
        }
        catch { }
    }
}
