using Godot;
using System;
using System.Collections.Generic;

public partial class Character : Node2D
{
    [Export] public string character_name = "Unnamed";
    [Export] public int strength = 10;
    [Export] public int dexterity = 10;
    [Export] public int constitution = 10;
    [Export] public int intelligence = 10;
    [Export] public int wisdom = 10;
    [Export] public int charisma = 10;

    [Export] public int max_health = 100;
    [Export] public int current_health = 100;
    [Export] public int armor_class = 10;
    [Export] public int level = 1;
    [Export] public int experience = 0;

    [Export] public int attack_bonus = 0;
    [Export] public string damage_dice = "1d6";

    public int initiative = 0;

    public Item weapon = null;
    public Item armor = null;
    public Godot.Collections.Array inventory = new Godot.Collections.Array();

    public override void _Ready()
    {
        UpdateDerivedStats();
    }

    public int GetModifier(int stat)
    {
        return (stat - 10) / 2;
    }

    public void UpdateDerivedStats()
    {
        armor_class = 10 + GetModifier(dexterity);
        if (armor != null)
            armor_class += armor.armor_bonus;

        max_health = 100 + (GetModifier(constitution) * level * 10);
        if (current_health > max_health)
            current_health = max_health;
    }

    public int RollD20()
    {
        var rng = new Random();
        return rng.Next(1, 21);
    }

    public int RollDice(string diceString)
    {
        if (string.IsNullOrEmpty(diceString))
            return 0;

        var plusParts = diceString.Split('+');
        int modifier = 0;
        if (plusParts.Length > 1)
            int.TryParse(plusParts[1], out modifier);

        var dicePart = plusParts[0];
        var diceComponents = dicePart.Split('d');
        if (diceComponents.Length != 2)
            return modifier;

        int numDice = 1;
        int dieSize = 6;
        int.TryParse(diceComponents[0], out numDice);
        int.TryParse(diceComponents[1], out dieSize);

        var rng = new Random();
        int total = 0;
        for (int i = 0; i < Math.Max(1, numDice); i++)
            total += rng.Next(1, dieSize + 1);

        return total + modifier;
    }

    public bool MakeAttackRoll(Character target)
    {
        int roll = RollD20();
        int total = roll + attack_bonus + GetModifier(strength);
        GD.Print($"Attack roll: {roll} + {attack_bonus} + {GetModifier(strength)} = {total}");
        return target != null && total >= target.armor_class;
    }

    public void DealDamage(Character target)
    {
        if (target == null)
            return;
        int dmg = RollDice(damage_dice) + GetModifier(strength);
        target.TakeDamage(dmg);
        GD.Print($"Dealt {dmg} damage to {target.character_name}");
    }

    public void TakeDamage(int amount, string damageType = "physical")
    {
        current_health -= amount;
        if (current_health < 0)
            current_health = 0;

        // Emit a signal the GDScript UI expects by using EmitSignal with the GDScript signal name
        EmitSignal("health_changed", current_health, max_health);

        if (current_health <= 0)
            Die();
    }

    public void Heal(int amount)
    {
        current_health += amount;
        if (current_health > max_health)
            current_health = max_health;
        EmitSignal("health_changed", current_health, max_health);
    }

    public void Die()
    {
        GD.Print($"{character_name} has died!");
        EmitSignal("died");
    }

    public bool MakeSavingThrow(string type, int dc)
    {
        int roll = RollD20();
        int modifier = 0;
        switch (type.ToLower())
        {
            case "strength": modifier = GetModifier(strength); break;
            case "dexterity": modifier = GetModifier(dexterity); break;
            case "constitution": modifier = GetModifier(constitution); break;
            case "intelligence": modifier = GetModifier(intelligence); break;
            case "wisdom": modifier = GetModifier(wisdom); break;
            case "charisma": modifier = GetModifier(charisma); break;
        }
        int total = roll + modifier;
        GD.Print($"Saving throw ({type}): {roll} + {modifier} = {total} vs DC {dc}");
        return total >= dc;
    }

    // Experience helpers (minimal)
    public int GetXpForNextLevel()
    {
        // keep simple: linear growth
        return (level + 1) * 1000;
    }

    public float GetXpProgress()
    {
        int curLevelXp = 0;
        int nextLevelXp = GetXpForNextLevel();
        int progress = experience - curLevelXp;
        int needed = nextLevelXp - curLevelXp;
        if (needed <= 0) return 1f;
        return (float)progress / (float)needed;
    }

    public bool GainExperience(int xpAmount)
    {
        int oldLevel = level;
        experience += xpAmount;
        EmitSignal("experience_changed", experience, level);
        // Simple level-up rule
        if (experience >= GetXpForNextLevel())
        {
            LevelUp();
        }
        return level > oldLevel;
    }

    public void LevelUp()
    {
        level += 1;
        int hpGain = Math.Max(1, 6 + GetModifier(constitution));
        max_health += hpGain;
        current_health += hpGain;
        UpdateDerivedStats();
        GD.Print($"Level up to {level}, +{hpGain} HP");
    }
}
