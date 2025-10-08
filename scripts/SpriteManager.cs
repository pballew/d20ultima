using Godot;
using System.Collections.Generic;

public partial class SpriteManager : Node
{
    public Godot.Collections.Dictionary base_paths = new Godot.Collections.Dictionary()
    {
        { "player", "res://assets/player_sprites/" },
        { "monster", "res://assets/monster_sprites/" },
        { "other", "res://assets/sprites/" }
    };

    private Godot.Collections.Dictionary _cache = new Godot.Collections.Dictionary();
    private Texture2D _placeholder_texture = null;

    public override void _Ready()
    {
        _placeholder_texture = _create_placeholder();
    }

    private string _resolve_path(string category, string name)
    {
    var basePath = base_paths.ContainsKey(category) ? (string)base_paths[category] : (string)base_paths["other"];
        if (string.IsNullOrEmpty(name)) return "";
        if (name.StartsWith("res://")) return name;
        if (!name.Contains(".")) return basePath + name + ".png";
        return basePath + name;
    }

    private Texture2D _load_texture(string path)
    {
        if (string.IsNullOrEmpty(path)) return _placeholder_texture;
    if (_cache.ContainsKey(path)) return (Texture2D)_cache[path];
        var tex = ResourceLoader.Load(path) as Texture2D;
        if (tex == null)
        {
            GD.PushWarning($"SpriteManager: failed to load '{path}'");
            _cache[path] = _placeholder_texture;
            return _placeholder_texture;
        }
        _cache[path] = tex;
        return tex;
    }

    public Texture2D get_texture(string category, string name)
    {
        var path = _resolve_path(category, name);
        return _load_texture(path);
    }

    public Texture2D get_player_texture(string name, Vector2 target_size)
    {
        return get_scaled_texture("player", name, target_size);
    }

    public Texture2D get_monster_texture(string name, Vector2 target_size)
    {
        return get_scaled_texture("monster", name, target_size);
    }

    public Texture2D get_scaled_texture(string category, string name, Vector2 target_size)
    {
        var path = _resolve_path(category, name);
        var original = _load_texture(path);
        if (target_size == Vector2.Zero || original == _placeholder_texture) return original;

        var key = $"{category}|{name}|{(int)target_size.X}|{(int)target_size.Y}";
        if (_cache.ContainsKey(key)) return (Texture2D)_cache[key];

        // Defer actual resizing for now; return original texture to keep behavior stable.
        return original;
    }

    public Sprite2D render_to_sprite(Sprite2D sprite_node, string category = "other", string name = "", Vector2 target_size = default, Color? modulate = null, bool centered = true)
    {
        if (sprite_node == null)
        {
            sprite_node = new Sprite2D();
        }
        var tex = get_scaled_texture(category, name, target_size == default ? Vector2.Zero : target_size);
        if (tex == null) tex = _placeholder_texture;
        sprite_node.Texture = tex;
        sprite_node.Modulate = modulate ?? new Color(1,1,1,1);
        sprite_node.Centered = centered;

        if (target_size != default && tex.GetSize() != Vector2.Zero)
        {
            var texSize = tex.GetSize();
            var scale = new Vector2(target_size.X / texSize.X, target_size.Y / texSize.Y);
            sprite_node.Scale = scale;
        }
        else
        {
            sprite_node.Scale = Vector2.One;
        }
        return sprite_node;
    }

    private Texture2D _create_placeholder()
    {
    var img = Image.CreateEmpty(8,8,false,Image.Format.Rgba8);
        for (int y=0;y<img.GetHeight();y++)
            for (int x=0;x<img.GetWidth();x++)
                img.SetPixel(x,y, ((x+y)%2)==0 ? new Color(1,0,1,1) : new Color(0,0,0,1));
    // no unlock required for the created image API in this context
        return ImageTexture.CreateFromImage(img);
    }
}
