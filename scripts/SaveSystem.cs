using Godot;
using System;
using System.IO;
using System.Text.Json;

public partial class SaveSystem : Node
{
    private const string SAVE_PATH = "user://game_save.dat";
    private const string CHARACTERS_PATH = "user://characters/";

    // Minimal implementations to keep the C# autoload working.
    // These can be expanded later to use proper JSON and Resource saving.
    public static bool HasSaveData()
    {
        return Godot.FileAccess.FileExists(SAVE_PATH);
    }

    public static Resource LoadLastCharacter()
    {
        try
        {
            if (!Godot.FileAccess.FileExists(SAVE_PATH))
                return null;

            using var fa = Godot.FileAccess.Open(SAVE_PATH, Godot.FileAccess.ModeFlags.Read);
            if (fa == null)
                return null;
            var json = fa.GetAsText();
            fa.Close();

            if (string.IsNullOrEmpty(json))
                return null;

            using var doc = JsonDocument.Parse(json);
            if (!doc.RootElement.TryGetProperty("last_character_file", out var elem))
                return null;
            var characterFile = elem.GetString();
            if (string.IsNullOrEmpty(characterFile))
                return null;

            if (!Godot.FileAccess.FileExists(characterFile))
                return null;

            var res = GD.Load<Resource>(characterFile);
            return res;
        }
        catch (Exception ex)
        {
            GD.PrintErr($"SaveSystem.LoadLastCharacter exception: {ex.Message}");
            return null;
        }
    }

    public static bool SaveGameState(Resource characterData)
    {
        try
        {
            if (characterData == null)
                return false;

            // Ensure characters directory exists
            try
            {
                Godot.DirAccess.MakeDirRecursiveAbsolute(CHARACTERS_PATH);
            }
            catch
            {
                // ignore
            }

            // Generate a safe filename for the character
            var name = DateTime.UtcNow.ToString("yyyyMMddHHmmss");
            try
            {
                // Try to get a character_name property if the resource exposes it via Get
                var maybe = characterData.Get("character_name");
                var s = maybe.ToString();
                if (!string.IsNullOrEmpty(s))
                {
                    name = s.ToLower().Replace(' ', '_');
                }
            }
            catch { }

            var characterSavePath = CHARACTERS_PATH + name + ".tres";

            // Save the Resource to the characters folder (ResourceSaver expects Resource first)
            var err = ResourceSaver.Save(characterData, characterSavePath);

            // Build a tiny JSON state describing the last character
            var state = new
            {
                last_character_name = name,
                last_character_file = characterSavePath,
                last_played_timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds()
            };

            var json = JsonSerializer.Serialize(state);

            using var fa = Godot.FileAccess.Open(SAVE_PATH, Godot.FileAccess.ModeFlags.Write);
            if (fa == null)
                return false;
            fa.StoreString(json);
            fa.Close();

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
