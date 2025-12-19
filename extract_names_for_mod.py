#!/usr/bin/env python3
"""
Extract object names and generate detection patterns for BetterResting mod.
"""

import re

INPUT_FILE = "/Users/emiliomontes/Desktop/projects/BetterResting/BED_OBJECTS_FILTERED.txt"

def extract_all_objects():
    """Extract all objects from the filtered file."""
    objects = []
    current_obj = {}
    in_detailed = False
    
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        for line in f:
            if "DETAILED ENTRIES" in line:
                in_detailed = True
                continue
            
            if not in_detailed:
                continue
            
            if line.strip().startswith("--- Object #"):
                if current_obj:
                    objects.append(current_obj)
                current_obj = {}
            elif line.strip().startswith("CustomItem:"):
                current_obj['custom_item'] = line.split(":", 1)[1].strip()
            elif line.strip().startswith("CustomName:"):
                current_obj['custom_name'] = line.split(":", 1)[1].strip()
            elif line.strip().startswith("BedType:"):
                current_obj['bed_type'] = line.split(":", 1)[1].strip()
            elif line.strip().startswith("GroupName:"):
                current_obj['group_name'] = line.split(":", 1)[1].strip()
    
    if current_obj:
        objects.append(current_obj)
    
    return objects

def categorize_objects(objects):
    """Categorize objects into beds and chairs."""
    beds = []
    chairs = []
    
    for obj in objects:
        if not obj.get('custom_name') and not obj.get('custom_item'):
            continue
        
        name = (obj.get('custom_name') or obj.get('custom_item', '')).lower()
        bed_type = obj.get('bed_type', '')
        
        # Determine category
        is_seating = any(word in name for word in [
            'chair', 'stool', 'bench', 'couch', 'sofa', 'seat', 'seating', 
            'ottoman', 'pew', 'barstool', 'bar stool', 'table', 'picnic'
        ])
        is_bed = any(word in name for word in [
            'bed', 'beds', 'tent', 'sleeping', 'cot', 'gurney', 'coffin', 
            'mat', 'hay', 'shelter', 'stump', 'block'
        ])
        
        entry = {
            'name': name,
            'custom_item': obj.get('custom_item'),
            'custom_name': obj.get('custom_name'),
            'bed_type': bed_type
        }
        
        if bed_type in ['goodBed', 'averageBed']:
            beds.append(entry)
        elif is_seating:
            chairs.append(entry)
        elif is_bed:
            beds.append(entry)
        else:
            # Default: treat as bed if unclear
            beds.append(entry)
    
    return beds, chairs

def generate_detection_code(beds, chairs):
    """Generate the updated detectRestType function."""
    
    # Get unique names
    bed_names = sorted(set(obj['name'] for obj in beds))
    chair_names = sorted(set(obj['name'] for obj in chairs))
    
    # Get CustomItems
    bed_items = sorted(set(obj['custom_item'] for obj in beds if obj.get('custom_item')))
    chair_items = sorted(set(obj['custom_item'] for obj in chairs if obj.get('custom_item')))
    
    code = """-- Detect what type of rest location the player is at
function BetterResting.detectRestType(player)
    if not player then return BetterResting.RestType.FLOOR end
    
    -- Check if in vehicle
    local vehicle = player:getVehicle()
    if vehicle then
        return BetterResting.RestType.VEHICLE
    end
    
    -- Check current square for furniture
    local square = player:getCurrentSquare()
    if not square then return BetterResting.RestType.FLOOR end
    
    local objects = square:getObjects()
    if not objects then return BetterResting.RestType.FLOOR end
    
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj then
            -- Safely get sprite name with nil checks
            local sprite = obj:getSprite()
            if sprite then
                local spriteNameObj = sprite:getName()
                if spriteNameObj then
                    local spriteName = spriteNameObj:lower()
                    if spriteName then
                        -- Check for beds (comprehensive list)
                        if spriteName:find("bed") or 
                           spriteName:find("furniture_bed") or
                           spriteName:find("furniture_sleeping") or
                           spriteName:find("beds") or
                           spriteName:find("tent") or
                           spriteName:find("sleeping") or
                           spriteName:find("cot") or
                           spriteName:find("gurney") or
                           spriteName:find("coffin") or
                           spriteName:find("mat") or
                           spriteName:find("gymnmat") or
                           spriteName:find("hay") or
                           spriteName:find("shelter") or
                           spriteName:find("stump") or
                           spriteName:find("block") or
"""
    
    # Add bed name patterns
    for name in bed_names:
        # Create multiple pattern variations
        patterns = [name]
        patterns.append(name.replace(" ", "_"))
        patterns.append(name.replace(" ", ""))
        if " " in name:
            patterns.append(name.split()[0])  # First word
        
        for pattern in set(patterns):
            if len(pattern) > 2:  # Skip very short patterns
                code += f'                           spriteName:find("{pattern}") or\n'
    
    code += """                           false then
                            return BetterResting.RestType.BED
                        end
                        
                        -- Check for chairs/sofas/couches/seating (comprehensive list)
                        if spriteName:find("chair") or 
                           spriteName:find("sofa") or 
                           spriteName:find("couch") or
                           spriteName:find("seat") or
                           spriteName:find("furniture_seating") or
                           spriteName:find("seating") or
                           spriteName:find("bench") or
                           spriteName:find("stool") or
                           spriteName:find("barstool") or
                           spriteName:find("bar_stool") or
                           spriteName:find("ottoman") or
                           spriteName:find("pew") or
                           spriteName:find("picnic") or
                           spriteName:find("picknic") or
                           spriteName:find("table") or
"""
    
    # Add chair name patterns
    for name in chair_names:
        patterns = [name]
        patterns.append(name.replace(" ", "_"))
        patterns.append(name.replace(" ", ""))
        if " " in name:
            patterns.append(name.split()[0])
        
        for pattern in set(patterns):
            if len(pattern) > 2:
                code += f'                           spriteName:find("{pattern}") or\n'
    
    code += """                           false then
                            return BetterResting.RestType.CHAIR
                        end
                    end
                end
            end
        end
    end
    
    return BetterResting.RestType.FLOOR
end"""
    
    return code

def main():
    print("Extracting objects...")
    objects = extract_all_objects()
    print(f"Found {len(objects)} objects")
    
    print("Categorizing objects...")
    beds, chairs = categorize_objects(objects)
    print(f"Beds: {len(beds)}")
    print(f"Chairs: {len(chairs)}")
    
    print("Generating detection code...")
    code = generate_detection_code(beds, chairs)
    
    output_file = "/Users/emiliomontes/Desktop/projects/BetterResting/detection_code.lua"
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(code)
    
    print(f"\nGenerated code written to: {output_file}")
    print(f"\nBed names found: {len(set(obj['name'] for obj in beds))}")
    print(f"Chair names found: {len(set(obj['name'] for obj in chairs))}")

if __name__ == "__main__":
    main()

