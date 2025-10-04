using Godot;
using System;

public partial class Item : Resource
{
    public enum ItemType { WEAPON, ARMOR, CONSUMABLE, MISC }

    [Export] public string item_name = "";
    [Export] public string description = "";
    [Export] public ItemType item_type = ItemType.MISC;
    [Export] public int value = 0;

    [Export] public string damage_dice = "1d4";
    [Export] public int attack_bonus = 0;

    [Export] public int armor_bonus = 0;
    [Export] public int healing_amount = 0;
    [Export] public int uses = 1;

    public void UseItem(Node character)
    {
        // Minimal compatibility: call well-known methods if present
        if (item_type == ItemType.CONSUMABLE && healing_amount > 0)
        {
            if (character is Character c)
            {
                c.Heal(healing_amount);
                GD.Print($"{c.character_name} used {item_name} and healed {healing_amount}");
            }
        }
    }
}
