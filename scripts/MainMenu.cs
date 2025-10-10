using Godot;
using System;

public partial class MainMenu : Control
{
    private Button _mapButton;
    private MapPanel _mapPanel;
    private Button _continueButton;
    private Button _newCharacterButton;
    private Button _loadButton;
    private Button _quitButton;

    public override void _Ready()
    {
        // Wire up the Map button (if present) to toggle the MapPanel instance
        _mapButton = GetNodeOrNull<Button>("VBoxContainer/MapButton");
        _mapPanel = GetNodeOrNull<MapPanel>("MapPanel");
        if (_mapButton != null && _mapPanel != null)
            _mapButton.Pressed += () => _mapPanel.ToggleMap();

        // Cache other menu buttons
        _continueButton = GetNodeOrNull<Button>("VBoxContainer/ContinueButton");
        _newCharacterButton = GetNodeOrNull<Button>("VBoxContainer/NewCharacterButton");
        _loadButton = GetNodeOrNull<Button>("VBoxContainer/LoadCharacterButton");
        _quitButton = GetNodeOrNull<Button>("VBoxContainer/QuitButton");

        // Wire controller-dependent button actions. Use a helper that finds the GameController
        // at invocation time (try parent first, then group) to avoid timing issues with _Ready order.
        if (_continueButton != null)
        {
            _continueButton.Pressed += () =>
            {
                InvokeOnController((controller) =>
                {
                    var last = SaveSystem.LoadLastCharacter();
                    if (last != null)
                        controller._OnStartGame(last);
                    else
                        controller.ShowCharacterCreation();
                }, "MainMenu: GameController not found when pressing Continue");
            };
        }

        if (_newCharacterButton != null)
        {
            _newCharacterButton.Pressed += () =>
            {
                InvokeOnController((controller) => controller.ShowCharacterCreation(),
                    "MainMenu: GameController not found when pressing NewCharacter");
            };
        }

        if (_loadButton != null)
        {
            _loadButton.Pressed += () =>
            {
                // Find controller now and present a FileDialog listing user://characters/*.tres
                var controller = FindController();
                if (controller == null)
                {
                    GD.PrintErr("MainMenu: GameController not found when pressing LoadCharacter");
                    return;
                }

                // Instantiate our custom in-game popup to list saved characters
                // Instantiate the popup via its class to ensure the C# script is attached
                try
                {
                    var popup = new LoadCharacterPopup();
                    AddChild(popup);
                    popup.Connect("character_selected", new Callable(this, nameof(OnPopupCharacterSelected)));
                    popup.PopupCentered();
                }
                catch (Exception ex)
                {
                    GD.PrintErr("MainMenu: failed to create LoadCharacterPopup: " + ex.Message);
                }
            };
        }

        if (_quitButton != null)
        {
            _quitButton.Pressed += () => { GetTree().Quit(); };
        }
    }

    private void OnPopupCharacterSelected(Resource character)
    {
        var controller = FindController();
        if (controller == null)
        {
            GD.PrintErr("MainMenu: GameController not found when popup selected character");
            return;
        }
        try
        {
            controller._OnStartGame(character);
        }
        catch (Exception ex)
        {
            GD.PrintErr("MainMenu: exception starting game from popup: " + ex.Message);
        }
    }

    // Try to find the GameController in likely places: parent chain (most common) or group fallback
    private GameController FindController()
    {
        try
        {
            Node current = this;
            while (current != null)
            {
                if (current is GameController gc) return gc;
                current = current.GetParent();
            }
        }
        catch { }

        try
        {
            var grp = GetTree().GetNodesInGroup("game_controller");
            if (grp != null && grp.Count > 0)
                return grp[0] as GameController;
        }
        catch { }

        return null;
    }

    private void InvokeOnController(Action<GameController> action, string errMsg)
    {
        var controller = FindController();
        if (controller != null)
        {
            try { action(controller); } catch (Exception ex) { GD.PrintErr($"MainMenu: controller action exception: {ex.Message}"); }
        }
        else
        {
            GD.PrintErr(errMsg);
        }
    }

    // GDScript compatibility: methods expected by GameController and other callers
    // Keep them minimal to avoid changing runtime behavior.
    public void move_to_front()
    {
        // Ensure the menu is on top visually; match previous z_index used in logs
        this.ZIndex = 200;
        this.Show();
    }

    public void show_main_menu()
    {
        // Minimal implementation: ensure visible and ready state. Detailed UI setup
        // is handled by the C# port when needed.
        this.Show();
    }
}
