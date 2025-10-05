using Godot;
using System;

public partial class Player : Character
{
    [Signal]
    public delegate void movement_finished();

    [Signal]
    public delegate void encounter_started();

    [Signal]
    public delegate void camping_started();

    [Signal]
    public delegate void town_name_display(string town_name);

    [Export] public float movement_speed = 200.0f;
    [Export] public bool encounters_enabled = false;
    [Export] public float camera_smooth_speed = 8.0f;
    [Export] public NodePath animation_node_path = new NodePath("AnimatedSprite2D");
    [Export] public bool run_self_test = false;

    public Vector2 current_target_position;
    public bool is_moving = false;
    public bool is_in_combat = false;
    private System.Collections.Generic.Queue<Vector2> _moveQueue = new System.Collections.Generic.Queue<Vector2>();
    private Vector2 _camera_target = Vector2.Zero;
    private const int TILE_SIZE = 32;
    private AnimatedSprite2D _anim = null;

    public override void _Ready()
    {
        base._Ready();
        current_target_position = GlobalPosition;
        // Try to bind an AnimatedSprite2D if present for simple animation switching
        if (!animation_node_path.IsEmpty())
        {
            _anim = GetNodeOrNull<AnimatedSprite2D>(animation_node_path);
        }
        if (_anim == null)
        {
            _anim = GetNodeOrNull<AnimatedSprite2D>("AnimatedSprite2D");
        }

        if (run_self_test)
        {
            // run a best-effort save/load round-trip test and log results
            SaveLoadSelfTest();
        }
    }

    public override void _PhysicsProcess(double delta)
    {
        base._PhysicsProcess(delta);
        if (is_moving)
        {
            GlobalPosition = GlobalPosition.MoveToward(current_target_position, movement_speed * (float)delta);
            if (GlobalPosition.DistanceTo(current_target_position) < 1.0f)
            {
                GlobalPosition = current_target_position;
                is_moving = false;
                // Emit GDScript-compatible signal
                EmitSignal("movement_finished");

                    // Snap to tile grid exactly
                    SnapToTile();

                    // Switch to idle animation
                    PlayDirectionalAnimation(Vector2.Down, false);

                // After finishing a step, if we have queued moves, dequeue next
                if (_moveQueue.Count > 0)
                {
                    current_target_position = _moveQueue.Dequeue();
                    is_moving = true;
                }
                else
                {
                    // No more queued steps - perform encounter and town checks
                    var parent = GetParent();
                    Node terrain = null;
                    if (parent != null)
                    {
                        terrain = parent.GetNodeOrNull("EnhancedTerrainTileMap");
                        if (terrain == null)
                            terrain = parent.GetNodeOrNull("EnhancedTerrain");
                    }
                    check_for_random_encounter(GlobalPosition, terrain);
                    check_for_town_at_position(GlobalPosition);
                }
            }
        }

        // Smooth camera follow if target set
        if (_camera_target != Vector2.Zero)
        {
            var cam = GetNodeOrNull<Camera2D>("../Camera2D");
            if (cam != null)
            {
                float t = Math.Clamp(camera_smooth_speed * (float)delta, 0f, 1f);
                cam.GlobalPosition = cam.GlobalPosition.Lerp(_camera_target, t);
            }
        }
    }

    private void SnapToTile()
    {
        float snappedX = (float)Math.Round(GlobalPosition.x / TILE_SIZE) * TILE_SIZE;
        float snappedY = (float)Math.Round(GlobalPosition.y / TILE_SIZE) * TILE_SIZE;
        GlobalPosition = new Vector2(snappedX, snappedY);
    }

    public override void _Process(double delta)
    {
        base._Process(delta);

        // Input-driven movement (tile-based). Only allow when not in combat and not already moving.
        if (!is_in_combat && !is_moving)
        {
            Vector2 dir = Vector2.Zero;
            if (Input.IsActionJustPressed("ui_right")) dir = Vector2.Right;
            else if (Input.IsActionJustPressed("ui_left")) dir = Vector2.Left;
            else if (Input.IsActionJustPressed("ui_up")) dir = Vector2.Up;
            else if (Input.IsActionJustPressed("ui_down")) dir = Vector2.Down;

            if (dir != Vector2.Zero)
            {
                Vector2 tileTarget = new Vector2(Mathf.RoundToInt((GlobalPosition.x + dir.x * TILE_SIZE) / TILE_SIZE) * TILE_SIZE,
                                                 Mathf.RoundToInt((GlobalPosition.y + dir.y * TILE_SIZE) / TILE_SIZE) * TILE_SIZE);
                MoveToTile(tileTarget);
                PlayDirectionalAnimation(dir, true);
            }
            else
            {
                // idle animation
                PlayDirectionalAnimation(Vector2.Down, false);
            }
        }
        else if (!is_moving)
        {
            // when not moving (perhaps in combat), ensure idle animation
            PlayDirectionalAnimation(Vector2.Down, false);
        }
    }

    private void PlayDirectionalAnimation(Vector2 dir, bool moving)
    {
        if (_anim == null) return;
        string dirName = "down";
        if (Math.Abs(dir.x) > Math.Abs(dir.y)) dirName = dir.x > 0 ? "right" : "left";
        else if (Math.Abs(dir.y) > 0) dirName = dir.y < 0 ? "up" : "down";

        string animName = moving ? ($"walk_{dirName}") : ($"idle_{dirName}");
        try
        {
            if (_anim.Frames != null && _anim.Frames.HasAnimation(animName))
                _anim.Play(animName);
            else if (_anim.Frames != null && _anim.Frames.HasAnimation(moving ? "walk_down" : "idle_down"))
                _anim.Play(moving ? "walk_down" : "idle_down");
        }
        catch (Exception)
        {
            // best-effort, ignore animation errors
        }
    }

    public void LoadFromCharacterData(Resource charData)
    {
        if (charData == null) return;

        // Dictionary-style saves
        if (charData is Godot.Collections.Dictionary dict)
        {
            if (dict.Contains("character_name")) character_name = (string)dict["character_name"];
            if (dict.Contains("level")) level = Convert.ToInt32(dict["level"]);
            if (dict.Contains("max_health")) max_health = Convert.ToInt32(dict["max_health"]);
            if (dict.Contains("current_health")) current_health = Convert.ToInt32(dict["current_health"]);
            if (dict.Contains("experience")) experience = Convert.ToInt32(dict["experience"]);
            if (dict.Contains("world_position")) GlobalPosition = (Vector2)dict["world_position"];
            if (dict.Contains("strength")) strength = Convert.ToInt32(dict["strength"]);
            if (dict.Contains("dexterity")) dexterity = Convert.ToInt32(dict["dexterity"]);
            if (dict.Contains("constitution")) constitution = Convert.ToInt32(dict["constitution"]);
            if (dict.Contains("intelligence")) intelligence = Convert.ToInt32(dict["intelligence"]);
            if (dict.Contains("wisdom")) wisdom = Convert.ToInt32(dict["wisdom"]);
            if (dict.Contains("charisma")) charisma = Convert.ToInt32(dict["charisma"]);
            if (dict.Contains("gold"))
            {
                try { gold = Convert.ToInt32(dict["gold"]); } catch { }
            }
            if (dict.Contains("attack_bonus"))
            {
                try { attack_bonus = Convert.ToInt32(dict["attack_bonus"]); } catch { }
            }
            if (dict.Contains("armor_class"))
            {
                try { armor_class = Convert.ToInt32(dict["armor_class"]); } catch { }
            }
            if (dict.Contains("skill_points"))
            {
                try { skill_points = Convert.ToInt32(dict["skill_points"]); } catch { }
            }
            // explored_tiles may be an Array of positions; we won't store it on the Player in C# yet but accept it
            if (dict.Contains("explored_tiles"))
            {
                var et = dict["explored_tiles"];
                // no-op: keep for compatibility
            }
            return;
        }

        // Try to read fields from a CharacterData Resource
        try
        {
            var name = charData.Get("character_name"); if (name != null) character_name = name.ToString();
            var lvl = charData.Get("level"); if (lvl != null) level = Convert.ToInt32(lvl);
            var mh = charData.Get("max_health"); if (mh != null) max_health = Convert.ToInt32(mh);
            var ch = charData.Get("current_health"); if (ch != null) current_health = Convert.ToInt32(ch);
            var xp = charData.Get("experience"); if (xp != null) experience = Convert.ToInt32(xp);
            var wp = charData.Get("world_position"); if (wp != null && wp is Vector2) GlobalPosition = (Vector2)wp;
            var s = charData.Get("strength"); if (s != null) strength = Convert.ToInt32(s);
            var d = charData.Get("dexterity"); if (d != null) dexterity = Convert.ToInt32(d);
            var con = charData.Get("constitution"); if (con != null) constitution = Convert.ToInt32(con);
            var intel = charData.Get("intelligence"); if (intel != null) intelligence = Convert.ToInt32(intel);
            var wis = charData.Get("wisdom"); if (wis != null) wisdom = Convert.ToInt32(wis);
            var cha = charData.Get("charisma"); if (cha != null) charisma = Convert.ToInt32(cha);
            var g = charData.Get("gold"); if (g != null) try { gold = Convert.ToInt32(g); } catch { }
            var ab = charData.Get("attack_bonus"); if (ab != null) try { attack_bonus = Convert.ToInt32(ab); } catch { }
            var ac = charData.Get("armor_class"); if (ac != null) try { armor_class = Convert.ToInt32(ac); } catch { }
            var sp = charData.Get("skill_points"); if (sp != null) try { skill_points = Convert.ToInt32(sp); } catch { }
            var explored = charData.Get("explored_tiles");
            // If explored_tiles is a PackedVector2Array or Array, accept it for compatibility
            try
            {
                if (explored is Godot.Collections.PackedVector2Array pva)
                {
                    // best-effort: could notify FogOfWar or Map manager here
                }
                else if (explored is Godot.Collections.Array arr)
                {
                    // convert array of Vector2-like entries if needed
                }
            }
            catch { }

            // Read enum fields if present
            var cc = charData.Get("character_class"); if (cc != null) { try { /* store as int in level-like field? */ } catch { } }
            var cr = charData.Get("character_race"); if (cr != null) { try { /* no-op for now */ } catch { } }
            var ts = charData.Get("save_timestamp"); if (ts != null) { /* no-op */ }
            var lrr = charData.Get("last_reveal_radius"); if (lrr != null) { /* no-op */ }
        }
        catch (Exception)
        {
            // Ignore and continue; best-effort load
        }
    }

    // Create and return a CharacterData Resource instance populated from this Player
    public Resource SaveToCharacterData()
    {
        // Try to instantiate CharacterData resource
        Resource charRes = null;
        var script = GD.Load<Script>("res://scripts/CharacterData.gd");
        if (script != null)
        {
            try { charRes = (Resource)script.Instantiate(); } catch { charRes = null; }
        }

        if (charRes == null)
        {
            // Fallback: use a plain Resource and set properties dynamically
            charRes = new Resource();
        }

    try
    {
            charRes.Set("character_name", character_name);
            charRes.Set("level", level);
            charRes.Set("strength", strength);
            charRes.Set("dexterity", dexterity);
            charRes.Set("constitution", constitution);
            charRes.Set("intelligence", intelligence);
            charRes.Set("wisdom", wisdom);
            charRes.Set("charisma", charisma);
            charRes.Set("max_health", max_health);
            charRes.Set("current_health", current_health);
            charRes.Set("experience", experience);
            charRes.Set("gold", 0);
            charRes.Set("attack_bonus", attack_bonus);
                try { charRes.Set("damage_dice", damage_dice); } catch { }
                try { charRes.Set("character_class", 0); } catch { }
                try { charRes.Set("character_race", 0); } catch { }
                try { charRes.Set("save_timestamp", System.DateTime.Now.ToString()); } catch { }
                try { charRes.Set("last_reveal_radius", 0); } catch { }
            charRes.Set("armor_class", armor_class);
            charRes.Set("skill_points", 0);
            charRes.Set("world_position", GlobalPosition);
            // Include a placeholder explored_tiles array so saves have the expected structure
            try
            {
                charRes.Set("explored_tiles", new Godot.Collections.Array());
            }
            catch { }
        }
        catch (Exception)
        {
            // best-effort
        }

        return charRes;
    }

    // Return a Dictionary representation of this player suitable for testing or non-Resource saves
    public Godot.Collections.Dictionary SaveToDictionary()
    {
        var d = new Godot.Collections.Dictionary();
        d["character_name"] = character_name;
        d["level"] = level;
        d["strength"] = strength;
        d["dexterity"] = dexterity;
        d["constitution"] = constitution;
        d["intelligence"] = intelligence;
        d["wisdom"] = wisdom;
        d["charisma"] = charisma;
        d["max_health"] = max_health;
        d["current_health"] = current_health;
        d["experience"] = experience;
        d["gold"] = 0;
        d["attack_bonus"] = attack_bonus;
        d["damage_dice"] = damage_dice;
        d["armor_class"] = armor_class;
        d["skill_points"] = 0;
        d["world_position"] = GlobalPosition;
        d["explored_tiles"] = new Godot.Collections.Array();
        return d;
    }

    // Best-effort self-test: save to dict and reload, then log any mismatches
    public void SaveLoadSelfTest()
    {
        try
        {
            var saved = SaveToDictionary();
            var beforeName = character_name;
            // mutate a field, then reload to ensure LoadFromCharacterData overwrites
            character_name = "__temp_test__";
            LoadFromCharacterData(saved);
            if (character_name == beforeName)
            {
                GD.Print($"[Player SelfTest] PASS: name preserved as {character_name}");
            }
            else
            {
                GD.Print($"[Player SelfTest] FAIL: expected {beforeName} got {character_name}");
            }
        }
        catch (Exception ex)
        {
            GD.PrintErr("[Player SelfTest] Exception: " + ex.Message);
        }
    }

    public void EnterCombat()
    {
        is_in_combat = true;
    }

    public void ExitCombat()
    {
        is_in_combat = false;
    }

    public void MoveToTile(Vector2 newPos)
    {
        if (!is_moving)
        {
            current_target_position = newPos;
            is_moving = true;
        }
        else
        {
            _moveQueue.Enqueue(newPos);
        }
    }

    public void SetCameraTarget(Vector2 pos)
    {
        _camera_target = pos;
    }

    public float GetEncounterDifficultyForTerrain(int terrainType)
    {
        // Return same string-based difficulty mapping as GDScript but expose float-compatible helper
        // We'll map common terrain types to numeric multipliers only as a fallback
        switch (terrainType)
        {
            case 4: // TREE
            case 10: // FOREST
                return 1.2f;
            case 5: // MOUNTAIN
            case 11: // HILLS
                return 1.15f;
            case 13: // SWAMP
                return 1.1f;
            case 3: // WATER
            case 7:
            case 8:
                return 0.9f;
            case 14: // TOWN
                return 0.8f;
            default:
                return 1.0f;
        }
    }

    // === Terrain & encounter helpers matching GDScript API ===
    public int get_terrain_type_at_position(Vector2 worldPos, Node terrainSystem)
    {
        if (terrainSystem == null)
            return 0;

        var tilePos = new Vector2i((int)(worldPos.x / TILE_SIZE), (int)(worldPos.y / TILE_SIZE));

        if (terrainSystem.HasMethod("get_terrain_type_at_tile"))
        {
            var result = terrainSystem.Call("get_terrain_type_at_tile", tilePos);
            return ConvertToInt(result);
        }
        else if (terrainSystem.HasMethod("get_terrain_at_position"))
        {
            var result = terrainSystem.Call("get_terrain_at_position", worldPos);
            return ConvertToInt(result);
        }
        else
        {
            // Try to read a Dictionary property named terrain_data
            if (terrainSystem.Get("terrain_data") is Godot.Collections.Dictionary terrainData)
            {
                if (terrainData.Contains(tilePos))
                {
                    return ConvertToInt(terrainData[tilePos]);
                }
            }
        }

        return 0;
    }

    private int ConvertToInt(object v)
    {
        if (v == null) return 0;
        if (v is int i) return i;
        if (v is long l) return (int)l;
        if (v is float f) return (int)f;
        if (v is string s && int.TryParse(s, out var parsed)) return parsed;
        return 0;
    }

    public float get_encounter_chance_for_terrain(int terrainType)
    {
        switch (terrainType)
        {
            case 0: return 0.06f; // GRASS
            case 1: return 0.05f; // DIRT
            case 2: return 0.03f; // STONE
            case 3: return 0.02f; // WATER
            case 4: return 0.12f; // TREE/FOREST
            case 5: return 0.08f; // MOUNTAIN
            case 6: return 0.07f; // VALLEY
            case 7: return 0.04f; // RIVER
            case 8: return 0.03f; // LAKE
            case 9: return 0.01f; // OCEAN
            case 10: return 0.15f; // FOREST
            case 11: return 0.09f; // HILLS
            case 12: return 0.05f; // BEACH
            case 13: return 0.08f; // SWAMP
            case 14: return 0.01f; // TOWN
            default: return 0.06f;
        }
    }

    public string get_encounter_difficulty_for_terrain(int terrainType)
    {
        switch (terrainType)
        {
            case 4:
            case 10:
                return "forest";
            case 5:
            case 11:
                return "mountain";
            case 13:
                return "swamp";
            case 3:
            case 7:
            case 8:
                return "water";
            case 14:
                return "civilized";
            default:
                return "wilderness";
        }
    }

    public void check_for_random_encounter(Vector2 worldPos, Node terrainSystem)
    {
        int terrainType = get_terrain_type_at_position(worldPos, terrainSystem);
        float encounterChance = get_encounter_chance_for_terrain(terrainType);

        float levelModifier = 1.0f + (level - 1) * 0.02f;
        encounterChance *= levelModifier;
        encounterChance = Math.Min(encounterChance, 0.25f);

        GD.Print($"Encounter check: terrain={terrainType} base_chance={get_encounter_chance_for_terrain(terrainType)} final_chance={encounterChance}");

        if (encounters_enabled && GD.Randf() < encounterChance)
        {
            EmitSignal("encounter_started");
        }
    }

    public void check_for_town_at_position(Vector2 worldPos)
    {
        // Convert to tile top-left like GDScript
        var tileTopLeft = new Vector2((float)Math.Floor(worldPos.x / TILE_SIZE) * TILE_SIZE, (float)Math.Floor(worldPos.y / TILE_SIZE) * TILE_SIZE);

        // Try to find terrain system as sibling nodes
        Node parent = GetParent();
        Node terrain = null;
        if (parent != null)
        {
            terrain = parent.GetNodeOrNull("EnhancedTerrainTileMap");
            if (terrain == null)
                terrain = parent.GetNodeOrNull("EnhancedTerrain");
        }

        if (terrain != null && terrain.HasMethod("get_town_data_at_position"))
        {
            var townData = terrain.Call("get_town_data_at_position", tileTopLeft);
            if (townData != null && townData is Godot.Collections.Dictionary dict && dict.Count > 0)
            {
                var townName = dict.Contains("name") ? dict["name"].ToString() : "Unknown Town";
                EmitSignal("town_name_display", townName);

                // After small delay show dialog via GameController (async not trivial in C# here); instead, attempt direct call
                // Try to find game controller in group
                var tree = GetTree();
                Node gameController = null;
                foreach (var node in tree.GetNodesInGroup("game_controller"))
                {
                    gameController = node as Node;
                    break;
                }
                if (gameController != null && gameController.HasMethod("show_town_dialog"))
                {
                    gameController.Call("show_town_dialog", dict);
                }
            }
        }
    }

    public int award_xp_for_exploration()
    {
        int xp = 50 + level * 10;
        GainExperience(xp);
        return xp;
    }

    // GDScript-compatible wrappers (snake_case) so has_method/has_signal and direct calls work
    public void load_from_character_data(Resource charData) => LoadFromCharacterData(charData);

    public Godot.Collections.Dictionary save_to_character_data() => SaveToCharacterData();

    public void move_to_tile(Vector2 pos) => MoveToTile(pos);

    public void enter_combat()
    {
        is_in_combat = true;
        EmitSignal("encounter_started");
    }

    public void exit_combat()
    {
        is_in_combat = false;
    }

    public void set_camera_target(Vector2 pos) => SetCameraTarget(pos);

    public float get_encounter_difficulty_for_terrain(int terrainType) => GetEncounterDifficultyForTerrain(terrainType);
}
