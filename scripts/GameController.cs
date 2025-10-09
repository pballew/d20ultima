using Godot;
using System;

public partial class GameController : Control
{
    private Control main_menu;
    private Control game_scene;
    private Node town_dialog;
    private PackedScene _characterCreationScene;
    private Control _characterCreationInstance;
    private Resource currentCharacter;
    private AcceptDialog quitConfirmationDialog;
    private bool q_saves_to_menu = true;

    public override void _Ready()
    {
        // Keep a group name so other nodes (like Player) can find the controller as before
        try { AddToGroup("game_controller"); } catch { }
        // Ensure this controller processes input with high priority like the GDScript version
        try { ProcessMode = Node.ProcessModeEnum.Always; } catch { }

        // Ensure this controller fills the viewport like the GDScript version did
        try {
            this.AnchorLeft = 0f;
            this.AnchorTop = 0f;
            this.AnchorRight = 1f;
            this.AnchorBottom = 1f;
            this.OffsetLeft = 0f;
            this.OffsetTop = 0f;
            this.OffsetRight = 0f;
            this.OffsetBottom = 0f;
        } catch { }

        // Cache common nodes (assumes they are direct children)
        main_menu = GetNodeOrNull<Control>("MainMenu");
    game_scene = GetNodeOrNull<Control>("GameScene");
        town_dialog = GetNodeOrNull<Node>("TownDialog");

        if (main_menu != null)
        {
            // Make sure the main menu fills its parent controller
            try {
                main_menu.AnchorLeft = 0f;
                main_menu.AnchorTop = 0f;
                main_menu.AnchorRight = 1f;
                main_menu.AnchorBottom = 1f;
                main_menu.OffsetLeft = 0f;
                main_menu.OffsetTop = 0f;
                main_menu.OffsetRight = 0f;
                main_menu.OffsetBottom = 0f;
            } catch { }

            main_menu.Visible = true;
            // Force MainMenu to be on top and properly sized (matches GDScript behavior)
            try { main_menu.ZIndex = 100; } catch { }
            try { main_menu.CallDeferred("move_to_front"); } catch { }
            // Log anchor/offset/position for debugging layout issues
            GD.Print($"MainMenu anchors: L={main_menu.AnchorLeft} T={main_menu.AnchorTop} R={main_menu.AnchorRight} B={main_menu.AnchorBottom}");
            GD.Print($"MainMenu offsets: L={main_menu.OffsetLeft} T={main_menu.OffsetTop} R={main_menu.OffsetRight} B={main_menu.OffsetBottom}");
            // If needed, additional geometry can be computed via the viewport or Control APIs
            // Keep game_scene hidden until start
            if (game_scene != null) game_scene.Visible = false;
        }

        // Prepare CharacterCreation packed scene but do not instance it yet
        try
        {
            _characterCreationScene = GD.Load<PackedScene>("res://scenes/CharacterCreation.tscn");
        }
        catch { _characterCreationScene = null; }

        // Connect MainMenu's NewCharacterButton (if present) to show the character creation UI
        try
        {
            var newBtn = main_menu?.GetNodeOrNull<Button>("VBoxContainer/NewCharacterButton");
            if (newBtn != null)
            {
                newBtn.Pressed += () => { ShowCharacterCreation(); };
            }
        }
        catch { }

        // Ensure the game camera is NOT current while the main menu is showing.
        // Calling MakeCurrent here can cause the viewport to jump if the camera
        // is positioned for gameplay. Use Current = false to be explicit.
    var playerCamera = GetNodeOrNull<Camera2D>("GameScene/Camera2D");
    if (playerCamera != null)
    {
        // Intentionally do nothing here: avoid forcing the camera to become
        // current while the main menu is visible. Calling MakeCurrent() here
        // would make the game camera active immediately and may jump the view.
        // No-op is safer; the camera will be activated when the game actually
        // starts in _OnStartGame.
    }

        // Hide player stats UI while in menu
        var playerStatsUI = GetNodeOrNull<Control>("GameScene/UI/PlayerStatsUI");
    if (playerStatsUI != null) playerStatsUI.Visible = false;

        // Show menu by default
        if (main_menu != null)
        {
            main_menu.Visible = true;
            // If there's a start_game signal on the menu, try to connect to it
            try {
                if (main_menu.HasSignal("start_game"))
                    main_menu.Connect("start_game", new Callable(this, nameof(_on_start_game)));
            } catch { }
        }
        if (game_scene != null) game_scene.Visible = false;

        // Defer connecting to town dialog signals like the GDScript version did
        CallDeferred(nameof(ConnectTownDialogSignals));

        // Create quit confirmation dialog
        CreateQuitConfirmationDialog();

        // Check for auto-load of last character
        CheckAutoLoad();

    }
    // Auto-load intentionally skipped to avoid runtime type/Variant handling complexity during conversion.

    public void _OnStartGame(Resource character_data)
    {
        GD.Print("=== _ON_START_GAME CALLED ===");
        // Track current character (as GDScript did)
        currentCharacter = character_data;
        // Hide the main menu and start the game scene
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

    public void ShowCharacterCreation()
    {
        if (_characterCreationInstance != null)
            return; // already shown

        if (_characterCreationScene == null)
        {
            GD.PrintErr("CharacterCreation scene not found");
            return;
        }

        var inst = _characterCreationScene.Instantiate();
        if (inst is Control ctrl)
        {
            AddChild(ctrl);
            _characterCreationInstance = ctrl;
            // Ensure it fills the parent
            try {
                ctrl.AnchorLeft = 0f; ctrl.AnchorTop = 0f; ctrl.AnchorRight = 1f; ctrl.AnchorBottom = 1f;
                ctrl.OffsetLeft = 0f; ctrl.OffsetTop = 0f; ctrl.OffsetRight = 0f; ctrl.OffsetBottom = 0f;
            } catch { }
            // hide main menu while creating
            if (main_menu != null) main_menu.Visible = false;
        }
    }

    public void HideCharacterCreation()
    {
        if (_characterCreationInstance != null)
        {
            _characterCreationInstance.QueueFree();
            _characterCreationInstance = null;
            if (main_menu != null) main_menu.Visible = true;
        }
    }

    // GDScript-compatible snake_case wrapper so calls from GDScript still work
    public void _on_start_game(Resource character_data) => _OnStartGame(character_data);

    private void CheckAutoLoad()
    {
        GD.Print("=== GameController Debug ===");
        GD.Print("Checking for save data...");
        try
        {
            if (SaveSystem.HasSaveData())
            {
                GD.Print("Save data found, attempting to load last character...");
                var last = SaveSystem.LoadLastCharacter();
                if (last != null)
                {
                    GD.Print("Auto-loading last character");
                    _OnStartGame(last);
                    return;
                }
                else
                {
                    GD.PrintErr("Failed to load character data!");
                }
            }
            else
            {
                GD.Print("No save data found");
            }
        }
        catch (Exception ex)
        {
            GD.PrintErr("CheckAutoLoad exception: " + ex.Message);
        }

        // No save -> show main menu
        if (main_menu != null) main_menu.Show();
        if (game_scene != null) game_scene.Hide();
    }

    private void CreateQuitConfirmationDialog()
    {
        try
        {
            quitConfirmationDialog = new AcceptDialog();
            quitConfirmationDialog.DialogText = "Save and return to main menu?";
            quitConfirmationDialog.Title = "Quit to Menu";
            quitConfirmationDialog.AddCancelButton("Cancel");
            AddChild(quitConfirmationDialog);
            quitConfirmationDialog.Connect("confirmed", new Callable(this, nameof(OnQuitConfirmed)));
        }
        catch { }
    }

    private void OnQuitConfirmed()
    {
        SaveAndReturnToMenu();
    }

    public void SaveAndReturnToMenuPublic()
    {
        SaveAndReturnToMenu();
    }

    public void SaveAndReturnToMenu()
    {
        var player = GetNodeOrNull<Player>("GameScene/Player");
        if (player != null)
        {
            var dictObj = player.save_to_character_data();
            var dict = dictObj as Godot.Collections.Dictionary;
            if (dict != null)
            {
                // Convert to CharacterData Resource (minimal fields)
                var cd = new CharacterData();
                if (dict.ContainsKey("character_name")) cd.Set("character_name", dict["character_name"]);
                if (dict.ContainsKey("position")) cd.Set("world_position", dict["position"]);
                try { SaveSystem.SaveGameState(cd); } catch { }
            }
        }

        if (game_scene != null) game_scene.Hide();
        if (main_menu != null)
        {
            main_menu.Show();
            // If the menu exposes a show_main_menu method, call it
            if (main_menu.HasMethod("show_main_menu"))
                main_menu.Call("show_main_menu");
        }
    }

    // GDScript wrapper names
    public void _save_and_return_to_menu() => SaveAndReturnToMenu();

    public void save_game()
    {
        var player = GetNodeOrNull<Player>("GameScene/Player");
        if (player != null)
        {
            var dictObj = player.save_to_character_data();
            var dict = dictObj as Godot.Collections.Dictionary;
            if (dict != null)
            {
                var cd = new CharacterData();
                if (dict.ContainsKey("character_name")) cd.Set("character_name", dict["character_name"]);
                if (dict.ContainsKey("position")) cd.Set("world_position", dict["position"]);
                try {
                    var ok = SaveSystem.SaveGameState(cd);
                    if (ok) GD.Print("Game saved successfully!"); else GD.PrintErr("Failed to save game!");
                } catch { }
            }
        }
    }

    private void ConnectTownDialogSignals()
    {
        try
        {
            var td = GetNodeOrNull<Node>("TownDialog");
            if (td != null)
            {
                // connect signals if present
                if (td.HasSignal("town_entered"))
                    td.Connect("town_entered", new Callable(this, nameof(ShowTownDialog)));
                if (td.HasSignal("dialog_cancelled"))
                    td.Connect("dialog_cancelled", new Callable(this, nameof(OnTownDialogCancelled)));
            }
        }
        catch { }
    }

    private void OnTownDialogCancelled()
    {
        // No-op mirror of GDScript behavior
    }

    // Expose snake_case show_town_dialog for GDScript compatibility
    public void show_town_dialog(Godot.Collections.Dictionary town_data) => ShowTownDialog(town_data);

    public override void _Input(InputEvent @event)
    {
        if (@event.IsActionPressed("ui_cancel"))
        {
            if (game_scene != null && game_scene.Visible)
            {
                // Show quit dialog simple: call SaveAndReturnToMenu
                if (quitConfirmationDialog != null)
                    quitConfirmationDialog.PopupCentered();
                else
                    SaveAndReturnToMenu();
            }
            else if (main_menu != null && main_menu.Visible)
            {
                GetTree().Quit();
            }
            return;
        }

        // Handle Q key explicitly (mirrors GDScript behavior)
        if (@event is InputEventKey ek && ek.Pressed && !ek.Echo)
        {
            // Compare the Key enum directly
            if (ek.Keycode == Key.Q)
            {
                if (game_scene != null && game_scene.Visible)
                {
                    if (q_saves_to_menu)
                    {
                        SaveAndReturnToMenu();
                        // consume input by marking as handled
                        GetViewport().SetInputAsHandled();
                        return;
                    }
                    else
                    {
                        // Save and quit
                        var player = GetNodeOrNull<Player>("GameScene/Player");
                        if (player != null)
                        {
                            var dictObj = player.save_to_character_data();
                            var dict = dictObj as Godot.Collections.Dictionary;
                            if (dict != null)
                            {
                                var cd = new CharacterData();
                                if (dict.ContainsKey("character_name")) cd.Set("character_name", dict["character_name"]);
                                if (dict.ContainsKey("position")) cd.Set("world_position", dict["position"]);
                                try { SaveSystem.SaveGameState(cd); GD.Print("Q pressed: game saved, quitting application"); } catch { GD.Print("Q pressed: save attempt failed"); }
                            }
                            else
                            {
                                GD.Print("Q pressed: no character to save, quitting application");
                            }
                        }
                        GetTree().Quit();
                    }
                }
                else
                {
                    // On main menu: do nothing and consume
                    GetViewport().SetInputAsHandled();
                    return;
                }
            }
        }
    }

    public void ShowTownDialog(Godot.Collections.Dictionary town_data)
    {
        var td = GetNodeOrNull<Node>("TownDialog");
        if (td != null && td.HasMethod("show_town_dialog"))
            td.Call("show_town_dialog", town_data);
    }

    // geometry diagnostic removed now that layout is finalized
}
