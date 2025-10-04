using Godot;
using System;
using System.Collections.Generic;

public partial class CombatManager : Node
{
    [Signal] public delegate void CombatFinishedEventHandler(bool player_won);
    [Signal] public delegate void TurnChangedEventHandler(Node current_character);
    [Signal] public delegate void CombatMessageEventHandler(string message);

    public List<Character> combat_participants = new List<Character>();
    public int current_turn_index = 0;
    public bool is_combat_active = false;

    public void StartCombat(Character player, Godot.Collections.Array enemies)
    {
        combat_participants.Clear();
        combat_participants.Add(player);
        foreach (var e in enemies)
            if (e is Character c)
                combat_participants.Add(c);

        EmitSignal("combat_message", "=== COMBAT BEGINS ===");
        is_combat_active = true;
        current_turn_index = -1;
        NextTurn();
    }

    public void NextTurn()
    {
        if (!is_combat_active)
            return;

        // Find next alive participant
        for (int i = 0; i < combat_participants.Count; i++)
        {
            current_turn_index = (current_turn_index + 1) % combat_participants.Count;
            var participant = combat_participants[current_turn_index];
            if (participant != null && participant.current_health > 0)
            {
                EmitSignal("turn_changed", participant);
                if (!(participant is Player))
                {
                    // simple AI: attack player
                    // ... omitted for brevity
                }
                break;
            }
        }
    }

    public void EndCombat(bool playerWon)
    {
        is_combat_active = false;
        combat_participants.Clear();
        EmitSignal("combat_finished", playerWon);
    }
}
