#!/usr/bin/env python3
"""
Script to filter out duplicate objects from BED_OBJECTS_EXTRACTED.txt
Groups by CustomItem and keeps only one representative entry per unique CustomItem.
"""

import re
from collections import defaultdict

INPUT_FILE = "/Users/emiliomontes/Desktop/projects/BetterResting/BED_OBJECTS_EXTRACTED.txt"
OUTPUT_FILE = "/Users/emiliomontes/Desktop/projects/BetterResting/BED_OBJECTS_FILTERED.txt"

def parse_extracted_file(file_path):
    """Parse the extracted file and return a list of objects."""
    objects = []
    current_object = None
    in_tile_block = False
    tile_block_lines = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            # Detect start of new object
            if line.strip().startswith("--- Object #"):
                # Save previous object if exists
                if current_object:
                    current_object['tile_block'] = '\n'.join(tile_block_lines)
                    objects.append(current_object)
                
                # Start new object
                current_object = {
                    'header': line.strip(),
                    'lines': None,
                    'bed_type': None,
                    'custom_item': None,
                    'custom_name': None,
                    'sprite_name': None,
                    'group_name': None,
                    'tile_block': '',
                    'raw_lines': [line]
                }
                in_tile_block = False
                tile_block_lines = []
                continue
            
            if current_object:
                current_object['raw_lines'].append(line)
                
                # Parse metadata lines
                if line.strip().startswith("Lines:"):
                    current_object['lines'] = line.strip()
                elif line.strip().startswith("BedType:"):
                    current_object['bed_type'] = line.strip().split(":", 1)[1].strip()
                elif line.strip().startswith("CustomItem:"):
                    current_object['custom_item'] = line.strip().split(":", 1)[1].strip()
                elif line.strip().startswith("CustomName:"):
                    current_object['custom_name'] = line.strip().split(":", 1)[1].strip()
                elif line.strip().startswith("Sprite:"):
                    current_object['sprite_name'] = line.strip().split(":", 1)[1].strip()
                elif line.strip().startswith("GroupName:"):
                    current_object['group_name'] = line.strip().split(":", 1)[1].strip()
                elif line.strip() == "Tile block:":
                    in_tile_block = True
                    tile_block_lines = []
                elif in_tile_block:
                    tile_block_lines.append(line.rstrip())
                    # Check if we've reached the separator
                    if line.strip().startswith("-" * 80):
                        in_tile_block = False
        
        # Don't forget the last object
        if current_object:
            current_object['tile_block'] = '\n'.join(tile_block_lines)
            objects.append(current_object)
    
    return objects

def score_object(obj):
    """Score an object to determine which one to keep (higher score = more complete info)."""
    score = 0
    
    # Prefer objects with sprite names
    if obj.get('sprite_name'):
        score += 10
    
    # Prefer objects with more properties in tile block
    tile_block = obj.get('tile_block', '')
    
    # Prefer objects with ContainerCapacity (more complete)
    if 'ContainerCapacity' in tile_block:
        score += 5
    
    # Prefer objects with container property
    if 'container =' in tile_block:
        score += 3
    
    # Prefer objects with more lines (more complete definition)
    if obj.get('lines'):
        try:
            line_range = obj['lines'].split(":")[1].strip()
            if '-' in line_range:
                start, end = line_range.split('-')
                length = int(end) - int(start)
                score += min(length / 10, 5)  # Max 5 points for length
        except:
            pass
    
    return score

def get_object_key(obj):
    """Generate a unique key for grouping objects."""
    # Priority 1: CustomItem (most specific)
    custom_item = obj.get('custom_item')
    if custom_item:
        return f"ITEM:{custom_item}"
    
    # Priority 2: CustomName + GroupName (for objects like picnic tables, chairs)
    custom_name = obj.get('custom_name')
    group_name = obj.get('group_name')
    
    # Extract GroupName from tile block if not already parsed
    if not group_name:
        tile_block = obj.get('tile_block', '')
        group_match = re.search(r'GroupName\s*=\s*(\S+)', tile_block)
        if group_match:
            group_name = group_match.group(1)
    
    if custom_name:
        if group_name:
            return f"NAME:{custom_name}|GROUP:{group_name}"
        else:
            return f"NAME:{custom_name}"
    
    # Priority 3: Sprite name
    sprite_name = obj.get('sprite_name')
    if sprite_name:
        return f"SPRITE:{sprite_name}"
    
    # Priority 4: Extract from tile block comment or other fields
    comment_match = re.search(r'//\s*(\S+)', tile_block)
    if comment_match:
        return f"COMMENT:{comment_match.group(1)}"
    
    # Fallback: Use line numbers (shouldn't happen often)
    return f"FALLBACK:{obj.get('lines', 'unknown')}"

def filter_duplicates(objects):
    """Group objects by unique identifier and keep the best representative."""
    grouped = defaultdict(list)
    
    # Group by unique key
    for obj in objects:
        key = get_object_key(obj)
        grouped[key].append(obj)
    
    # For each group, keep the best representative
    filtered = []
    duplicates_removed = 0
    
    for key, group in grouped.items():
        if len(group) > 1:
            # Score each object and keep the best one
            scored = [(score_object(obj), i, obj) for i, obj in enumerate(group)]
            scored.sort(key=lambda x: (-x[0], x[1]))  # Sort by score descending, then by index
            best_obj = scored[0][2]
            filtered.append(best_obj)
            duplicates_removed += len(group) - 1
            
            # Show what we're grouping
            first_obj = group[0]
            identifier = first_obj.get('custom_item') or first_obj.get('custom_name') or key
            print(f"Group '{identifier}': Kept 1 out of {len(group)} variants")
        else:
            filtered.append(group[0])
    
    print(f"\nTotal objects: {len(objects)}")
    print(f"After filtering: {len(filtered)}")
    print(f"Duplicates removed: {duplicates_removed}")
    
    return filtered

def write_filtered_results(objects, output_file):
    """Write filtered results to output file."""
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("=" * 80 + "\n")
        f.write("PROJECT ZOMBOID - FILTERED RESTABLE OBJECTS\n")
        f.write("Duplicates removed - One entry per unique object type\n")
        f.write("=" * 80 + "\n\n")
        
        f.write(f"Total unique objects: {len(objects)}\n\n")
        
        # Group by bed type for summary
        by_bed_type = defaultdict(list)
        for obj in objects:
            bed_type = obj.get('bed_type', 'Unknown')
            by_bed_type[bed_type].append(obj)
        
        f.write("=" * 80 + "\n")
        f.write("SUMMARY BY BED TYPE\n")
        f.write("=" * 80 + "\n\n")
        for bed_type in sorted(by_bed_type.keys()):
            count = len(by_bed_type[bed_type])
            f.write(f"{bed_type}: {count} unique objects\n")
        f.write("\n")
        
        # Extract GroupName for display
        def get_group_name(obj):
            tile_block = obj.get('tile_block', '')
            group_match = re.search(r'GroupName\s*=\s*(\S+)', tile_block)
            return group_match.group(1) if group_match else None
        
        # List all unique objects
        f.write("=" * 80 + "\n")
        f.write("UNIQUE OBJECTS LIST\n")
        f.write("=" * 80 + "\n\n")
        for i, obj in enumerate(sorted(objects, key=lambda x: (x.get('custom_item') or '', x.get('custom_name') or '')), 1):
            custom_item = obj.get('custom_item')
            custom_name = obj.get('custom_name')
            group_name = get_group_name(obj)
            
            identifier = custom_item or custom_name or f"Object #{i}"
            f.write(f"{i}. {identifier}\n")
            if custom_item:
                f.write(f"   CustomItem: {custom_item}\n")
            if custom_name:
                f.write(f"   CustomName: {custom_name}\n")
            if group_name:
                f.write(f"   GroupName: {group_name}\n")
            f.write(f"   BedType: {obj.get('bed_type', 'N/A')}\n")
            if obj.get('sprite_name'):
                f.write(f"   Sprite: {obj.get('sprite_name')}\n")
            if obj.get('lines'):
                f.write(f"   Lines: {obj.get('lines')}\n")
            f.write("\n")
        
        # Detailed entries
        f.write("\n" + "=" * 80 + "\n")
        f.write("DETAILED ENTRIES (One per unique object type)\n")
        f.write("=" * 80 + "\n\n")
        
        for i, obj in enumerate(sorted(objects, key=lambda x: (x.get('custom_item') or '', x.get('custom_name') or '')), 1):
            f.write(f"\n{obj.get('header', f'--- Object #{i} ---')}\n")
            if obj.get('lines'):
                f.write(f"{obj.get('lines')}\n")
            if obj.get('bed_type'):
                f.write(f"BedType: {obj.get('bed_type')}\n")
            if obj.get('custom_item'):
                f.write(f"CustomItem: {obj.get('custom_item')}\n")
            if obj.get('custom_name'):
                f.write(f"CustomName: {obj.get('custom_name')}\n")
            if obj.get('sprite_name'):
                f.write(f"Sprite: {obj.get('sprite_name')}\n")
            
            if obj.get('tile_block'):
                f.write(f"\nTile block:\n{obj.get('tile_block')}\n")
            
            f.write("-" * 80 + "\n")
    
    print(f"\nFiltered results written to: {output_file}")

def main():
    print("Parsing extracted file...")
    objects = parse_extracted_file(INPUT_FILE)
    print(f"Parsed {len(objects)} objects")
    
    print("\nFiltering duplicates...")
    filtered = filter_duplicates(objects)
    
    print("\nWriting filtered results...")
    write_filtered_results(filtered, OUTPUT_FILE)
    
    print("\nDone!")

if __name__ == "__main__":
    main()

