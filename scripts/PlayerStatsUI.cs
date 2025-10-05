using Godot;
using System;

public partial class PlayerStatsUI : Control
{
    public Character player;

    private Label nameLabel;
    private Label levelLabel;
    private Label healthLabel;
    private ProgressBar healthBar;
    private Label xpLabel;
    private ProgressBar xpBar;
    private Label strLabel;
    private Label dexLabel;
    private Label conLabel;
    private Label intLabel;
    private Label wisLabel;
    private Label chaLabel;
    private Label acLabel;
    private Label attackLabel;

    public override void _Ready()
    {
        nameLabel = GetNodeOrNull<Label>("VBoxContainer/NameLabel");
        levelLabel = GetNodeOrNull<Label>("VBoxContainer/LevelLabel");
        healthLabel = GetNodeOrNull<Label>("VBoxContainer/HealthContainer/HealthLabel");
        healthBar = GetNodeOrNull<ProgressBar>("VBoxContainer/HealthContainer/HealthBar");
        xpLabel = GetNodeOrNull<Label>("VBoxContainer/ExperienceContainer/ExperienceLabel");
        xpBar = GetNodeOrNull<ProgressBar>("VBoxContainer/ExperienceContainer/ExperienceBar");
        strLabel = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/StrengthLabel");
        dexLabel = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/DexterityLabel");
        conLabel = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/ConstitutionLabel");
        intLabel = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/IntelligenceLabel");
        wisLabel = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/WisdomLabel");
        chaLabel = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/CharismaLabel");
        acLabel = GetNodeOrNull<Label>("VBoxContainer/CombatContainer/ArmorClassLabel");
        attackLabel = GetNodeOrNull<Label>("VBoxContainer/CombatContainer/AttackBonusLabel");
    }

    public void SetupPlayerStats(Node p)
    {
        if (p is Character c)
        {
            player = c;
            // Connect signals if present
            if (player.HasSignal("health_changed"))
                player.Connect("health_changed", new Callable(this, nameof(OnHealthChanged)));
            if (player.HasSignal("experience_changed"))
                player.Connect("experience_changed", new Callable(this, nameof(OnExperienceChanged)));
            UpdateAllStats();
        }
    }

    // snake_case alias used by GDScript
    public void setup_player_stats(Node p) => SetupPlayerStats(p);

    public void UpdateAllStats()
    {
        if (player == null) return;
        if (nameLabel != null) nameLabel.Text = player.character_name;
        if (levelLabel != null) levelLabel.Text = $"Level: {player.level}";
        if (healthLabel != null) healthLabel.Text = $"{player.current_health}/{player.max_health}";
        if (healthBar != null) healthBar.Value = player.max_health > 0 ? (float)player.current_health / player.max_health * 100f : 0f;
        if (xpLabel != null) xpLabel.Text = $"XP: {player.experience}";
        if (xpBar != null) xpBar.Value = player.GetXpProgress() * 100f;
        if (strLabel != null) strLabel.Text = $"STR: {player.strength} ({(player.GetModifier(player.strength)>=0?"+":"")}{player.GetModifier(player.strength)})";
        if (dexLabel != null) dexLabel.Text = $"DEX: {player.dexterity} ({(player.GetModifier(player.dexterity)>=0?"+":"")}{player.GetModifier(player.dexterity)})";
        if (conLabel != null) conLabel.Text = $"CON: {player.constitution} ({(player.GetModifier(player.constitution)>=0?"+":"")}{player.GetModifier(player.constitution)})";
        if (intLabel != null) intLabel.Text = $"INT: {player.intelligence} ({(player.GetModifier(player.intelligence)>=0?"+":"")}{player.GetModifier(player.intelligence)})";
        if (wisLabel != null) wisLabel.Text = $"WIS: {player.wisdom} ({(player.GetModifier(player.wisdom)>=0?"+":"")}{player.GetModifier(player.wisdom)})";
        if (chaLabel != null) chaLabel.Text = $"CHA: {player.charisma} ({(player.GetModifier(player.charisma)>=0?"+":"")}{player.GetModifier(player.charisma)})";
        if (acLabel != null) acLabel.Text = $"AC: {player.armor_class}";
        if (attackLabel != null) attackLabel.Text = $"Attack: +{player.attack_bonus}";
    }

    private void OnHealthChanged(int current, int max)
    {
        UpdateAllStats();
    }

    private void OnExperienceChanged(int xp, int lvl)
    {
        UpdateAllStats();
    }
}
