# BetterResting - Project Zomboid Mod

A mod for Project Zomboid Build 42.13 that improves resting and sleeping mechanics.

## Installation (Mac)

### For Local Development:
1. Navigate to your Project Zomboid mods directory:
   ```
   ~/Zomboid/mods/
   ```

2. If the `mods` directory doesn't exist, create it:
   ```bash
   mkdir -p ~/Zomboid/mods
   ```

3. Copy this entire `BetterResting` folder to the mods directory:
   ```bash
   cp -r BetterResting ~/Zomboid/mods/
   ```

4. Your mod structure should look like:
   ```
   ~/Zomboid/mods/BetterResting/
   ├── mod.info
   ├── lua/
   ├── media/
   └── README.md
   ```

### For Steam Workshop:
1. Subscribe to the mod through Steam Workshop
2. The mod will be automatically installed

## Enabling the Mod

1. Launch Project Zomboid
2. Go to **Options** → **Mods**
3. Check the box next to **Better Resting**
4. Restart the game if required

## Structure

- `mod.info` - Mod metadata and configuration
- `lua/` - Lua scripts for mod functionality
- `media/` - Textures, sounds, and other media files
- `README.md` - This file

## Development Notes

- Build 42.13 is an unstable build, so be prepared for compatibility issues
- Test thoroughly before releasing
- Make sure all Lua scripts are compatible with Build 42.13 API

## Resources

- [Zomboid Modding Guide](https://github.com/FWolfe/Zomboid-Modding-Guide)
- [PZ Modding Community](https://pzwiki.net/wiki/PZ_Modding_Community)
- [Project Zomboid Modding Policy](https://projectzomboid.com/blog/modding-policy/)

## License

[Add your license here]

