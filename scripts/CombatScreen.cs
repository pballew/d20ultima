using Godot;
using System;

public partial class CombatScreen : Control
{
    private Node combatManagerNode;
    private Label msgLabel;
    private Button btnAttack;
    private Button btnDefend;
    private Button btnRun;

    public override void _Ready()
    {
        // Find UI nodes
        msgLabel = GetNodeOrNull<Label>("VBoxContainer/MessageLabel");
        btnAttack = GetNodeOrNull<Button>("VBoxContainer/HBox/Attack");
        btnDefend = GetNodeOrNull<Button>("VBoxContainer/HBox/Defend");
        btnRun = GetNodeOrNull<Button>("VBoxContainer/HBox/Run");

        // Resolve CombatManager: prefer root/Main/CombatManager if present
        combatManagerNode = GetNodeOrNull<CombatManager>("/root/Main/CombatManager");
        if (combatManagerNode == null)
        {
            combatManagerNode = GetTree().Root.GetNodeOrNull("Main/CombatManager");
        }

        // If the combat manager is a GDScript node, we still can connect to signals via string names
        if (combatManagerNode != null)
        {
            // connect signals defensively
            if (!combatManagerNode.IsConnected("combat_message", this, nameof(OnCombatMessage)))
                combatManagerNode.Connect("combat_message", this, nameof(OnCombatMessage));
            if (!combatManagerNode.IsConnected("turn_changed", this, nameof(OnTurnChanged)))
                combatManagerNode.Connect("turn_changed", this, nameof(OnTurnChanged));
        }

        // Wire up buttons
        if (btnAttack != null)
            btnAttack.Connect("pressed", new Callable(this, nameof(OnAttackPressed)));
        if (btnDefend != null)
            btnDefend.Connect("pressed", new Callable(this, nameof(OnDefendPressed)));
        if (btnRun != null)
            btnRun.Connect("pressed", new Callable(this, nameof(OnRunPressed)));
    }

    public void OnCombatMessage(string message)
    {
        if (msgLabel != null)
            msgLabel.Text += message + "\n";
    }

    public void OnTurnChanged(Node currentCharacter)
    {
        if (btnAttack != null) btnAttack.Disabled = false;
        if (btnDefend != null) btnDefend.Disabled = false;
        if (btnRun != null) btnRun.Disabled = false;
    }

    private void CallExecutePlayerAction(string action)
    {
        if (combatManagerNode == null)
        {
            combatManagerNode = GetNodeOrNull<CombatManager>("/root/Main/CombatManager");
            if (combatManagerNode == null)
                combatManagerNode = GetTree().Root.GetNodeOrNull("Main/CombatManager");
        }

        if (combatManagerNode == null)
            return;

        // Prefer strongly-typed C# method if available
        if (combatManagerNode is CombatManager cm)
        {
            cm.ExecutePlayerAction(action);
            return;
        }

        // Otherwise call dynamic/GDScript method names
        if (combatManagerNode.HasMethod("ExecutePlayerAction"))
        {
            combatManagerNode.Call("ExecutePlayerAction", action);
        }
        else if (combatManagerNode.HasMethod("execute_player_action"))
        {
            combatManagerNode.Call("execute_player_action", action);
        }
    }

    public void OnAttackPressed()
    {
        CallExecutePlayerAction("attack");
    }

    public void OnDefendPressed()
    {
        CallExecutePlayerAction("defend");
    }

    public void OnRunPressed()
    {
        CallExecutePlayerAction("run");
    }
}
