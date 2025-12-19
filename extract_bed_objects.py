#!/usr/bin/env python3
"""
Script to extract all objects with BedType parameter from newtiledefinitions.tiles.txt
This will help identify all restable objects in Project Zomboid.
"""

import re
import os
from collections import defaultdict

# Path to the tiles file
TILES_FILE = "/Users/emiliomontes/Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java/media/newtiledefinitions.tiles.txt"
OUTPUT_FILE = "/Users/emiliomontes/Desktop/projects/BetterResting/BED_OBJECTS_EXTRACTED.txt"

def extract_bed_objects(file_path):
    """Extract all objects with BedType parameter from the tiles file."""
    
    bed_objects = []
    current_tile = {}
    in_tile_block = False
    brace_count = 0
    line_number = 0
    tile_start_line = 0
    
    print(f"Reading file: {file_path}")
    
    if not os.path.exists(file_path):
        print(f"ERROR: File not found: {file_path}")
        return []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                line_number += 1
                stripped = line.strip()
                
                # Detect start of a tile block
                if stripped == "tile" or stripped.startswith("tile "):
                    in_tile_block = True
                    brace_count = 0
                    current_tile = {
                        'line_start': line_number,
                        'bed_type': None,
                        'custom_item': None,
                        'custom_name': None,
                        'sprite_name': None,
                        'raw_lines': []
                    }
                    tile_start_line = line_number
                    continue
                
                # If we're in a tile block, collect information
                if in_tile_block:
                    current_tile['raw_lines'].append(line.rstrip())
                    
                    # Count braces to know when block ends
                    brace_count += line.count('{')
                    brace_count -= line.count('}')
                    
                    # Extract BedType
                    bed_type_match = re.search(r'BedType\s*=\s*(\S+)', line)
                    if bed_type_match:
                        current_tile['bed_type'] = bed_type_match.group(1)
                    
                    # Extract CustomItem
                    custom_item_match = re.search(r'CustomItem\s*=\s*(\S+)', line)
                    if custom_item_match:
                        current_tile['custom_item'] = custom_item_match.group(1)
                    
                    # Extract CustomName
                    custom_name_match = re.search(r'CustomName\s*=\s*(.+)', line)
                    if custom_name_match:
                        # Remove any trailing comments or whitespace
                        name = custom_name_match.group(1).strip()
                        # Remove trailing comments
                        if '//' in name:
                            name = name.split('//')[0].strip()
                        current_tile['custom_name'] = name
                    
                    # Extract sprite name from comment (e.g., // camping_01_1)
                    comment_match = re.search(r'//\s*(\S+)', line)
                    if comment_match and not current_tile['sprite_name']:
                        current_tile['sprite_name'] = comment_match.group(1)
                    
                    # Check if tile block is closed
                    if brace_count <= 0 and '{' in line or (brace_count == 0 and '}' in line):
                        # Block ended, check if it has BedType
                        if current_tile['bed_type']:
                            bed_objects.append({
                                'line_start': tile_start_line,
                                'line_end': line_number,
                                'bed_type': current_tile['bed_type'],
                                'custom_item': current_tile['custom_item'],
                                'custom_name': current_tile['custom_name'],
                                'sprite_name': current_tile['sprite_name'],
                                'raw_block': '\n'.join(current_tile['raw_lines'])
                            })
                        in_tile_block = False
                        current_tile = {}
    
    except Exception as e:
        print(f"ERROR reading file: {e}")
        return []
    
    return bed_objects

def write_results(bed_objects, output_file):
    """Write extracted results to output file."""
    
    # Group by bed type
    by_bed_type = defaultdict(list)
    for obj in bed_objects:
        by_bed_type[obj['bed_type']].append(obj)
    
    # Group by CustomItem to find unique items
    by_custom_item = defaultdict(list)
    for obj in bed_objects:
        if obj['custom_item']:
            by_custom_item[obj['custom_item']].append(obj)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("=" * 80 + "\n")
        f.write("PROJECT ZOMBOID - RESTABLE OBJECTS EXTRACTION\n")
        f.write("Extracted from newtiledefinitions.tiles.txt\n")
        f.write("=" * 80 + "\n\n")
        
        f.write(f"Total objects with BedType: {len(bed_objects)}\n")
        f.write(f"Unique BedType values: {len(by_bed_type)}\n")
        f.write(f"Unique CustomItems: {len(by_custom_item)}\n\n")
        
        # Summary by BedType
        f.write("=" * 80 + "\n")
        f.write("SUMMARY BY BED TYPE\n")
        f.write("=" * 80 + "\n\n")
        for bed_type in sorted(by_bed_type.keys()):
            count = len(by_bed_type[bed_type])
            f.write(f"{bed_type}: {count} objects\n")
        f.write("\n")
        
        # Unique CustomItems
        f.write("=" * 80 + "\n")
        f.write("UNIQUE CUSTOM ITEMS (Objects that can be rested on)\n")
        f.write("=" * 80 + "\n\n")
        for custom_item in sorted(by_custom_item.keys()):
            items = by_custom_item[custom_item]
            # Get the most common name for this item
            names = [obj['custom_name'] for obj in items if obj['custom_name']]
            unique_names = list(set(names))
            name_str = unique_names[0] if unique_names else "Unknown"
            
            bed_types = list(set([obj['bed_type'] for obj in items]))
            sprite_names = [obj['sprite_name'] for obj in items if obj['sprite_name']]
            unique_sprites = list(set(sprite_names))[:3]  # First 3 unique sprites
            
            f.write(f"\nCustomItem: {custom_item}\n")
            f.write(f"  Name: {name_str}\n")
            f.write(f"  BedType(s): {', '.join(bed_types)}\n")
            f.write(f"  Variants: {len(items)} tile definitions\n")
            if unique_sprites:
                f.write(f"  Sprite examples: {', '.join(unique_sprites)}\n")
            f.write(f"  Line range: {items[0]['line_start']}-{items[-1]['line_end']}\n")
        
        # Detailed list
        f.write("\n\n" + "=" * 80 + "\n")
        f.write("DETAILED LIST (All tile definitions)\n")
        f.write("=" * 80 + "\n\n")
        
        for i, obj in enumerate(bed_objects, 1):
            f.write(f"\n--- Object #{i} ---\n")
            f.write(f"Lines: {obj['line_start']}-{obj['line_end']}\n")
            f.write(f"BedType: {obj['bed_type']}\n")
            if obj['custom_item']:
                f.write(f"CustomItem: {obj['custom_item']}\n")
            if obj['custom_name']:
                f.write(f"CustomName: {obj['custom_name']}\n")
            if obj['sprite_name']:
                f.write(f"Sprite: {obj['sprite_name']}\n")
            f.write(f"\nTile block:\n{obj['raw_block']}\n")
            f.write("-" * 80 + "\n")
    
    print(f"\nResults written to: {output_file}")
    print(f"Total objects found: {len(bed_objects)}")
    print(f"Unique CustomItems: {len(by_custom_item)}")
    print(f"BedType values: {', '.join(sorted(by_bed_type.keys()))}")

def main():
    print("Extracting bed objects from newtiledefinitions.tiles.txt...")
    bed_objects = extract_bed_objects(TILES_FILE)
    
    if bed_objects:
        write_results(bed_objects, OUTPUT_FILE)
        print("\nExtraction complete!")
    else:
        print("No objects with BedType found.")

if __name__ == "__main__":
    main()

