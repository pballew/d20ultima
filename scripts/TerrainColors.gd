class_name TerrainColors
extends RefCounted

# Single source of truth for terrain colors
# Realistic palette - greens, yellows, blacks and dark greys (no red)
const TERRAIN_COLORS = {
	0: Color(0.2, 0.6, 0.2),          # GRASS (Bright green)
	1: Color(0.4, 0.4, 0.0),          # DIRT (Dark yellow-green)
	2: Color(0.3, 0.3, 0.3),          # STONE (Dark gray)
	3: Color(0.1, 0.2, 0.4),          # WATER (Dark blue)
	4: Color(0.1, 0.3, 0.1),          # TREE (Very dark green)
	5: Color(0.2, 0.2, 0.2),          # MOUNTAIN (Very dark gray)
	6: Color(0.3, 0.5, 0.2),          # VALLEY (Medium green)
	7: Color(0.2, 0.3, 0.4),          # RIVER (Dark blue-gray)
	8: Color(0.05, 0.15, 0.3),        # LAKE (Very dark blue)
	9: Color(0.0, 0.1, 0.2),          # OCEAN (Almost black-blue)
	10: Color(0.05, 0.2, 0.05),       # FOREST (Almost black-green)
	11: Color(0.5, 0.6, 0.3),         # HILLS (Yellow-green)
	12: Color(0.6, 0.6, 0.4),         # BEACH (Light yellow)
	13: Color(0.1, 0.1, 0.1),         # SWAMP (Very dark gray/black)
	14: Color(0.6, 0.5, 0.3)          # TOWN (Light brown - medieval buildings)
}