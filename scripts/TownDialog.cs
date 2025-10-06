using Godot;
using System;

public partial class TownDialog : Control
{
    public TownDialog()
    {
        // Ensure expected GDScript-style signals exist as early as possible
        try {
            AddUserSignal("town_entered", new Godot.Collections.Array());
            AddUserSignal("dialog_cancelled", new Godot.Collections.Array());
            // Can't use DebugLogger here (tree not ready) — but this indicates constructor ran
        } catch {
            // best-effort - if engine isn't ready yet this will be a no-op
        }
    }
    [Signal] public delegate void TownEnteredEventHandler(Godot.Collections.Dictionary town_data);
    [Signal] public delegate void DialogCancelledEventHandler();

    private Label _townLabel;
    private Label _messageLabel;
    private Godot.Collections.Dictionary _currentTownData = new Godot.Collections.Dictionary();

    public override void _Ready()
    {
        Visible = false;
        ZIndex = 1000;
        ProcessMode = Node.ProcessModeEnum.WhenPaused;
        FocusMode = FocusModeEnum.All;

        _townLabel = GetNodeOrNull<Label>("DialogPanel/VBoxContainer/TownLabel");
        _messageLabel = GetNodeOrNull<Label>("DialogPanel/VBoxContainer/MessageLabel");

        var logger = GetTree()?.Root?.GetNodeOrNull<DebugLogger>("DebugLogger");
    logger?.Info($"DEBUG TownDialog: _ready called, z_index set to: {ZIndex}");
    logger?.Info("DEBUG TownDialog: process_mode set to PROCESS_MODE_WHEN_PAUSED");

        // Ensure the SignalProxy properties are available to GDScript via get("town_entered")
        if (_townEnteredProxy == null) _townEnteredProxy = new SignalProxy(this, "town_entered");
        if (_dialogCancelledProxy == null) _dialogCancelledProxy = new SignalProxy(this, "dialog_cancelled");
        try {
            Set("town_entered", _townEnteredProxy);
            Set("dialog_cancelled", _dialogCancelledProxy);
            logger?.Info("DEBUG TownDialog: Exposed signal proxies as properties") ;
        } catch (Exception ex) {
            logger?.Warn("DEBUG TownDialog: Failed to expose proxies: " + ex.Message);
        }

        // If our parent is GameController (or any node implementing the handlers), connect directly
        var parent = GetParent();
        if (parent != null)
        {
            try {
                if (parent.HasMethod("_on_town_entered")){
                    var r = Connect("town_entered", parent, "_on_town_entered");
                    logger?.Info($"DEBUG TownDialog: Connected town_entered to parent, result={r}");
                }
            } catch (Exception ex){ logger?.Warn("DEBUG TownDialog: connect town_entered failed: " + ex.Message); }
            try {
                if (parent.HasMethod("_on_town_dialog_cancelled")){
                    var r2 = Connect("dialog_cancelled", parent, "_on_town_dialog_cancelled");
                    logger?.Info($"DEBUG TownDialog: Connected dialog_cancelled to parent, result={r2}");
                }
            } catch (Exception ex){ logger?.Warn("DEBUG TownDialog: connect dialog_cancelled failed: " + ex.Message); }
        }
    }

    // Keep the same snake_case API used from GDScript
    public void show_town_dialog(Godot.Collections.Dictionary town_data)
    {
        var logger = GetTree()?.Root?.GetNodeOrNull<DebugLogger>("DebugLogger");
        logger?.Info($"DEBUG TownDialog: show_town_dialog called with: {town_data}");

        _currentTownData = town_data ?? new Godot.Collections.Dictionary();
    var viewport = GetViewport();
    var viewportSize = viewport != null ? viewport.GetVisibleRect().Size : new Vector2(1024,768);

        var camera = GetViewport().GetCamera2D();
        Vector2 cameraPosition = Vector2.Zero;
        if (camera != null)
            cameraPosition = camera.GetScreenCenterPosition();

        Position = cameraPosition - viewportSize / 2.0f;
        Size = viewportSize;

        if (_townLabel != null)
            _townLabel.Text = town_data != null && town_data.ContainsKey("name") ? $"Welcome to {town_data["name"]}!" : "Welcome to this town!";

        if (_messageLabel != null)
            _messageLabel.Text = "Do you want to enter the town? (y/n)";

        Visible = true;
        GetTree().Paused = true;
        GrabFocus();
    }

    public void hide_dialog()
    {
        Visible = false;
        GetTree().Paused = false;
    }

    public override void _Input(InputEvent @event)
    {
        if (!Visible) return;
        if (@event.IsActionPressed("ui_cancel"))
        {
            hide_dialog();
            EmitSignal("dialog_cancelled");
            return;
        }
        if (@event is InputEventKey ek && ek.Pressed && !ek.Echo)
        {
            if (ek.Keycode == Key.Y)
            {
                hide_dialog();
                EmitSignal("town_entered", _currentTownData);
            }
            else if (ek.Keycode == Key.N)
            {
                hide_dialog();
                EmitSignal("dialog_cancelled");
            }
        }
    }

    public override void _EnterTree()
    {
        // Ensure the expected GDScript-style signal names exist for runtime connections
        AddUserSignal("town_entered", new Godot.Collections.Array());
        AddUserSignal("dialog_cancelled", new Godot.Collections.Array());
    }

    // Compatibility proxies so GDScript can access `town_dialog.town_entered.connect(...)`
    private SignalProxy _townEnteredProxy;
    private SignalProxy _dialogCancelledProxy;

    public SignalProxy town_entered {
        get {
            if (_townEnteredProxy == null) _townEnteredProxy = new SignalProxy(this, "town_entered");
            return _townEnteredProxy;
        }
    }

    public SignalProxy dialog_cancelled {
        get {
            if (_dialogCancelledProxy == null) _dialogCancelledProxy = new SignalProxy(this, "dialog_cancelled");
            return _dialogCancelledProxy;
        }
    }

    // Small helper type exposed to GDScript to mimic the GDScript `object.signal` API
    public class SignalProxy : Reference
    {
        private Node _owner;
        private string _signalName;
        public SignalProxy(Node owner, string signalName) { _owner = owner; _signalName = signalName; }

        // Connects using a Callable (function reference or bound method)
        public void connect(object callable)
        {
            if (callable is Callable c)
            {
                _owner.Connect(_signalName, c);
                return;
            }
            // If a GDScript passed a function, it should come through as a Callable; try best-effort
            try { _owner.Connect(_signalName, new Callable(callable)); } catch { }
        }

        // Overload for target + method name
        public void connect(Node target, string method)
        {
            if (target != null && !string.IsNullOrEmpty(method))
            {
                _owner.Connect(_signalName, target, method);
            }
        }
    }
}
