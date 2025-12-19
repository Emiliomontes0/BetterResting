#!/usr/bin/env python3
"""
Script to generate detection code for BetterResting mod from filtered objects.
"""

import re

INPUT_FILE = "/Users/emiliomontes/Desktop/projects/BetterResting/BED_OBJECTS_FILTERED.txt"

def extract_objects(file_path):
    """Extract all objects and categorize them."""
    beds = []  # goodBed and averageBed -> BED type
    chairs = []  # badBed seating -> CHAIR type
    bed_objects = []  # badBed beds -> BED type
    
    current_obj = {}
    in_detailed = False
    
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            # Check if we're in the detailed section
            if "DETAILED ENTRIES" in line:
                in_detailed = True
                continue
            
            if not in_detailed:
                continue
            
            # Parse object info
            if line.strip().startswith("CustomItem:"):
                current_obj['custom_item'] = line.split(":", 1)[1].strip()
            elif line.strip().startswith("CustomName:"):
                current_obj['custom_name'] = line.split(":", 1)[1].strip()
            elif line.strip().startswith("BedType:"):
                current_obj['bed_type'] = line.split(":", 1)[1].strip()
            elif line.strip().startswith("GroupName:"):
                current_obj['group_name'] = line.split(":", 1)[1].strip()
            elif line.strip().startswith("--- Object #"):
                # New object, save previous
                if current_obj:
                    obj_name = current_obj.get('custom_name') or current_obj.get('custom_item', '')
                    bed_type = current_obj.get('bed_type', '')
                    
                    if obj_name:
                        obj_entry = {
                            'name': obj_name.lower(),
                            'custom_item': current_obj.get('custom_item'),
                            'group_name': current_obj.get('group_name')
                        }
                        
                        # Categorize based on name and bed type
                        name_lower = obj_name.lower()
                        is_seating = any(word in name_lower for word in ['chair', 'stool', 'bench', 'couch', 'sofa', 'seat', 'seating', 'ottoman', 'pew', 'barstool', 'bar stool'])
                        is_table = 'table' in name_lower or 'picnic' in name_lower
                        is_bed = 'bed' in name_lower or 'tent' in name_lower or 'sleeping' in name_lower or 'cot' in name_lower or 'gurney' in name_lower or 'coffin' in name_lower or 'mat' in name_lower or 'hay' in name_lower or 'shelter' in name_lower or 'stump' in name_lower or 'block' in name_lower
                        
                        if bed_type == 'goodBed' or bed_type == 'averageBed':
                            # Good/average beds go to BED category
                            beds.append(obj_entry)
                        elif is_seating or is_table:
                            # Seating furniture with badBed -> CHAIR category
                            chairs.append(obj_entry)
                        elif is_bed:
                            # Bed-like objects with badBed -> BED category
                            bed_objects.append(obj_entry)
                        else:
                            # Default: if badBed and unclear, treat as bed
                            bed_objects.append(obj_entry)
                
                current_obj = {}
    
    # Don't forget the last object
    if current_obj:
        obj_name = current_obj.get('custom_name') or current_obj.get('custom_item', '')
        bed_type = current_obj.get('bed_type', '')
        
        if obj_name:
            obj_entry = {
                'name': obj_name.lower(),
                'custom_item': current_obj.get('custom_item'),
                'group_name': current_obj.get('group_name')
            }
            
            name_lower = obj_name.lower()
            is_seating = any(word in name_lower for word in ['chair', 'stool', 'bench', 'couch', 'sofa', 'seat', 'seating', 'ottoman', 'pew', 'barstool', 'bar stool'])
            is_table = 'table' in name_lower or 'picnic' in name_lower
            is_bed = 'bed' in name_lower or 'tent' in name_lower or 'sleeping' in name_lower or 'cot' in name_lower or 'gurney' in name_lower or 'coffin' in name_lower or 'mat' in name_lower or 'hay' in name_lower or 'shelter' in name_lower or 'stump' in name_lower or 'block' in name_lower
            
            if bed_type == 'goodBed' or bed_type == 'averageBed':
                beds.append(obj_entry)
            elif is_seating or is_table:
                chairs.append(obj_entry)
            elif is_bed:
                bed_objects.append(obj_entry)
            else:
                bed_objects.append(obj_entry)
    
    return beds, chairs, bed_objects

def generate_lua_code(beds, chairs, bed_objects):
    """Generate Lua detection code."""
    
    # Get unique names (lowercase)
    bed_names = set()
    for obj in beds + bed_objects:
        bed_names.add(obj['name'])
    
    chair_names = set()
    for obj in chairs:
        chair_names.add(obj['name'])
    
    # Generate bed detection patterns
    bed_patterns = []
    for name in sorted(bed_names):
        # Create pattern from name
        pattern = name:gsub(" ", "_"):gsub("-", "_")
        bed_patterns.append(f'                           spriteName:find("{name}") or')
    
    # Generate chair detection patterns
    chair_patterns = []
    for name in sorted(chair_names):
        pattern = name:gsub(" ", "_"):gsub("-", "_")
        chair_patterns.append(f'                           spriteName:find("{name}") or')
    
    # Also get CustomItem patterns for beds
    bed_custom_items = []
    for obj in beds + bed_objects:
        if obj.get('custom_item'):
            bed_custom_items.append(obj['custom_item'])
    
    chair_custom_items = []
    for obj in chairs:
        if obj.get('custom_item'):
            chair_custom_items.append(obj['custom_item'])
    
    lua_code = f"""-- Enhanced detection with all restable objects
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
            -- Check CustomItem first (most reliable)
            local customItem = obj:getCustomItem()
            if customItem then
                local itemType = customItem:getType()
                if itemType then
                    -- Bed CustomItems
                    local bedItems = {{
"""
    
    # Add bed CustomItems
    for item in sorted(set(bed_custom_items)):
        lua_code += f'                        "{item}",\n'
    
    lua_code += """                    }}
                    for _, bedItem in ipairs(bedItems) do
                        if itemType == bedItem then
                            return BetterResting.RestType.BED
                        end
                    end
                    
                    -- Chair CustomItems
                    local chairItems = {{
"""
    
    # Add chair CustomItems
    for item in sorted(set(chair_custom_items)):
        lua_code += f'                        "{item}",\n'
    
    lua_code += """                    }}
                    for _, chairItem in ipairs(chairItems) do
                        if itemType == chairItem then
                            return BetterResting.RestType.CHAIR
                        end
                    end
                end
            end
            
            -- Check CustomName (second priority)
            local customName = obj:getCustomName()
            if customName then
                local nameLower = customName:lower()
                
                -- Bed names
                local bedNames = {{
"""
    
    # Add bed names
    for name in sorted(bed_names):
        lua_code += f'                    "{name}",\n'
    
    lua_code += """                }}
                for _, bedName in ipairs(bedNames) do
                    if nameLower == bedName then
                        return BetterResting.RestType.BED
                    end
                end
                
                -- Chair names
                local chairNames = {{
"""
    
    # Add chair names
    for name in sorted(chair_names):
        lua_code += f'                    "{name}",\n'
    
    lua_code += """                }}
                for _, chairName in ipairs(chairNames) do
                    if nameLower == chairName then
                        return BetterResting.RestType.CHAIR
                    end
                end
            end
            
            -- Fallback: Check sprite name (original method)
            local sprite = obj:getSprite()
            if sprite then
                local spriteNameObj = sprite:getName()
                if spriteNameObj then
                    local spriteName = spriteNameObj:lower()
                    if spriteName then
                        -- Check for beds (original patterns + new ones)
                        if spriteName:find("bed") or 
                           spriteName:find("furniture_bed") or
                           spriteName:find("furniture_sleeping") or
"""
    
    # Add bed sprite patterns
    for name in sorted(bed_names):
        # Convert name to pattern (replace spaces with underscores, etc.)
        pattern = name.replace(" ", "_").replace("-", "_")
        lua_code += f'                           spriteName:find("{name}") or\n'
        if pattern != name:
            lua_code += f'                           spriteName:find("{pattern}") or\n'
    
    lua_code += """                           spriteName:find("tent") or
                           spriteName:find("sleeping") or
                           spriteName:find("cot") or
                           spriteName:find("gurney") or
                           spriteName:find("coffin") or
                           spriteName:find("mat") then
                            return BetterResting.RestType.BED
                        end
                        
                        -- Check for chairs/sofas/couches (original patterns + new ones)
                        if spriteName:find("chair") or 
                           spriteName:find("sofa") or 
                           spriteName:find("couch") or
                           spriteName:find("seat") or
                           spriteName:find("furniture_seating") or
"""
    
    # Add chair sprite patterns
    for name in sorted(chair_names):
        pattern = name.replace(" ", "_").replace("-", "_")
        lua_code += f'                           spriteName:find("{name}") or\n'
        if pattern != name:
            lua_code += f'                           spriteName:find("{pattern}") or\n'
    
    lua_code += """                           spriteName:find("bench") or
                           spriteName:find("stool") or
                           spriteName:find("ottoman") or
                           spriteName:find("pew") or
                           spriteName:find("picnic") or
                           spriteName:find("table") then
                            return BetterResting.RestType.CHAIR
                        end
                    end
                end
            end
        end
    end
    
    return BetterResting.RestType.FLOOR
end"""
    
    return lua_code

def main():
    print("Extracting objects from filtered file...")
    beds, chairs, bed_objects = extract_objects(INPUT_FILE)
    
    print(f"Found {len(beds)} good/average beds")
    print(f"Found {len(chairs)} seating objects")
    print(f"Found {len(bed_objects)} bed-like objects")
    
    print("\nGenerating Lua code...")
    lua_code = generate_lua_code(beds, chairs, bed_objects)
    
    output_file = "/Users/emiliomontes/Desktop/projects/BetterResting/detection_code_generated.lua"
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(lua_code)
    
    print(f"\nGenerated code written to: {output_file}")
    print("\nNote: You may need to adjust the API calls (getCustomItem, getCustomName)")
    print("based on the actual Project Zomboid Build 42 API.")

if __name__ == "__main__":
    main()

