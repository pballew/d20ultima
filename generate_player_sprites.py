#!/usr/bin/env python3
"""
Direct sprite generator for the Godot RPG game.
Creates 64x64 pixel player sprites for all race/class combinations.
"""

from PIL import Image, ImageDraw
import os

# Race palettes (skin color, primary clothing color)
RACE_PALETTES = {
    "Human": {"skin": (230, 191, 153), "primary": (51, 77, 204)},
    "Elf": {"skin": (217, 204, 179), "primary": (26, 153, 51)},
    "Dwarf": {"skin": (204, 166, 128), "primary": (153, 77, 26)},
    "Halfling": {"skin": (230, 179, 140), "primary": (102, 128, 51)},
    "Gnome": {"skin": (217, 191, 153), "primary": (179, 51, 179)},
    "Half-Elf": {"skin": (222, 196, 161), "primary": (64, 115, 217)},
    "Half-Orc": {"skin": (140, 179, 115), "primary": (89, 128, 51)},
    "Dragonborn": {"skin": (153, 102, 51), "primary": (204, 77, 38)},
    "Tiefling": {"skin": (140, 64, 64), "primary": (128, 26, 153)}
}

# Class glyphs (color, weapon type)
CLASS_GLYPHS = {
    "Fighter": {"color": (179, 179, 179), "type": "sword"},
    "Rogue": {"color": (153, 153, 153), "type": "dagger"},
    "Wizard": {"color": (230, 230, 255), "type": "staff"},
    "Cleric": {"color": (255, 255, 204), "type": "mace"},
    "Ranger": {"color": (77, 179, 77), "type": "bow"},
    "Barbarian": {"color": (204, 153, 77), "type": "axe"}
}

def draw_base_body(draw, palette):
    """Draw the basic humanoid body."""
    skin = palette["skin"]
    primary = palette["primary"]
    
    # Head (circle)
    cx, cy = 32, 16
    r = 10
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=skin)
    
    # Hair (top of head)
    hair_color = (102, 51, 26)  # Brown hair
    draw.rectangle([cx-6, cy-6, cx+6, cy-2], fill=hair_color)
    
    # Torso (rectangle)
    draw.rectangle([cx-6, cy+6, cx+6, cy+26], fill=primary)
    
    # Arms
    draw.rectangle([cx-6, cy+4, cx-3, cy+10], fill=skin)  # Left arm
    draw.rectangle([cx+3, cy+4, cx+6, cy+10], fill=skin)   # Right arm
    
    # Legs (pants)
    pants_color = (38, 38, 51)
    draw.rectangle([cx-5, cy+26, cx-1, cy+40], fill=pants_color)  # Left leg
    draw.rectangle([cx+1, cy+26, cx+5, cy+40], fill=pants_color)   # Right leg
    
    # Feet (boots)
    boot_color = (77, 51, 26)
    draw.rectangle([cx-4, cy+40, cx+4, cy+42], fill=boot_color)

def draw_class_emblem(draw, glyph):
    """Draw the class-specific weapon/emblem."""
    color = glyph["color"]
    weapon_type = glyph["type"]
    
    if weapon_type == "sword":
        # Vertical sword blade
        draw.line([48, 20, 48, 44], fill=color, width=2)
        # Crossguard
        draw.line([44, 20, 52, 20], fill=color, width=2)
        
    elif weapon_type == "dagger":
        # Short blade
        draw.line([46, 24, 46, 40], fill=color, width=2)
        
    elif weapon_type == "staff":
        # Long staff
        draw.line([50, 12, 50, 50], fill=color, width=2)
        # Staff head
        draw.rectangle([48, 12, 52, 16], fill=color)
        
    elif weapon_type == "mace":
        # Handle
        draw.line([47, 18, 47, 46], fill=color, width=2)
        # Mace head
        draw.ellipse([45, 16, 49, 20], fill=color)
        
    elif weapon_type == "bow":
        # Bow string and curve
        draw.line([46, 18, 46, 46], fill=color, width=2)
        # Bow curve (simplified)
        draw.arc([44, 18, 48, 46], 270, 90, fill=color, width=1)
        
    elif weapon_type == "axe":
        # Handle
        draw.line([48, 18, 48, 44], fill=color, width=2)
        # Axe head
        draw.polygon([48, 18, 56, 18, 56, 26, 48, 26], fill=color)
        
    else:
        # Default: simple line
        draw.line([48, 20, 48, 36], fill=color, width=2)

def generate_sprite(race_name, class_name):
    """Generate a single 64x64 sprite for the given race/class combination."""
    # Create transparent image
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Get palettes
    palette = RACE_PALETTES.get(race_name, RACE_PALETTES["Human"])
    glyph = CLASS_GLYPHS.get(class_name, CLASS_GLYPHS["Fighter"])
    
    # Draw the sprite
    draw_base_body(draw, palette)
    draw_class_emblem(draw, glyph)
    
    return img

def main():
    """Generate all sprite combinations."""
    # Create output directory
    output_dir = "assets/player_sprites"
    os.makedirs(output_dir, exist_ok=True)
    
    total_generated = 0
    
    print("Generating player sprites...")
    
    # Generate all race/class combinations
    for race_name in RACE_PALETTES.keys():
        for class_name in CLASS_GLYPHS.keys():
            sprite = generate_sprite(race_name, class_name)
            filename = f"{output_dir}/{race_name}_{class_name}.png"
            sprite.save(filename)
            print(f"Generated: {filename}")
            total_generated += 1
    
    print(f"\nGenerated {total_generated} player sprites in {output_dir}/")
    print("Sprite combinations created:")
    print(f"- {len(RACE_PALETTES)} races: {', '.join(RACE_PALETTES.keys())}")
    print(f"- {len(CLASS_GLYPHS)} classes: {', '.join(CLASS_GLYPHS.keys())}")

if __name__ == "__main__":
    main()
