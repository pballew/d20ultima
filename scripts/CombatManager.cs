using Godot;
using System;
using System.Collections.Generic;

public partial class CombatManager : Node
{
    [Signal] public delegate void combat_finished();
    [Signal] public delegate void combat_message(string message);
    [Signal] public delegate void turn_changed(Node current_character);

    private List<Character> combat_participants = new List<Character>();
    private int current_turn_index = -1;
    private bool is_combat_active = false;

    public void StartCombat(Character player, Godot.Collections.Array enemies)
    {
        combat_participants.Clear();
        if (player != null) combat_participants.Add(player);
        if (enemies != null)
        {
            foreach (var e in enemies)
                if (e is Character c)
                    combat_participants.Add(c);
        }

        is_combat_active = true;
        current_turn_index = -1;
        EmitSignal("combat_message", "Combat started");
        // Start turn processing; UI can call StartPlayerTurn when it's player's turn
        NextTurn();
    }

    public void NextTurn()
    {
        if (!is_combat_active || combat_participants.Count == 0)
            return;

        // Advance to next alive participant
        for (int i = 0; i < combat_participants.Count; i++)
        {
            current_turn_index = (current_turn_index + 1) % combat_participants.Count;
            var participant = combat_participants[current_turn_index];
            if (participant != null && participant.current_health > 0)
            {
                EmitSignal("turn_changed", participant);
                // If participant is player, emit turn_changed and wait for UI to call ExecutePlayerAction
                if (participant is Player p)
                {
                    EmitSignal("combat_message", $"It's {p.character_name}'s turn.");
                    // Let UI handle player turn by listening to turn_changed signal and calling ExecutePlayerAction
                    return;
                }
                else
                {
                    // Enemy turn: simple AI attack
                    Player playerTarget = null;
                    foreach (var cp in combat_participants)
                        if (cp is Player pl && pl.current_health > 0) { playerTarget = pl; break; }
                    if (playerTarget != null)
                    {
                        if (participant.MakeAttackRoll(playerTarget))
                        {
                            participant.DealDamage(playerTarget);
                            EmitSignal("combat_message", $"{participant.character_name} hits {playerTarget.character_name}!");
                        }
                        else
                        {
                            EmitSignal("combat_message", $"{participant.character_name} misses {playerTarget.character_name}.");
                        }
                    }
                }

                // Check for end of combat
                bool playerAlive = false;
                bool enemiesAlive = false;
                foreach (var cp in combat_participants)
                {
                    if (cp is Player) { if (cp.current_health > 0) playerAlive = true; }
                    else { if (cp.current_health > 0) enemiesAlive = true; }
                }
                if (!playerAlive || !enemiesAlive)
                {
                    EndCombat(playerAlive && !enemiesAlive);
                }

                return;
            }
        }
    }

    // Called by UI to execute a player action. action can be "attack", "defend", "item", etc.
    public void ExecutePlayerAction(string action, Node target = null)
    {
        if (!is_combat_active || combat_participants.Count == 0) return;

        var participant = combat_participants[current_turn_index];
        if (!(participant is Player p)) return;

        if (action == "attack")
        {
            // Choose first alive enemy if none provided
            Character chosen = null;
            if (target is Character c && c.current_health > 0) chosen = c;
            else
            {
                foreach (var cp in combat_participants)
                    if (!(cp is Player) && cp.current_health > 0) { chosen = cp; break; }
            }

            if (chosen != null)
            {
                if (p.MakeAttackRoll(chosen))
                {
                    p.DealDamage(chosen);
                    EmitSignal("combat_message", $"{p.character_name} hits {chosen.character_name}!");
                }
                else
                {
                    EmitSignal("combat_message", $"{p.character_name} misses {chosen.character_name}.");
                }
            }
        }

        // After player action, advance to next turn
        NextTurn();
    }

    public void EndCombat(bool playerWon)
    {
        is_combat_active = false;
        combat_participants.Clear();
        EmitSignal("combat_finished");
    }
}
