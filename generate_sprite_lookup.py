#!/usr/bin/env python3
"""
Script to parse bedtype_tiles.md and generate Lua lookup tables for sprite name detection.
Organizes sprites by category (BED, CHAIR) based on CustomName and BedType values.
"""

import re
from collections import defaultdict

def parse_markdown_file(file_path):
    """
    Parse bedtype_tiles.md and extract sprite names with their metadata
    """
    tiles = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            # Skip header and separator lines
            if 'Sprite Name' in line or '---' in line or not line.strip():
                continue
            
            # Check if it's a table row
            if '|' in line and '`' in line:
                # Split by | and extract fields
                parts = [p.strip() for p in line.split('|')]
                if len(parts) >= 7:  # Should have 7 parts: empty, #, sprite, bedtype, customname, customitem, lines, empty
                    try:
                        idx = parts[1].strip()
                        sprite_match = re.search(r'`([^`]+)`', parts[2])
                        if sprite_match:
                            sprite = sprite_match.group(1)
                            bed_type = parts[3].strip()
                            custom_name = parts[4].strip()
                            custom_item = parts[5].strip()
                            
                            tiles.append({
                                'sprite': sprite,
                                'bed_type': bed_type,
                                'custom_name': custom_name,
                                'custom_item': custom_item,
                                'index': int(idx)
                            })
                    except (ValueError, IndexError) as e:
                        # Skip malformed rows
                        continue
    
    return tiles

def categorize_tile(tile):
    """
    Categorize a tile as BED or CHAIR based on CustomName and BedType
    """
    custom_name_lower = tile['custom_name'].lower()
    bed_type = tile['bed_type'].lower()
    
    # Beds: sleeping bags, tents, beds, cots, gurneys
    bed_keywords = ['bed', 'sleeping bag', 'tent', 'cot', 'gurney', 'mattress']
    # Chairs: chairs, couches, sofas, benches, stools, ottomans, seats, tables (picnic tables)
    chair_keywords = ['chair', 'couch', 'sofa', 'bench', 'stool', 'ottoman', 'seat', 'pew', 'table', 'picnic']
    
    # Check CustomName first
    for keyword in bed_keywords:
        if keyword in custom_name_lower:
            return 'BED'
    
    for keyword in chair_keywords:
        if keyword in custom_name_lower:
            return 'CHAIR'
    
    # Check BedType value
    # averageBed and goodBed are typically beds
    # badBed can be either, but if CustomName doesn't help, check sprite name
    if bed_type in ['averagebed', 'goodbed']:
        return 'BED'
    
    # If BedType is badBed and we can't determine from CustomName,
    # check sprite name patterns
    sprite_lower = tile['sprite'].lower()
    
    # Sprite name patterns for beds
    bed_patterns = ['bedding', 'camping_02', 'camping_01', 'camping_04']
    # Sprite name patterns for chairs
    chair_patterns = ['seating', 'furniture_seating']
    
    for pattern in bed_patterns:
        if pattern in sprite_lower:
            return 'BED'
    
    for pattern in chair_patterns:
        if pattern in sprite_lower:
            return 'CHAIR'
    
    # Default: if BedType exists but we can't categorize, treat as BED
    # (since most BedType items are beds)
    return 'BED'

def generate_lua_lookup(tiles, output_path):
    """
    Generate Lua lookup tables organized by category
    """
    # Organize tiles by category
    beds = []
    chairs = []
    uncategorized = []
    
    for tile in tiles:
        category = categorize_tile(tile)
        if category == 'BED':
            beds.append(tile)
        elif category == 'CHAIR':
            chairs.append(tile)
        else:
            uncategorized.append(tile)
    
    # Also create a flat lookup for quick access
    all_sprites = {}
    for tile in tiles:
        category = categorize_tile(tile)
        all_sprites[tile['sprite']] = category
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("-- Sprite Name Lookup Tables\n")
        f.write("-- Generated from bedtype_tiles.md\n")
        f.write("-- Total sprites: {}\n".format(len(tiles)))
        f.write("-- Beds: {}, Chairs: {}, Uncategorized: {}\n\n".format(
            len(beds), len(chairs), len(uncategorized)))
        
        # BED sprites lookup
        f.write("-- BED sprites (sleeping bags, tents, beds, cots, etc.)\n")
        f.write("BetterResting.BedSprites = {\n")
        for tile in sorted(beds, key=lambda x: x['sprite']):
            f.write('    ["{}"] = true,  -- {} ({})\n'.format(
                tile['sprite'], 
                tile['custom_name'] or 'N/A',
                tile['bed_type']
            ))
        f.write("}\n\n")
        
        # CHAIR sprites lookup
        f.write("-- CHAIR sprites (chairs, couches, sofas, benches, stools, etc.)\n")
        f.write("BetterResting.ChairSprites = {\n")
        for tile in sorted(chairs, key=lambda x: x['sprite']):
            f.write('    ["{}"] = true,  -- {} ({})\n'.format(
                tile['sprite'],
                tile['custom_name'] or 'N/A',
                tile['bed_type']
            ))
        f.write("}\n\n")
        
        # Combined lookup function
        f.write("-- Combined lookup function\n")
        f.write("-- Returns 'BED', 'CHAIR', or nil\n")
        f.write("function BetterResting.getRestTypeFromSprite(spriteName)\n")
        f.write("    if not spriteName then return nil end\n")
        f.write("    \n")
        f.write("    -- Check beds first\n")
        f.write("    if BetterResting.BedSprites[spriteName] then\n")
        f.write("        return BetterResting.RestType.BED\n")
        f.write("    end\n")
        f.write("    \n")
        f.write("    -- Check chairs\n")
        f.write("    if BetterResting.ChairSprites[spriteName] then\n")
        f.write("        return BetterResting.RestType.CHAIR\n")
        f.write("    end\n")
        f.write("    \n")
        f.write("    return nil\n")
        f.write("end\n\n")
        
        # Statistics
        f.write("-- Statistics\n")
        f.write("--[[\n")
        f.write("Total sprites: {}\n".format(len(tiles)))
        f.write("Beds: {}\n".format(len(beds)))
        f.write("Chairs: {}\n".format(len(chairs)))
        f.write("Uncategorized: {}\n".format(len(uncategorized)))
        f.write("\nBedType distribution:\n")
        bed_type_counts = defaultdict(int)
        for tile in tiles:
            bed_type_counts[tile['bed_type']] += 1
        for bed_type, count in sorted(bed_type_counts.items()):
            f.write("  {}: {}\n".format(bed_type, count))
        f.write("--]]\n")
    
    print(f"[OK] Generated Lua lookup table with {len(tiles)} sprites")
    print(f"[OK] Beds: {len(beds)}, Chairs: {len(chairs)}, Uncategorized: {len(uncategorized)}")
    print(f"[OK] Output written to: {output_path}")

if __name__ == '__main__':
    input_file = 'bedtype_tiles.md'
    output_file = 'sprite_lookup.lua'
    
    print(f"Reading from: {input_file}")
    print("Parsing tiles...")
    
    tiles = parse_markdown_file(input_file)
    generate_lua_lookup(tiles, output_file)
    
    print(f"\nDone! Check {output_file} for the generated lookup table.")

