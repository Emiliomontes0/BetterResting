# BetterResting - Project Zomboid Mod

A mod for Project Zomboid Build 42 that enhances resting mechanics, making every moment of rest more meaningful and rewarding. No more wasting time on the floor when you could be getting proper recovery!

## Features

- **Enhanced Chair/Sofa Resting**: Rest on any chair, sofa, stool, or bench and experience noticeably faster stamina recovery. Take a proper rest and you'll feel the benefits long after you get up.

- **Well Rested Buff**: Rest long enough on furniture to fully recover your stamina, and you'll gain a "Well Rested" buff that makes your activities less draining. The longer you rest, the longer the benefits last.

- **Vehicle Resting**: Taking a break in your vehicle? You'll recover faster than just sitting on the ground. Perfect for those long road trips across Knox County.

- **Bed Resting**: Beds, sleeping bags, cots, and tents now provide proper healing benefits. Your wounds will heal gradually, muscle strain will ease, and your overall health will improve while you rest.

- **Smart Detection**: The mod uses the game's built-in API for reliable detection, with comprehensive sprite lookup tables as a fallback. It intelligently knows when you're actually resting versus just passing through furniture, so you only get benefits when you deserve them.

## Installation

### Steam Workshop (Recommended)
1. Subscribe to the mod through Steam Workshop
2. The mod will be automatically installed
3. Enable it in-game: **Options** → **Mods** → Check **BetterResting**

### Manual Installation
1. Download the mod files
2. Extract to your Project Zomboid mods directory:
   - **Windows**: `C:\Users\[YourUsername]\Zomboid\mods\`
   - **Mac**: `~/Zomboid/mods/`
   - **Linux**: `~/.local/share/Steam/steamapps/common/ProjectZomboid/mods/`
3. Enable it in-game: **Options** → **Mods** → Check **BetterResting**

## How It Works

### Detection System
The mod uses a multi-layered detection system for maximum reliability:
1. **Game API Methods**: Primary detection using the game's built-in resting state methods
2. **Sprite Lookup Tables**: Comprehensive fallback system with 707+ sprite names (264 beds, 443 chairs)
3. **Movement Detection**: Prevents false positives by checking if the player is actually resting

This ensures accurate detection of:
- All types of beds (regular beds, sleeping bags, cots, gurneys)
- All seating furniture (chairs, sofas, couches, stools, benches, picnic tables)
- Tents and camping equipment
- Vehicles

### Chair/Sofa Resting
- Rest on any chair, sofa, stool, bench, or seating furniture
- Stamina recovers 7% faster than normal
- After resting long enough to fully recover stamina, gain a "Well Rested" buff
- The buff reduces stamina consumption by 25% for a duration based on how long you rested

### Vehicle Resting
- Rest in any vehicle seat
- Stamina recovers 10% faster than normal
- Perfect for quick recovery during long drives

### Bed Resting
- Rest in any bed, sleeping bag, cot, tent, or bed-like furniture
- Stamina recovers 20% faster than normal
- Wounds heal gradually over time
- Muscle strain (stiffness) recovers 30% faster
- Health gradually restores when resting

## Requirements

- Project Zomboid Build 42 or later
- No other mods required

## Technical Details

- Uses Project Zomboid's built-in API methods (`isResting()`, `isSittingOnFurniture()`, `isOnBed()`, etc.)
- Comprehensive sprite lookup tables for edge cases and maximum compatibility
- Server-side game mechanics with client-side UI feedback
- Movement detection prevents false positives when walking through furniture

## Compatibility

This mod is designed for Build 42. It may not work correctly with earlier builds.

## Credits

Created for Project Zomboid Build 42.

## License

[Add your license here]

## Support

If you encounter any issues or have suggestions, please report them on the Steam Workshop page or the mod's GitHub repository.
