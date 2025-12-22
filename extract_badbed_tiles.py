#!/usr/bin/env python3
"""
Script to extract all tiles with BedType = (any value) from newtiledefinitions.tiles.txt
and output them to a markdown file.
"""

import re
from pathlib import Path

def parse_tiles_file(file_path, output_path):
    """
    Parse newtiledefinitions.tiles.txt and extract all tiles with BedType property (any value)
    """
    tiles = []
    current_sprite = None
    in_tile_block = False
    current_tile = {}
    tile_start_line = None
    
    with open(file_path, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, start=1):
            stripped = line.strip()
            
            # Check for sprite name comment (// sprite_name)
            if stripped.startswith('//') and not stripped.startswith('///'):
                sprite_match = re.match(r'//\s*(.+)', stripped)
                if sprite_match:
                    current_sprite = sprite_match.group(1).strip()
                    continue
            
            # Check if we're entering a tile block
            if stripped == 'tile':
                in_tile_block = True
                current_tile = {
                    'sprite': current_sprite,
                    'line_start': line_num,
                    'properties': {}
                }
                tile_start_line = line_num
                continue
            
            # Skip opening brace of tile block
            if in_tile_block and stripped == '{':
                continue
            
            # If we're in a tile block
            if in_tile_block:
                # Check for closing brace
                if stripped == '}':
                    # Check if this tile has BedType property (any value)
                    if 'BedType' in current_tile['properties'] or 'bed' in current_tile['properties']:
                        current_tile['line_end'] = line_num
                        tiles.append(current_tile.copy())
                    # Reset for next tile
                    in_tile_block = False
                    current_tile = {}
                    continue
                
                # Parse property lines (PropertyName = value)
                if '=' in stripped:
                    # Handle properties with or without values
                    prop_match = re.match(r'(\w+)\s*=\s*(.*)', stripped)
                    if prop_match:
                        prop_name = prop_match.group(1).strip()
                        prop_value = prop_match.group(2).strip()
                        current_tile['properties'][prop_name] = prop_value
    
    # Write to markdown file
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("# Tiles with BedType Property\n\n")
        f.write(f"Total tiles found: **{len(tiles)}**\n\n")
        
        # Summary table
        f.write("## Summary\n\n")
        f.write("| # | Sprite Name | BedType | CustomName | CustomItem | Lines |\n")
        f.write("|---|-------------|--------|------------|------------|-------|\n")
        
        for idx, tile in enumerate(tiles, start=1):
            sprite = tile['sprite'] or 'N/A'
            bed_type = tile['properties'].get('BedType', '')
            custom_name = tile['properties'].get('CustomName', '')
            custom_item = tile['properties'].get('CustomItem', '')
            line_range = f"{tile['line_start']}-{tile['line_end']}"
            f.write(f"| {idx} | `{sprite}` | {bed_type} | {custom_name} | {custom_item} | {line_range} |\n")
        
        f.write("\n---\n\n")
        
        for idx, tile in enumerate(tiles, start=1):
            f.write(f"## Tile {idx}: {tile['sprite']}\n\n")
            f.write(f"**Sprite Name:** `{tile['sprite']}`\n\n")
            f.write(f"**Location:** Lines {tile['line_start']}-{tile['line_end']}\n\n")
            f.write("**Tile Definition:**\n\n")
            f.write("```\n")
            f.write(f"    // {tile['sprite']}\n")
            f.write("    tile\n")
            f.write("    {\n")
            
            # Write properties in the same format as the original file
            # Sort properties but keep BedType first for visibility
            prop_items = sorted(tile['properties'].items())
            # Move BedType to front if it exists
            bed_type_item = None
            other_props = []
            for prop_name, prop_value in prop_items:
                if prop_name == 'BedType':
                    bed_type_item = (prop_name, prop_value)
                else:
                    other_props.append((prop_name, prop_value))
            
            # Write BedType first, then others
            if bed_type_item:
                prop_name, prop_value = bed_type_item
                if prop_value:
                    f.write(f"        {prop_name} = {prop_value}\n")
                else:
                    f.write(f"        {prop_name} = \n")
            
            for prop_name, prop_value in other_props:
                if prop_value:
                    f.write(f"        {prop_name} = {prop_value}\n")
                else:
                    f.write(f"        {prop_name} = \n")
            
            f.write("    }\n")
            f.write("```\n\n")
            f.write("---\n\n")
    
    print(f"[OK] Found {len(tiles)} tiles with BedType property")
    print(f"[OK] Output written to: {output_path}")
    return tiles

if __name__ == '__main__':
    # File paths
    input_file = Path(r'h:\SteamLibrary\steamapps\common\ProjectZomboid\media\newtiledefinitions.tiles.txt')
    output_file = Path('bedtype_tiles.md')
    
    if not input_file.exists():
        print(f"Error: Input file not found: {input_file}")
        print("Please update the path in the script.")
        exit(1)
    
    print(f"Reading from: {input_file}")
    print("Parsing tiles...")
    
    tiles = parse_tiles_file(input_file, output_file)
    
    print(f"\nDone! Check {output_file} for results.")

