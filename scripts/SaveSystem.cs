using Godot;
using System;

public partial class SaveSystem : Node
{
    private const string SAVE_PATH = "user://game_save.dat";
    private const string CHARACTERS_PATH = "user://characters/";

    public static bool HasSaveData()
    {
        return FileAccess.FileExists(SAVE_PATH);
    }

    public static Resource LoadLastCharacter()
    {
        if (!FileAccess.FileExists(SAVE_PATH)) return null;
        var file = FileAccess.Open(SAVE_PATH, FileAccess.ModeFlags.Read);
        if (file == null) return null;
        var json = file.GetAsText();
        file.Close();
        var parsed = JSON.Parse(json);
        if (parsed == null || parsed.Result != Error.Ok) return null;
        var data = parsed.Result == Error.Ok ? parsed.GetData() : null;
        if (data == null) return null;
        var dict = data as Godot.Collections.Dictionary;
        if (dict == null || !dict.Contains("last_character_file")) return null;
        var character_file = dict["last_character_file"].ToString();
        if (!FileAccess.FileExists(character_file)) return null;
        var res = GD.Load<Resource>(character_file);
        return res;
    }

    public static bool SaveGameState(Resource characterData)
    {
        try
        {
            // Ensure characters directory exists
            if (!DirAccess.DirExistsAbsolute(CHARACTERS_PATH))
                DirAccess.MakeDirRecursiveAbsolute(CHARACTERS_PATH);

            // Save character resource to characters folder
            var name = "character";
            try { name = characterData.Get("character_name").ToString().ToLower().Replace(" ", "_"); } catch { }
            var character_save_path = CHARACTERS_PATH + name + ".tres";
            var err = ResourceSaver.Save(character_save_path, characterData);

            // Save game state JSON
            var game_state = new Godot.Collections.Dictionary();
            game_state["last_character_name"] = name;
            game_state["last_character_file"] = character_save_path;
            game_state["last_played_timestamp"] = (long)Time.GetUnixTimeFromSystem();

            var file = FileAccess.Open(SAVE_PATH, FileAccess.ModeFlags.Write);
            if (file == null) return false;
            var json = JSON.Print(game_state);
            file.StoreString(json);
            file.Close();
            GD.Print("Game state saved successfully!");
            return err == Error.Ok;
        }
        catch (Exception ex)
        {
            GD.PrintErr("SaveGameState exception: " + ex.Message);
            return false;
        }
    }

    // Provide lowercase, snake_case wrappers for GDScript compatibility
    public static bool has_save_data() => HasSaveData();
    public static Resource load_last_character() => LoadLastCharacter();
    public static bool save_game_state(Resource characterData) => SaveGameState(characterData);
}
