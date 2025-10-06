using Godot;
using System;
using System.Collections.Generic;

public partial class PlayerIconFactory : Node
{
    private Dictionary<string, ImageTexture> _cache = new Dictionary<string, ImageTexture>();
    private const int ICON_SIZE = 32;

    private Dictionary<string, (Color skin, Color primary)> racePalettes = new Dictionary<string, (Color, Color)>()
    {
        {"Human", (new Color(0.9f,0.75f,0.6f), new Color(0.2f,0.3f,0.8f))},
        {"Elf", (new Color(0.85f,0.8f,0.7f), new Color(0.1f,0.6f,0.2f))},
        {"Dwarf", (new Color(0.8f,0.65f,0.5f), new Color(0.6f,0.3f,0.1f))},
        {"Halfling", (new Color(0.9f,0.7f,0.55f), new Color(0.4f,0.5f,0.2f))},
        {"Gnome", (new Color(0.85f,0.75f,0.6f), new Color(0.7f,0.2f,0.7f))},
        {"Half-Elf", (new Color(0.87f,0.77f,0.63f), new Color(0.25f,0.45f,0.85f))},
        {"Half-Orc", (new Color(0.55f,0.7f,0.45f), new Color(0.35f,0.5f,0.2f))},
        {"Dragonborn", (new Color(0.6f,0.4f,0.2f), new Color(0.8f,0.3f,0.15f))},
        {"Tiefling", (new Color(0.55f,0.25f,0.25f), new Color(0.5f,0.1f,0.6f))}
    };

    private Dictionary<string, (Color color, string type)> classGlyphs = new Dictionary<string, (Color, string)>()
    {
        {"Fighter", (new Color(0.7f,0.7f,0.7f), "sword")},
        {"Rogue", (new Color(0.6f,0.6f,0.6f), "dagger")},
        {"Wizard", (new Color(0.9f,0.9f,1.0f), "staff")},
        {"Cleric", (new Color(1.0f,1.0f,0.8f), "mace")},
        {"Ranger", (new Color(0.3f,0.7f,0.3f), "bow")},
        {"Barbarian", (new Color(0.8f,0.6f,0.3f), "axe")}
    };

    public ImageTexture GenerateIcon(string raceName, string charClassName)
    {
        var key = raceName + "_" + charClassName;
        if (_cache.ContainsKey(key)) return _cache[key];

    var image = Image.CreateEmpty(ICON_SIZE, ICON_SIZE, false, Image.Format.Rgba8);
    image.Fill(new Color(0,0,0,0));

        var palette = racePalettes.ContainsKey(raceName) ? racePalettes[raceName] : racePalettes["Human"];
        var glyph = classGlyphs.ContainsKey(charClassName) ? classGlyphs[charClassName] : classGlyphs["Fighter"];

        DrawBaseBody(image, palette);
        DrawClassEmblem(image, glyph);

        var tex = ImageTexture.CreateFromImage(image);
        // Not caching by default to conserve memory (behaviour matched to GDScript)
        return tex;
    }

    private void DrawBaseBody(Image image, (Color skin, Color primary) palette)
    {
        var skin = palette.skin;
        var primary = palette.primary;
        int cx = ICON_SIZE / 2;
        int cy = 8;
        int r = 5;

        for (int x = 0; x < ICON_SIZE; x++)
        {
            for (int y = 0; y < ICON_SIZE; y++)
            {
                var dist = (new Vector2(x,y) - new Vector2(cx,cy)).Length();
                if (dist <= r)
                    image.SetPixel(x, y, skin);
            }
        }

        for (int x = cx-3; x < cx+3; x++)
            for (int y = cy+3; y < cy+13; y++)
                if (x >= 0 && x < ICON_SIZE && y >= 0 && y < ICON_SIZE)
                    image.SetPixel(x, y, primary);

        for (int x = cx-2; x < cx; x++)
            for (int y = cy+13; y < cy+20; y++)
                if (x >= 0 && x < ICON_SIZE && y >= 0 && y < ICON_SIZE)
                    image.SetPixel(x, y, new Color(0.15f,0.15f,0.2f));

        for (int x = cx; x < cx+2; x++)
            for (int y = cy+13; y < cy+20; y++)
                if (x >= 0 && x < ICON_SIZE && y >= 0 && y < ICON_SIZE)
                    image.SetPixel(x, y, new Color(0.15f,0.15f,0.2f));
    }

    private void DrawClassEmblem(Image image, (Color color, string type) glyph)
    {
        var color = glyph.color;
        var type = glyph.type;
        switch (type)
        {
            case "sword":
                for (int y=10;y<22;y++) image.SetPixel(24, y, color);
                for (int x=22;x<26;x++) image.SetPixel(x, 10, color);
                break;
            case "dagger":
                for (int y=12;y<20;y++) image.SetPixel(23, y, color);
                break;
            case "staff":
                for (int y=6;y<25;y++) image.SetPixel(25, y, color);
                for (int i=0;i<2;i++) image.SetPixel(24+i, 6, color);
                break;
            case "mace":
                for (int y=9;y<23;y++) image.SetPixel(24, y, color);
                for (int dx=-1; dx<2; dx++)
                    for (int dy=-1; dy<2; dy++)
                        image.SetPixel(24+dx, 9+dy, color);
                break;
            case "bow":
                for (int y=9;y<23;y++) image.SetPixel(23, y, color);
                for (int y=9;y<23;y++)
                {
                    int offset = (int)Math.Round(Math.Sin((y-9)/2.0)*1.5);
                    image.SetPixel(23+offset, y, color);
                }
                break;
            case "axe":
                for (int y=9;y<22;y++) image.SetPixel(24, y, color);
                for (int x=24;x<28;x++)
                    for (int y2=9;y2<13;y2++) image.SetPixel(x, y2, color);
                break;
            default:
                for (int y=10;y<18;y++) image.SetPixel(24, y, color);
                break;
        }
    }

    public int ExportAllPlayerSprites()
    {
    var logger = GetTree()?.Root?.GetNodeOrNull<DebugLogger>("DebugLogger");
    if (logger != null) logger.Info("Generating all player sprite combinations...");
    var dir = DirAccess.Open("res://");
        if (!dir.DirExists("assets/player_sprites"))
            dir.MakeDirRecursive("assets/player_sprites");

        int total = 0;
        foreach (var race in racePalettes.Keys)
        {
            foreach (var cls in classGlyphs.Keys)
            {
                var tex = GenerateIcon(race, cls);
                var img = tex.GetImage();
                var filename = $"assets/player_sprites/{race}_{cls}.png";
                var res = img.SavePng("res://" + filename);
                if (res == Error.Ok)
                {
                    if (logger != null) logger.Info("Generated: " + filename);
                    total++;
                }
                else
                {
                    if (logger != null) logger.Info("Failed to save: " + filename);
                }
            }
        }

        if (logger != null) logger.Info($"Generated {total} player sprites in assets/player_sprites/");
        return total;
    }

    public void ClearCache()
    {
        _cache.Clear();
        var logger = GetTree()?.Root?.GetNodeOrNull<DebugLogger>("DebugLogger");
        if (logger != null) logger.Info("PlayerIconFactory cache cleared");
    }
}

// snake_case wrappers for GDScript compatibility
public partial class PlayerIconFactory
{
    public ImageTexture generate_icon(string race_name, string char_class_name)
    {
        return GenerateIcon(race_name, char_class_name);
    }

    public int export_all_player_sprites()
    {
        return ExportAllPlayerSprites();
    }

    public void clear_cache()
    {
        ClearCache();
    }
}
