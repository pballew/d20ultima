using Godot;
using System;

public partial class Main : Node2D
{
    private const int TILE_SIZE = 32;

    public Player player;
    public Node combat_manager;
    public Camera2D camera;
    public Node terrain;
    public Node player_stats_ui;
    public Node coordinate_overlay;

    public override void _Ready()
    {
        AddToGroup("main");

        player = GetNodeOrNull<Player>("Player");
        combat_manager = GetNodeOrNull<Node>("CombatManager");
        player_stats_ui = GetNodeOrNull<Node>("UI/PlayerStatsUI");
        coordinate_overlay = GetNodeOrNull<Node>("UI/CoordinateOverlay");
        terrain = GetNodeOrNull<Node>("EnhancedTerrainTileMap");
        if (terrain == null)
            terrain = GetNodeOrNull<Node>("EnhancedTerrain");
        camera = GetNodeOrNull<Camera2D>("Camera2D");

        // Connect signals defensively (works whether player is GDScript or C#)
        if (player != null)
        {
            // Use Godot.Callable where appropriate; connect only if not already connected
            var selfCallable = new Callable(this, nameof(OnEncounterStarted));
            if (!player.IsConnected("encounter_started", selfCallable))
                player.Connect("encounter_started", selfCallable);

            selfCallable = new Callable(this, nameof(OnCampingStarted));
            if (!player.IsConnected("camping_started", selfCallable))
                player.Connect("camping_started", selfCallable);

            selfCallable = new Callable(this, nameof(OnPlayerMoved));
            if (!player.IsConnected("movement_finished", selfCallable))
                player.Connect("movement_finished", selfCallable);

            selfCallable = new Callable(this, nameof(OnTownNameDisplay));
            if (!player.IsConnected("town_name_display", selfCallable))
                player.Connect("town_name_display", selfCallable);
        }

        if (combat_manager != null)
        {
            // wire combat finished if available using Callable
            if (combat_manager.HasSignal("combat_finished"))
            {
                var cmCallableTop = new Callable(this, nameof(OnCombatFinished));
                if (!combat_manager.IsConnected("combat_finished", cmCallableTop))
                    combat_manager.Connect("combat_finished", cmCallableTop);
            }
        }

    // Wait one frame to allow terrain to initialize; schedule deferred init on this node
    CallDeferred(nameof(Deferred_Init));
    }

    private void Deferred_Init()
    {
        EnsurePlayerSafeStartingPosition();
        if (player != null && camera != null)
        {
            // Move the player to the center of the screen (world coordinates).
            Vector2 centerWorld;
            try
            {
                centerWorld = camera.GetScreenCenterPosition();
            }
            catch
            {
                var vp = GetViewport();
                centerWorld = vp != null ? vp.GetVisibleRect().Size / 2f : new Vector2(0, 0);
            }

            player.GlobalPosition = centerWorld;

            // If player supports set_camera_target, inform it of the new position
            if (player.HasMethod("set_camera_target"))
                player.Call("set_camera_target", player.GlobalPosition);
        }

        GD.Print("Game scene ready!");

        SpawnSomeOverworldMonsters();

        SetProcessInput(true);
    }

    private void EnsurePlayerSafeStartingPosition()
    {
        if (player == null || terrain == null) return;

        Vector2 current = player.GlobalPosition;
        if (TerrainIsWalkable(current))
        {
            GD.Print($"Player position is walkable; keeping saved position: {current}");
            return;
        }

        Vector2 near = FindNearestSafePosition(current);
        if (near != Vector2.Zero)
        {
            player.GlobalPosition = near;
            GD.Print($"Player adjusted to nearest safe position: {player.GlobalPosition}");
            return;
        }

        GD.Print("Searching broader area for safe starting position...");

        // Try fallback positions
        var fallback = new Vector2[] {
            new Vector2(5*TILE_SIZE,5*TILE_SIZE), new Vector2(-5*TILE_SIZE,5*TILE_SIZE),
            new Vector2(5*TILE_SIZE,-5*TILE_SIZE), new Vector2(-5*TILE_SIZE,-5*TILE_SIZE),
            new Vector2(10*TILE_SIZE,0), new Vector2(-10*TILE_SIZE,0), new Vector2(0,10*TILE_SIZE), new Vector2(0,-10*TILE_SIZE)
        };
        foreach (var pos in fallback)
        {
            if (TerrainIsWalkable(pos))
            {
                player.GlobalPosition = pos;
                GD.Print($"Player moved to fallback safe position: {player.GlobalPosition}");
                return;
            }
        }

        GD.Print("Warning: Could not find safe starting position for player!");
    }

    private bool TerrainIsWalkable(Vector2 worldPos)
    {
        if (terrain == null) return true;
        if (terrain.HasMethod("is_walkable"))
        {
            object res = terrain.Call("is_walkable", worldPos);
            if (res is bool b) return b;
        }
        return true; // conservative fallback
    }

    private Vector2 FindNearestSafePosition(Vector2 pos)
    {
        if (terrain == null) return pos;

        if (terrain.HasMethod("is_walkable") && TerrainIsWalkable(pos)) return pos;

        for (int radius = 1; radius < 10; radius++)
        {
            for (int x = -radius; x <= radius; x++)
            {
                for (int y = -radius; y <= radius; y++)
                {
                    if (x*x + y*y <= radius*radius)
                    {
                        Vector2 check = pos + new Vector2(x * TILE_SIZE, y * TILE_SIZE);
                        if (TerrainIsWalkable(check)) return check;
                    }
                }
            }
        }
        return Vector2.Zero;
    }

    private void OnEncounterStarted()
    {
        GD.Print("A wild creature appears!");
        if (player == null) return;

        int terrainType = GetCurrentTerrainType();
        string difficulty = "wilderness";
        if (player.HasMethod("get_encounter_difficulty_for_terrain"))
            difficulty = player.Call("get_encounter_difficulty_for_terrain", terrainType).ToString();

        var enemy = CreateRandomEnemy(difficulty);

        // Enter combat mode on player
        if (player.HasMethod("enter_combat")) player.Call("enter_combat");
        else if (player.HasMethod("EnterCombat")) player.Call("EnterCombat");

        // Instantiate CombatScreen UI
        var scene = GD.Load<PackedScene>("res://scenes/CombatScreen.tscn");
        if (scene != null)
        {
            var inst = scene.Instantiate();
            AddChild(inst);
        }

        // Start combat via combat_manager if available
        if (combat_manager != null)
        {
            if (combat_manager.HasMethod("StartCombat"))
                combat_manager.Call("StartCombat", player, new Godot.Collections.Array(){enemy});
            else if (combat_manager.HasMethod("start_combat"))
                combat_manager.Call("start_combat", player, new Godot.Collections.Array(){enemy});
            else if (combat_manager.HasMethod("startCombat"))
                combat_manager.Call("startCombat", player, new Godot.Collections.Array(){enemy});
        }

        // Connect to combat finish (best-effort)
        if (combat_manager != null && combat_manager.HasSignal("combat_finished"))
        {
                var cmCallable = new Callable(this, nameof(OnCombatFinished));
                if (!combat_manager.IsConnected("combat_finished", cmCallable))
                    combat_manager.Connect("combat_finished", cmCallable);
        }
    }

    private int GetCurrentTerrainType()
    {
        Node t = GetNodeOrNull<Node>("EnhancedTerrainTileMap");
        if (t == null) t = GetNodeOrNull<Node>("EnhancedTerrain");
        if (t != null && player != null && player.HasMethod("get_terrain_type_at_position"))
        {
                object resObj = player.Call("get_terrain_type_at_position", player.GlobalPosition, t);
                if (resObj is int ii) return ii;
                if (resObj is long ll) return (int)ll;
                if (int.TryParse(resObj?.ToString() ?? "0", out var parsed)) return parsed;
        }
        return 0;
    }

    private Monster CreateRandomEnemy(string difficultyModifier)
    {
        // Create a minimal monster instance and add to scene
        Monster monster = null;
        try {
            // Only try to load the scene if it exists on disk
            if (FileAccess.FileExists("res://scenes/Monster.tscn"))
            {
                var loaded = GD.Load<PackedScene>("res://scenes/Monster.tscn");
                monster = (Monster)loaded?.Instantiate();
            }
        } catch { }
        if (monster == null)
        {
            // fallback: instantiate script
            monster = new Monster();
        }

        monster.Name = "Goblin";
        monster.GlobalPosition = player.GlobalPosition + new Vector2(200, 0);
        AddChild(monster);

        GD.Print($"Spawned overworld monster: {monster.Name} at {monster.GlobalPosition}");
        return monster;
    }

    private void SpawnSomeOverworldMonsters()
    {
        if (player == null) return;
        var offsets = new Vector2[] { new Vector2(3,0), new Vector2(-4,1), new Vector2(2,2), new Vector2(-3,-2) };
        foreach (var off in offsets)
        {
            var pos = player.GlobalPosition + off * TILE_SIZE;
            var enemy = CreateRandomEnemy("wilderness");
            enemy.GlobalPosition = pos;
            // Ensure sprite z_index if sprite child exists
            foreach (var child in enemy.GetChildren())
            {
                if (child is Sprite2D s) s.ZIndex = 50;
            }
            GD.Print($"Spawned overworld monster: {enemy.Name} at {enemy.GlobalPosition}");
        }
    }

    private void OnCombatFinished()
    {
        GD.Print("Combat finished (Main.cs)");
    }

    // Placeholder handlers
    private void OnCampingStarted() { }
    private void OnPlayerMoved() { }
    private void OnTownNameDisplay(object townName) { }
}
