using Godot;
using System;
using System.Linq;

public partial class CharacterCreation : Control
{
    [Signal]
    public delegate void CharacterCreatedEventHandler(CharacterData character_data);
    [Signal]
    public delegate void CharacterLoadedEventHandler(CharacterData character_data);

    // UI nodes
    private LineEdit nameInput;
    private OptionButton classOption;
    private Label classDescription;
    private OptionButton raceOption;
    private Label raceDescription;

    private Label strLabel, dexLabel, conLabel, intLabel, wisLabel, chaLabel;
    private Button strMinus, strPlus, dexMinus, dexPlus, conMinus, conPlus, intMinus, intPlus, wisMinus, wisPlus, chaMinus, chaPlus;
    private Label pointsRemaining;
    private Button rollStatsBtn, createBtn, loadBtn;

    private CharacterData characterData;
    private int availablePoints = 27;
    private int[] baseStats = new int[] { 8, 8, 8, 8, 8, 8 };

    private RandomNumberGenerator rng = new RandomNumberGenerator();

    public override void _Ready()
    {
        // Expose GDScript-style snake_case signals so other GDScript code
        // can connect to `character_created` and `character_loaded` like before.
        try {
            if (!HasSignal("character_created")) AddUserSignal("character_created", new Godot.Collections.Array());
            if (!HasSignal("character_loaded")) AddUserSignal("character_loaded", new Godot.Collections.Array());
        } catch { }

        // Cache UI nodes
        nameInput = GetNodeOrNull<LineEdit>("VBoxContainer/NameContainer/NameLineEdit");
        classOption = GetNodeOrNull<OptionButton>("VBoxContainer/ClassContainer/ClassOptionButton");
        classDescription = GetNodeOrNull<Label>("VBoxContainer/ClassContainer/ClassDescription");
        raceOption = GetNodeOrNull<OptionButton>("VBoxContainer/RaceContainer/RaceOptionButton");
        raceDescription = GetNodeOrNull<Label>("VBoxContainer/RaceContainer/RaceDescription");

        strLabel = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/StrContainer/StrValue");
        dexLabel = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/DexContainer/DexValue");
        conLabel = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/ConContainer/ConValue");
        intLabel = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/IntContainer/IntValue");
        wisLabel = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/WisContainer/WisValue");
        chaLabel = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/ChaContainer/ChaValue");

        strMinus = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/StrContainer/StrMinus");
        strPlus = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/StrContainer/StrPlus");
        dexMinus = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/DexContainer/DexMinus");
        dexPlus = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/DexContainer/DexPlus");
        conMinus = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/ConContainer/ConMinus");
        conPlus = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/ConContainer/ConPlus");
        intMinus = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/IntContainer/IntMinus");
        intPlus = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/IntContainer/IntPlus");
        wisMinus = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/WisContainer/WisMinus");
        wisPlus = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/WisContainer/WisPlus");
        chaMinus = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/ChaContainer/ChaMinus");
        chaPlus = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/ChaContainer/ChaPlus");

        pointsRemaining = GetNodeOrNull<Label>("VBoxContainer/StatsContainer/PointsLabel");
        rollStatsBtn = GetNodeOrNull<Button>("VBoxContainer/StatsContainer/RollStatsButton");
        createBtn = GetNodeOrNull<Button>("VBoxContainer/ButtonsContainer/CreateButton");
        loadBtn = GetNodeOrNull<Button>("VBoxContainer/ButtonsContainer/LoadButton");

        rng.Randomize();

        SetupCharacterCreation();
        ConnectSignals();
        UpdateDisplay();
    }

    private void SetupCharacterCreation()
    {
        characterData = new CharacterData();

        // Setup class options
        classOption?.Clear();
        classOption?.AddItem("Fighter");
        classOption?.AddItem("Rogue");
        classOption?.AddItem("Wizard");
        classOption?.AddItem("Cleric");
        classOption?.AddItem("Ranger");
        classOption?.AddItem("Barbarian");

        // Setup race options
        raceOption?.Clear();
        string[] races = new string[] { "Human", "Elf", "Dwarf", "Halfling", "Gnome", "Half-Elf", "Half-Orc", "Dragonborn", "Tiefling" };
        foreach (var r in races) raceOption?.AddItem(r);

    // Set default descriptions
    try { object cd = (object)characterData.get_class_description(); classDescription.Text = cd != null ? cd.ToString() : ""; } catch { }
    try { object rd = (object)characterData.get_race_description(); raceDescription.Text = rd != null ? rd.ToString() : ""; } catch { }

        // Set default values into the resource via Set for compatibility
        characterData.Set("strength", baseStats[0]);
        characterData.Set("dexterity", baseStats[1]);
        characterData.Set("constitution", baseStats[2]);
        characterData.Set("intelligence", baseStats[3]);
        characterData.Set("wisdom", baseStats[4]);
        characterData.Set("charisma", baseStats[5]);
    }

    private void ConnectSignals()
    {
        if (classOption != null) classOption.ItemSelected += (long idx) => OnClassSelected((int)idx);
        if (raceOption != null) raceOption.ItemSelected += (long idx) => OnRaceSelected((int)idx);
        if (rollStatsBtn != null) rollStatsBtn.Pressed += OnRollStats;
        if (createBtn != null) createBtn.Pressed += OnCreateCharacter;
        if (loadBtn != null) loadBtn.Pressed += OnLoadCharacter;

        // Stat adjustments
        if (strMinus != null) strMinus.Pressed += () => AdjustStat(0, -1);
        if (strPlus != null) strPlus.Pressed += () => AdjustStat(0, 1);
        if (dexMinus != null) dexMinus.Pressed += () => AdjustStat(1, -1);
        if (dexPlus != null) dexPlus.Pressed += () => AdjustStat(1, 1);
        if (conMinus != null) conMinus.Pressed += () => AdjustStat(2, -1);
        if (conPlus != null) conPlus.Pressed += () => AdjustStat(2, 1);
        if (intMinus != null) intMinus.Pressed += () => AdjustStat(3, -1);
        if (intPlus != null) intPlus.Pressed += () => AdjustStat(3, 1);
        if (wisMinus != null) wisMinus.Pressed += () => AdjustStat(4, -1);
        if (wisPlus != null) wisPlus.Pressed += () => AdjustStat(4, 1);
        if (chaMinus != null) chaMinus.Pressed += () => AdjustStat(5, -1);
        if (chaPlus != null) chaPlus.Pressed += () => AdjustStat(5, 1);
    }

    private void OnClassSelected(int index)
    {
        try { characterData.Set("character_class", index); } catch { }
        try { var cd = (object)characterData.get_class_description(); classDescription.Text = cd != null ? cd.ToString() : ""; } catch { }
        UpdateDisplay();
    }

    private void OnRaceSelected(int index)
    {
        try { characterData.Set("character_race", index); } catch { }
        try { var rd = (object)characterData.get_race_description(); raceDescription.Text = rd != null ? rd.ToString() : ""; } catch { }
        UpdateDisplay();
    }

    private void AdjustStat(int statIndex, int delta)
    {
        var currentValue = baseStats[statIndex];
        var newValue = currentValue + delta;

        var oldCost = GetStatCost(currentValue);
        var newCost = GetStatCost(newValue);
        var costDifference = newCost - oldCost;

        if (newValue >= 8 && newValue <= 15 && availablePoints >= costDifference)
        {
            baseStats[statIndex] = newValue;
            availablePoints -= costDifference;
            UpdateCharacterStats();
            UpdateDisplay();
        }
    }

    private int GetStatCost(int value)
    {
        if (value <= 8) return 0;
        else if (value <= 13) return value - 8;
        else if (value <= 15) return 5 + (value - 13) * 2;
        else return 999;
    }

    private void OnRollStats()
    {
        for (int i = 0; i < 6; i++)
        {
            int[] rolls = new int[4];
            for (int j = 0; j < 4; j++) rolls[j] = (int)rng.RandiRange(1, 6);
            Array.Sort(rolls);
            // sum top 3
            baseStats[i] = rolls[1] + rolls[2] + rolls[3];
        }
        availablePoints = 0; // disable point-buy
        UpdateCharacterStats();
        UpdateDisplay();
    }

    private void UpdateCharacterStats()
    {
        try { characterData.Set("strength", baseStats[0]); } catch { }
        try { characterData.Set("dexterity", baseStats[1]); } catch { }
        try { characterData.Set("constitution", baseStats[2]); } catch { }
        try { characterData.Set("intelligence", baseStats[3]); } catch { }
        try { characterData.Set("wisdom", baseStats[4]); } catch { }
        try { characterData.Set("charisma", baseStats[5]); } catch { }
    }

    private void UpdateDisplay()
    {
        // Obtain racial bonuses dictionary if provided by CharacterData
        object racialBonusesObj = (object)characterData.get_racial_stat_bonuses();
        Godot.Collections.Dictionary racialBonuses = racialBonusesObj as Godot.Collections.Dictionary ?? new Godot.Collections.Dictionary();

        int rb(string k)
        {
            if (racialBonuses == null)
                return 0;
            try
            {
                var keys = racialBonuses.Keys;
                foreach (var keyVar in keys)
                {
                    object keyObj = (object)keyVar;
                    if (keyObj != null && keyObj.ToString() == k)
                    {
                        try { return Convert.ToInt32(racialBonuses[keyVar]); } catch { return 0; }
                    }
                }
            }
            catch { }
            return 0;
        }

        int strFinal = baseStats[0] + rb("str");
        int dexFinal = baseStats[1] + rb("dex");
        int conFinal = baseStats[2] + rb("con");
        int intFinal = baseStats[3] + rb("int");
        int wisFinal = baseStats[4] + rb("wis");
        int chaFinal = baseStats[5] + rb("cha");

        if (strLabel != null) strLabel.Text = baseStats[0].ToString() + (rb("str") > 0 ? $" + {rb("str")} = {strFinal}" : "");
        if (dexLabel != null) dexLabel.Text = baseStats[1].ToString() + (rb("dex") > 0 ? $" + {rb("dex")} = {dexFinal}" : "");
        if (conLabel != null) conLabel.Text = baseStats[2].ToString() + (rb("con") > 0 ? $" + {rb("con")} = {conFinal}" : "");
        if (intLabel != null) intLabel.Text = baseStats[3].ToString() + (rb("int") > 0 ? $" + {rb("int")} = {intFinal}" : "");
        if (wisLabel != null) wisLabel.Text = baseStats[4].ToString() + (rb("wis") > 0 ? $" + {rb("wis")} = {wisFinal}" : "");
        if (chaLabel != null) chaLabel.Text = baseStats[5].ToString() + (rb("cha") > 0 ? $" + {rb("cha")} = {chaFinal}" : "");

        if (pointsRemaining != null) pointsRemaining.Text = "Points Remaining: " + availablePoints.ToString();

        bool usingPointBuy = (availablePoints > 0) || (availablePoints == 0 && baseStats.Max() <= 15);

        if (strMinus != null) strMinus.Disabled = !usingPointBuy || baseStats[0] <= 8 || GetStatCost(baseStats[0] - 1) < 0;
        if (strPlus != null) strPlus.Disabled = !usingPointBuy || baseStats[0] >= 15 || availablePoints < (GetStatCost(baseStats[0] + 1) - GetStatCost(baseStats[0]));
        if (dexMinus != null) dexMinus.Disabled = !usingPointBuy || baseStats[1] <= 8 || GetStatCost(baseStats[1] - 1) < 0;
        if (dexPlus != null) dexPlus.Disabled = !usingPointBuy || baseStats[1] >= 15 || availablePoints < (GetStatCost(baseStats[1] + 1) - GetStatCost(baseStats[1]));
        if (conMinus != null) conMinus.Disabled = !usingPointBuy || baseStats[2] <= 8 || GetStatCost(baseStats[2] - 1) < 0;
        if (conPlus != null) conPlus.Disabled = !usingPointBuy || baseStats[2] >= 15 || availablePoints < (GetStatCost(baseStats[2] + 1) - GetStatCost(baseStats[2]));
        if (intMinus != null) intMinus.Disabled = !usingPointBuy || baseStats[3] <= 8 || GetStatCost(baseStats[3] - 1) < 0;
        if (intPlus != null) intPlus.Disabled = !usingPointBuy || baseStats[3] >= 15 || availablePoints < (GetStatCost(baseStats[3] + 1) - GetStatCost(baseStats[3]));
        if (wisMinus != null) wisMinus.Disabled = !usingPointBuy || baseStats[4] <= 8 || GetStatCost(baseStats[4] - 1) < 0;
        if (wisPlus != null) wisPlus.Disabled = !usingPointBuy || baseStats[4] >= 15 || availablePoints < (GetStatCost(baseStats[4] + 1) - GetStatCost(baseStats[4]));
        if (chaMinus != null) chaMinus.Disabled = !usingPointBuy || baseStats[5] <= 8 || GetStatCost(baseStats[5] - 1) < 0;
        if (chaPlus != null) chaPlus.Disabled = !usingPointBuy || baseStats[5] >= 15 || availablePoints < (GetStatCost(baseStats[5] + 1) - GetStatCost(baseStats[5]));
    }

    private void OnCreateCharacter()
    {
        if (nameInput == null || string.IsNullOrWhiteSpace(nameInput.Text))
        {
            GD.Print("Please enter a character name");
            return;
        }

        var name = nameInput.Text.Trim();
        try { characterData.Set("character_name", name); } catch { }
        try { characterData.apply_class_bonuses(); } catch { }
        try { characterData.calculate_derived_stats(); } catch { }

        SaveCharacter(characterData);

        EmitSignal("character_created", characterData);
    }

    private void OnLoadCharacter()
    {
        var fileDialog = new FileDialog();
        fileDialog.FileMode = FileDialog.FileModeEnum.OpenFile;
        fileDialog.Access = FileDialog.AccessEnum.Userdata;
        fileDialog.AddFilter("*.tres ; Character Files");
        fileDialog.CurrentDir = "user://characters/";
        AddChild(fileDialog);
        fileDialog.FileSelected += OnCharacterFileSelected;
    fileDialog.PopupCentered();
    }

    private void OnCharacterFileSelected(string path)
    {
        var loaded = GD.Load<CharacterData>(path);
        if (loaded != null)
        {
            if (nameInput != null)
            {
                try { object n = (object)loaded.Get("character_name"); nameInput.Text = n != null ? n.ToString() : ""; } catch { nameInput.Text = ""; }
            }
            try { object cc = (object)loaded.Get("character_class"); if (cc != null) classOption.Selected = Convert.ToInt32(cc); } catch { }
            try { object cr = (object)loaded.Get("character_race"); if (cr != null) raceOption.Selected = Convert.ToInt32(cr); } catch { }
            try { object cdesc = (object)loaded.get_class_description(); classDescription.Text = cdesc != null ? cdesc.ToString() : ""; } catch { }
            try { object rdesc = (object)loaded.get_race_description(); raceDescription.Text = rdesc != null ? rdesc.ToString() : ""; } catch { }

            EmitSignal("character_loaded", loaded);
        }
        else
        {
            GD.Print($"Failed to load character from: {path}");
        }
    }

    private void SaveCharacter(CharacterData charData)
    {
        try
        {
            DirAccess.MakeDirRecursiveAbsolute("user://characters/");
        }
        catch { }

    string name = "unnamed";
    try { object n = (object)charData.Get("character_name"); if (n != null) name = n.ToString(); } catch { }
        var savePath = $"user://characters/{name.ToLower().Replace(' ', '_')}.tres";
        var res = ResourceSaver.Save(charData, savePath);
        if (res == Error.Ok)
            GD.Print($"Character saved to: {savePath}");
        else
            GD.PrintErr("Failed to save character!");
    }
}
