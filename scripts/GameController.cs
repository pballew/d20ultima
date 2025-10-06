using Godot;
using System;

public partial class GameController : Control
{
    private Control main_menu;
    private Control game_scene;
    private Node town_dialog;

    public override void _Ready()
    {
        // Cache common nodes (assumes they are direct children)
        main_menu = GetNodeOrNull<Control>("MainMenu");
    game_scene = GetNodeOrNull<Control>("GameScene");
        town_dialog = GetNodeOrNull<Node>("TownDialog");

        if (main_menu != null)
        {
            main_menu.Visible = true;
            // Keep game_scene hidden until start
            if (game_scene != null) game_scene.Visible = false;
        }

        // Disable camera while in menu if exists
    var playerCamera = GetNodeOrNull<Camera2D>("GameScene/Camera2D");
    if (playerCamera != null) playerCamera.MakeCurrent();

        // Hide player stats UI while in menu
        var playerStatsUI = GetNodeOrNull<Control>("GameScene/UI/PlayerStatsUI");
    if (playerStatsUI != null) playerStatsUI.Visible = false;

        // Skip auto-load to avoid variant conversion issues for now
        // Show menu by default
        if (main_menu != null) main_menu.Visible = true;
        if (game_scene != null) game_scene.Visible = false;
    }
    // Auto-load intentionally skipped to avoid runtime type/Variant handling complexity during conversion.

    public void _OnStartGame(Resource character_data)
    {
        GD.Print("=== _ON_START_GAME CALLED ===");
        // Save current_character not tracked here; just start the scene
        if (main_menu != null) main_menu.Hide();

        // Find player in scene
        var player = GetNodeOrNull<Node>("GameScene/Player");
        if (player != null && player.HasMethod("load_from_character_data"))
        {
            player.Call("load_from_character_data", character_data);
        }

        // Enable camera
        var playerCamera = GetNodeOrNull<Camera2D>("GameScene/Camera2D");
        if (playerCamera != null)
        {
            playerCamera.MakeCurrent();
            // center camera on player
            if (player != null && player is Node2D p2d)
            {
                playerCamera.GlobalPosition = p2d.GlobalPosition;
                if (player.HasMethod("set_camera_target"))
                    player.Call("set_camera_target", p2d.GlobalPosition);
            }
        }

        // Setup player stats UI
        var stats = GetNodeOrNull<Control>("GameScene/UI/PlayerStatsUI");
        if (stats != null && player != null && stats.HasMethod("setup_player_stats"))
        {
            stats.Call("setup_player_stats", player);
            if (stats is CanvasItem ci) ci.Visible = true;
        }

    if (game_scene != null && game_scene is Control gsc) gsc.Visible = true;
        GD.Print("Game started (C#): " + (character_data != null ? character_data.Get("character_name").ToString() : "Unknown"));
    }

    public void SaveAndReturnToMenu()
    {
        var player = GetNodeOrNull<Node>("GameScene/Player");
        Resource current_character = null;
        if (player != null && player.HasMethod("save_to_character_data"))
        {
            object res = player.Call("save_to_character_data");
            if (res is Resource r) current_character = r;
        }

        var saveSystem = GetNodeOrNull<Node>("/root/SaveSystem");
        if (saveSystem != null && current_character != null)
        {
            saveSystem.Call("save_game_state", current_character);
        }

        if (game_scene != null) game_scene.Hide();
        if (main_menu != null) { main_menu.Show(); }
    }

    public override void _Input(InputEvent @event)
    {
        if (@event.IsActionPressed("ui_cancel"))
        {
            if (game_scene != null && game_scene.Visible)
            {
                // Show quit dialog simple: call SaveAndReturnToMenu
                SaveAndReturnToMenu();
            }
            else if (main_menu != null && main_menu.Visible)
            {
                GetTree().Quit();
            }
        }
    }

    public void ShowTownDialog(Godot.Collections.Dictionary town_data)
    {
        var td = GetNodeOrNull<Node>("TownDialog");
        if (td != null && td.HasMethod("show_town_dialog"))
            td.Call("show_town_dialog", town_data);
    }
}
