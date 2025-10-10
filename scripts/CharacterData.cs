using Godot;
using System;
using System.Collections.Generic;

public partial class CharacterData : Resource
{
    public enum CharacterClass
    {
        FIGHTER, ROGUE, WIZARD, CLERIC, RANGER, BARBARIAN
    }

    public enum CharacterRace
    {
        HUMAN, ELF, DWARF, HALFLING, GNOME, HALF_ELF, HALF_ORC, DRAGONBORN, TIEFLING
    }

    [Export] public string character_name = "";
    [Export] public CharacterClass character_class = CharacterClass.FIGHTER;
    [Export] public CharacterRace character_race = CharacterRace.HUMAN;
    [Export] public int level = 1;

    // Core stats
    [Export] public int strength = 10;
    [Export] public int dexterity = 10;
    [Export] public int constitution = 10;
    [Export] public int intelligence = 10;
    [Export] public int wisdom = 10;
    [Export] public int charisma = 10;

    // Derived stats
    [Export] public int max_health = 10;
    [Export] public int current_health = 10;
    [Export] public int experience = 0;
    [Export] public int gold = 100;

    // Class features
    [Export] public int attack_bonus = 0;
    [Export] public string damage_dice = "1d4";
    [Export] public int armor_class = 10;
    [Export] public int skill_points = 0;

    // Game progress
    [Export] public Vector2 world_position = Vector2.Zero;
    [Export] public string save_timestamp = "";
    [Export] public Godot.Collections.Array explored_tiles = new Godot.Collections.Array();
    [Export] public int last_reveal_radius = 0;

    public CharacterData()
    {
        // Fallback timestamp
        save_timestamp = DateTime.UtcNow.ToString("s");
    }

    public string get_class_name()
    {
        switch (character_class)
        {
            case CharacterClass.FIGHTER: return "Fighter";
            case CharacterClass.ROGUE: return "Rogue";
            case CharacterClass.WIZARD: return "Wizard";
            case CharacterClass.CLERIC: return "Cleric";
            case CharacterClass.RANGER: return "Ranger";
            case CharacterClass.BARBARIAN: return "Barbarian";
            default: return "Unknown";
        }
    }

    public string get_race_name()
    {
        switch (character_race)
        {
            case CharacterRace.HUMAN: return "Human";
            case CharacterRace.ELF: return "Elf";
            case CharacterRace.DWARF: return "Dwarf";
            case CharacterRace.HALFLING: return "Halfling";
            case CharacterRace.GNOME: return "Gnome";
            case CharacterRace.HALF_ELF: return "Half-Elf";
            case CharacterRace.HALF_ORC: return "Half-Orc";
            case CharacterRace.DRAGONBORN: return "Dragonborn";
            case CharacterRace.TIEFLING: return "Tiefling";
            default: return "Unknown";
        }
    }

    public string get_race_description()
    {
        switch (character_race)
        {
            case CharacterRace.HUMAN:
                return "Versatile and ambitious, humans are the most adaptable race. +1 to all stats.";
            case CharacterRace.ELF:
                return "Graceful and long-lived, with keen senses. +2 Dex, +1 Int. Darkvision.";
            case CharacterRace.DWARF:
                return "Hardy mountain folk with strong constitutions. +2 Con, +1 Wis. Poison resistance.";
            case CharacterRace.HALFLING:
                return "Small but brave, with natural luck. +2 Dex, +1 Cha. Lucky trait.";
            case CharacterRace.GNOME:
                return "Small, clever, and magically inclined. +2 Int, +1 Con. Gnome cunning.";
            case CharacterRace.HALF_ELF:
                return "Mix of human and elf heritage. +2 Cha, +1 to two different stats.";
            case CharacterRace.HALF_ORC:
                return "Strong and fierce, with orcish blood. +2 Str, +1 Con. Relentless endurance.";
            case CharacterRace.DRAGONBORN:
                return "Draconic humanoids with breath weapons. +2 Str, +1 Cha. Breath weapon.";
            case CharacterRace.TIEFLING:
                return "Touched by infernal heritage. +2 Cha, +1 Int. Fire resistance.";
            default:
                return "A mysterious heritage.";
        }
    }

    public string get_class_description()
    {
        switch (character_class)
        {
            case CharacterClass.FIGHTER:
                return "Masters of martial combat, skilled with many weapons and armor.";
            case CharacterClass.ROGUE:
                return "Sneaky and skilled, experts at dealing precise damage from shadows.";
            case CharacterClass.WIZARD:
                return "Scholarly magic-users capable of manipulating reality with spells.";
            case CharacterClass.CLERIC:
                return "Divine spellcasters who channel the power of their deity.";
            case CharacterClass.RANGER:
                return "Skilled hunters and trackers who protect the wilderness.";
            case CharacterClass.BARBARIAN:
                return "Fierce warriors who tap into primal fury in battle.";
            default:
                return "A mysterious adventurer.";
        }
    }

    public void apply_class_bonuses()
    {
        apply_racial_bonuses();

        switch (character_class)
        {
            case CharacterClass.FIGHTER:
                strength += 2; constitution += 1; attack_bonus = 1; damage_dice = "1d8"; armor_class = 12; break;
            case CharacterClass.ROGUE:
                dexterity += 2; intelligence += 1; attack_bonus = 0; damage_dice = "1d6"; armor_class = 11; break;
            case CharacterClass.WIZARD:
                intelligence += 2; wisdom += 1; attack_bonus = 0; damage_dice = "1d4"; armor_class = 10; break;
            case CharacterClass.CLERIC:
                wisdom += 2; strength += 1; attack_bonus = 0; damage_dice = "1d6"; armor_class = 11; break;
            case CharacterClass.RANGER:
                dexterity += 1; wisdom += 1; constitution += 1; attack_bonus = 1; damage_dice = "1d8"; armor_class = 11; break;
            case CharacterClass.BARBARIAN:
                strength += 2; constitution += 2; attack_bonus = 1; damage_dice = "1d12"; armor_class = 10; break;
            default: break;
        }
    }

    public void apply_racial_bonuses()
    {
        switch (character_race)
        {
            case CharacterRace.HUMAN: strength += 1; dexterity += 1; constitution += 1; intelligence += 1; wisdom += 1; charisma += 1; break;
            case CharacterRace.ELF: dexterity += 2; intelligence += 1; break;
            case CharacterRace.DWARF: constitution += 2; wisdom += 1; break;
            case CharacterRace.HALFLING: dexterity += 2; charisma += 1; break;
            case CharacterRace.GNOME: intelligence += 2; constitution += 1; break;
            case CharacterRace.HALF_ELF: charisma += 2; dexterity += 1; wisdom += 1; break;
            case CharacterRace.HALF_ORC: strength += 2; constitution += 1; break;
            case CharacterRace.DRAGONBORN: strength += 2; charisma += 1; break;
            case CharacterRace.TIEFLING: charisma += 2; intelligence += 1; break;
            default: break;
        }
    }

    public void calculate_derived_stats()
    {
        int con_modifier = (constitution - 10) / 2;
        int base_hp = get_class_base_hp();
        max_health = base_hp + con_modifier + ((level - 1) * (get_class_hp_per_level() + con_modifier));
        current_health = max_health;
    }

    public int get_class_base_hp()
    {
        switch (character_class)
        {
            case CharacterClass.FIGHTER:
            case CharacterClass.BARBARIAN:
                return 10;
            case CharacterClass.CLERIC:
            case CharacterClass.RANGER:
                return 8;
            case CharacterClass.ROGUE:
                return 6;
            case CharacterClass.WIZARD:
                return 4;
            default:
                return 6;
        }
    }

    public int get_class_hp_per_level()
    {
        switch (character_class)
        {
            case CharacterClass.FIGHTER:
            case CharacterClass.BARBARIAN:
                return 6;
            case CharacterClass.CLERIC:
            case CharacterClass.RANGER:
                return 5;
            case CharacterClass.ROGUE:
                return 4;
            case CharacterClass.WIZARD:
                return 3;
            default:
                return 4;
        }
    }

    public int roll_class_hit_die()
    {
        int roll = 1;
        switch (character_class)
        {
            case CharacterClass.BARBARIAN:
                while (roll == 1) roll = (int)(GD.Randi() % 12) + 1;
                break;
            case CharacterClass.FIGHTER:
            case CharacterClass.RANGER:
                while (roll == 1) roll = (int)(GD.Randi() % 10) + 1;
                break;
            case CharacterClass.CLERIC:
            case CharacterClass.ROGUE:
                while (roll == 1) roll = (int)(GD.Randi() % 8) + 1;
                break;
            case CharacterClass.WIZARD:
                while (roll == 1) roll = (int)(GD.Randi() % 4) + 1;
                break;
            default:
                while (roll == 1) roll = (int)(GD.Randi() % 8) + 1;
                break;
        }
        return roll;
    }

    public Godot.Collections.Dictionary get_stat_limits()
    {
        int base_min = 8;
        int base_max = 15;
        int racial_max = 17;
        var d = new Godot.Collections.Dictionary();
        d["min"] = base_min; d["max"] = base_max; d["racial_max"] = racial_max;
        return d;
    }

    public Godot.Collections.Dictionary get_racial_stat_bonuses()
    {
        var d = new Godot.Collections.Dictionary();
        switch (character_race)
        {
            case CharacterRace.HUMAN: d["str"] = 1; d["dex"] = 1; d["con"] = 1; d["int"] = 1; d["wis"] = 1; d["cha"] = 1; break;
            case CharacterRace.ELF: d["str"] = 0; d["dex"] = 2; d["con"] = 0; d["int"] = 1; d["wis"] = 0; d["cha"] = 0; break;
            case CharacterRace.DWARF: d["str"] = 0; d["dex"] = 0; d["con"] = 2; d["int"] = 0; d["wis"] = 1; d["cha"] = 0; break;
            case CharacterRace.HALFLING: d["str"] = 0; d["dex"] = 2; d["con"] = 0; d["int"] = 0; d["wis"] = 0; d["cha"] = 1; break;
            case CharacterRace.GNOME: d["str"] = 0; d["dex"] = 0; d["con"] = 1; d["int"] = 2; d["wis"] = 0; d["cha"] = 0; break;
            case CharacterRace.HALF_ELF: d["str"] = 0; d["dex"] = 1; d["con"] = 0; d["int"] = 0; d["wis"] = 1; d["cha"] = 2; break;
            case CharacterRace.HALF_ORC: d["str"] = 2; d["dex"] = 0; d["con"] = 1; d["int"] = 0; d["wis"] = 0; d["cha"] = 0; break;
            case CharacterRace.DRAGONBORN: d["str"] = 2; d["dex"] = 0; d["con"] = 0; d["int"] = 0; d["wis"] = 0; d["cha"] = 1; break;
            case CharacterRace.TIEFLING: d["str"] = 0; d["dex"] = 0; d["con"] = 0; d["int"] = 1; d["wis"] = 0; d["cha"] = 2; break;
            default: d["str"] = 0; d["dex"] = 0; d["con"] = 0; d["int"] = 0; d["wis"] = 0; d["cha"] = 0; break;
        }
        return d;
    }

    public string get_character_summary()
    {
        var summary = get_race_name() + " " + get_class_name() + "\n";
        summary += "Level " + level.ToString() + " (" + experience.ToString() + " XP)\n\n";

        var racial_bonuses = get_racial_stat_bonuses();
        summary += "STR: " + strength + " (base + racial)\n";
        summary += "DEX: " + dexterity + " (base + racial)\n";
        summary += "CON: " + constitution + " (base + racial)\n";
        summary += "INT: " + intelligence + " (base + racial)\n";
        summary += "WIS: " + wisdom + " (base + racial)\n";
        summary += "CHA: " + charisma + " (base + racial)\n\n";

        summary += "HP: " + current_health + "/" + max_health + "\n";
        summary += "AC: " + armor_class + "\n";
        summary += "Attack Bonus: +" + attack_bonus + "\n";
        summary += "Damage: " + damage_dice + "\n";
        summary += "XP: " + experience + "/" + get_xp_for_next_level() + "\n";

        return summary;
    }

    public int get_xp_for_level(int target_level)
    {
        if (target_level <= 1) return 0;
        var xp_table = new Dictionary<int,int>(){
            {2,300},{3,900},{4,2700},{5,6500},{6,14000},{7,23000},{8,34000},{9,48000},{10,64000},
            {11,85000},{12,100000},{13,120000},{14,140000},{15,165000},{16,195000},{17,225000},{18,265000},{19,305000},{20,355000}
        };
        if (xp_table.ContainsKey(target_level)) return xp_table[target_level];
        return 355000 + (target_level - 20) * 50000;
    }

    public int get_xp_for_next_level() => get_xp_for_level(level + 1);

    public float get_xp_progress()
    {
        int current_level_xp = get_xp_for_level(level);
        int next_level_xp = get_xp_for_next_level();
        int progress_in_level = experience - current_level_xp;
        int xp_needed_for_level = next_level_xp - current_level_xp;
        if (xp_needed_for_level <= 0) return 1.0f;
        return (float)progress_in_level / (float)xp_needed_for_level;
    }

    public bool gain_experience(int xp_amount)
    {
        int old_level = level;
        experience += xp_amount;
        GD.Print($"Gained {xp_amount} XP! Total: {experience}");
        while (experience >= get_xp_for_next_level() && level < 20)
        {
            level_up();
        }
        return level > old_level;
    }

    public void level_up()
    {
        int old_level = level;
        level += 1;
        GD.Print($"LEVEL UP! {character_name} is now level {level}");
        int hit_die_roll = roll_class_hit_die();
        int con_modifier = get_stat_modifier(constitution);
        int hp_gain = hit_die_roll + con_modifier;
        hp_gain = Math.Max(1, hp_gain);
        max_health += hp_gain;
        current_health += hp_gain;
        GD.Print($"Rolled {hit_die_roll} on hit die + {con_modifier} CON mod = {hp_gain} HP gained! New max HP: {max_health}");
        int old_attack_bonus = attack_bonus;
        calculate_attack_bonus();
        if (attack_bonus > old_attack_bonus) GD.Print($"Attack bonus increased to +{attack_bonus}");
        calculate_derived_stats();
        GD.Print($"Level {old_level} -> {level} complete!");
    }

    public void calculate_attack_bonus()
    {
        switch (character_class)
        {
            case CharacterClass.FIGHTER:
            case CharacterClass.RANGER:
            case CharacterClass.BARBARIAN:
                attack_bonus = level + get_stat_modifier(strength);
                break;
            case CharacterClass.CLERIC:
                attack_bonus = (int)(level * 0.75f) + get_stat_modifier(strength);
                break;
            case CharacterClass.ROGUE:
                attack_bonus = (int)(level * 0.5f) + get_stat_modifier(dexterity);
                break;
            case CharacterClass.WIZARD:
                attack_bonus = (int)(level * 0.5f) + get_stat_modifier(strength);
                break;
            default:
                attack_bonus = (int)(level * 0.5f);
                break;
        }
    }

    public int get_stat_modifier(int stat_value)
    {
        return (stat_value - 10) / 2;
    }

    public int award_xp_for_combat(int enemy_level)
    {
        int base_xp = enemy_level * 100;
        int level_difference = enemy_level - level;
        if (level_difference > 0) base_xp = (int)(base_xp * (1.0 + level_difference * 0.2));
        else if (level_difference < -2) base_xp = (int)(base_xp * 0.5);
        base_xp = Math.Max(10, base_xp);
        gain_experience(base_xp);
        return base_xp;
    }

    public int award_xp_for_exploration()
    {
        int xp_amount = 50 + level * 10;
        gain_experience(xp_amount);
        return xp_amount;
    }

    public int award_xp_for_quest(int difficulty_level)
    {
        int base_xp = difficulty_level * 200;
        gain_experience(base_xp);
        return base_xp;
    }
}
