using Godot;
using System;

public partial class Player : Character
{
    // Player extends Character in C# so C# code that expects Player can operate.
    // If the authoritative implementation lives in GDScript, the engine will
    // still have a Player object inheriting Character available for downcasts.

    public Godot.Collections.Dictionary save_to_character_data()
    {
        var dict = new Godot.Collections.Dictionary();
        dict["character_name"] = character_name;
        dict["level"] = level;
        dict["current_health"] = current_health;
        dict["max_health"] = max_health;
        dict["strength"] = strength;
        dict["dexterity"] = dexterity;
        dict["constitution"] = constitution;
        dict["intelligence"] = intelligence;
        dict["wisdom"] = wisdom;
        dict["charisma"] = charisma;
        dict["experience"] = experience;
        return dict;
    }
}
