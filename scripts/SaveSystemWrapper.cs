using Godot;
using System;

public partial class SaveSystemWrapper : Node
{
    // Simple bridges that forward to the main SaveSystem C# implementation.
    public static bool has_save_data()
    {
        return SaveSystem.HasSaveData();
    }

    public static Resource load_last_character()
    {
        return SaveSystem.LoadLastCharacter();
    }

    public static bool save_game_state(Resource characterData)
    {
        return SaveSystem.SaveGameState(characterData);
    }
}
