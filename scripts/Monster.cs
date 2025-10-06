using Godot;
using System;

public partial class Monster : Character
{
    public void setup_from_monster_data(object data)
    {
        if (data == null) return;

        try
        {
            if (data is Resource r)
            {
                object name = r.Get("monster_name"); if (name != null) character_name = name.ToString();
                object hd = r.Get("hit_dice"); if (hd != null) damage_dice = hd.ToString();
                object cr = r.Get("challenge_rating"); if (cr != null) { }
                object str = r.Get("strength"); if (str != null) strength = Convert.ToInt32(str);
                object con = r.Get("constitution"); if (con != null) constitution = Convert.ToInt32(con);
                object dex = r.Get("dexterity"); if (dex != null) dexterity = Convert.ToInt32(dex);
            }
            else
            {
                // Attempt to reflectively call Get if present (for dynamic GDScript objects)
                var method = data.GetType().GetMethod("Get");
                if (method != null)
                {
                    object nameObj = method.Invoke(data, new object[] { "monster_name" }); if (nameObj != null) character_name = nameObj.ToString();
                    object hdObj = method.Invoke(data, new object[] { "hit_dice" }); if (hdObj != null) damage_dice = hdObj.ToString();
                    object strObj = method.Invoke(data, new object[] { "strength" }); if (strObj != null) strength = Convert.ToInt32(strObj);
                    object conObj = method.Invoke(data, new object[] { "constitution" }); if (conObj != null) constitution = Convert.ToInt32(conObj);
                    object dexObj = method.Invoke(data, new object[] { "dexterity" }); if (dexObj != null) dexterity = Convert.ToInt32(dexObj);
                }
            }

            UpdateDerivedStats();
        }
        catch { }
    }
}
