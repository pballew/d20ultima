class_name Item
extends Resource

enum ItemType { WEAPON, ARMOR, CONSUMABLE, MISC }

@export var item_name: String = ""
@export var description: String = ""
@export var item_type: ItemType = ItemType.MISC
@export var value: int = 0

# Weapon properties
@export var damage_dice: String = "1d4"
@export var attack_bonus: int = 0

# Armor properties
@export var armor_bonus: int = 0

# Consumable properties
@export var healing_amount: int = 0
@export var uses: int = 1

func use_item(character: Character):
	match item_type:
		ItemType.CONSUMABLE:
			if healing_amount > 0:
				character.heal(healing_amount)
				DebugLogger.info(str(character.name) + " " + str(" used ") + " " + str(item_name) + " " + str(" and healed for ") + " " + str(healing_amount) + " " + str(" HP"))
			uses -= 1
			if uses <= 0:
				character.remove_item(self)
		ItemType.WEAPON:
			character.equip_weapon(self)
		ItemType.ARMOR:
			character.equip_armor(self)


