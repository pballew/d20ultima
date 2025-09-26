class_name TownNameGenerator
extends RefCounted

# Medieval town name generator for D20 Ultima-style RPG

# Medieval prefixes
const PREFIXES = [
	"Ald", "Ash", "Ban", "Black", "Bright", "Cold", "Dark", "Deep",
	"Dragon", "Eagle", "Elder", "Fair", "Gold", "Green", "Grey", "High",
	"Iron", "King", "Long", "New", "North", "Old", "Red", "River", 
	"Rock", "Silver", "South", "Stone", "White", "Wild", "Wolf"
]

# Medieval suffixes for towns
const SUFFIXES = [
	"bridge", "brook", "burg", "by", "dale", "ford", "gate", "haven",
	"helm", "hill", "hold", "moor", "port", "ridge", "shire", "stead",
	"stone", "ton", "vale", "wall", "watch", "well", "wick", "wood"
]

# Additional full town names for variety
const FULL_NAMES = [
	"Camelot", "Avalon", "Eldoria", "Thornwick", "Ravenscroft", "Millhaven",
	"Oakenford", "Shadowmere", "Brightwater", "Ironhold", "Goldmeadow",
	"Winterfell", "Summerhall", "Autumnrest", "Springdale", "Moonhaven"
]

static func generate_town_name(seed: int = -1) -> String:
	var rng = RandomNumberGenerator.new()
	if seed != -1:
		rng.seed = seed
	else:
		rng.randomize()
	
	# 30% chance for a full name, 70% chance for prefix+suffix
	if rng.randf() < 0.3:
		return FULL_NAMES[rng.randi() % FULL_NAMES.size()]
	else:
		var prefix = PREFIXES[rng.randi() % PREFIXES.size()]
		var suffix = SUFFIXES[rng.randi() % SUFFIXES.size()]
		return prefix + suffix

static func generate_town_data(position: Vector2i, seed: int = -1) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	if seed != -1:
		rng.seed = seed
	else:
		rng.randomize()
	
	var town_name = generate_town_name(seed)
	
	# Generate town properties
	var population = rng.randi_range(50, 500)  # Small to medium towns
	var has_inn = population > 100 or rng.randf() < 0.6  # Bigger towns more likely to have inn
	var has_shop = population > 150 or rng.randf() < 0.4  # Shops in larger towns
	var has_temple = population > 200 or rng.randf() < 0.3  # Temples in larger towns
	
	return {
		"name": town_name,
		"position": position,
		"population": population,
		"has_inn": has_inn,
		"has_shop": has_shop,
		"has_temple": has_temple,
		"founded_year": rng.randi_range(800, 1200)  # Medieval timeframe
	}