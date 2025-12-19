# BetterResting Mod Setup Guide

## Quick Start

### Step 1: Locate Project Zomboid Mods Directory

**On Windows:**
Project Zomboid stores mods in:
```
C:\Users\[YourUsername]\Zomboid\mods\
```

For example, if your username is `Emilio`:
```
C:\Users\Emilio\Zomboid\mods\
```

**To open this directory:**
1. Press `Windows Key + R` to open Run dialog
2. Type: `%USERPROFILE%\Zomboid\mods`
3. Press Enter

**On Mac:**
Project Zomboid stores mods in:
```
~/Zomboid/mods/
```

To open this directory in Finder:
1. Press `Cmd + Shift + G` in Finder
2. Type: `~/Zomboid/mods/`
3. Press Enter

**If the `mods` folder doesn't exist, create it:**
- **Windows**: The folder will be created automatically when you copy the mod, or create it manually in File Explorer
- **Mac**: Run `mkdir -p ~/Zomboid/mods` in Terminal

### Step 2: Install Your Mod

**Windows - Copy Method (Recommended):**
1. Navigate to your mod folder: `C:\Users\Emilio\Desktop\BetterResting\mods\BetterResting`
2. Copy the entire `BetterResting` folder
3. Paste it into `C:\Users\Emilio\Zomboid\mods\`
4. The final path should be: `C:\Users\Emilio\Zomboid\mods\BetterResting\`

**Windows - Using Command Prompt or PowerShell:**
```powershell
# Open PowerShell and run:
xcopy "C:\Users\Emilio\Desktop\BetterResting\mods\BetterResting" "C:\Users\Emilio\Zomboid\mods\BetterResting\" /E /I
```

**Mac - Option A: Symlink (Recommended for Development)**
```bash
# This creates a symbolic link so changes are reflected immediately
ln -s /Users/emiliomontes/Desktop/projects/BetterResting ~/Zomboid/mods/BetterResting
```

**Mac - Option B: Copy (For Distribution)**
```bash
# Copy the entire mod folder
cp -r /Users/emiliomontes/Desktop/projects/BetterResting ~/Zomboid/mods/BetterResting
```

### Step 3: Verify Installation

Check that your mod structure looks like this:

**Windows:**
```
C:\Users\Emilio\Zomboid\mods\BetterResting\
├── mod.info
├── 42\
│   ├── lua\
│   │   ├── client\
│   │   │   └── BetterRestingClient.lua
│   │   ├── server\
│   │   │   └── BetterRestingServer.lua
│   │   └── shared\
│   │       └── BetterRestingShared.lua
│   └── media\
├── common\
└── [other files]
```

**Mac:**
```
~/Zomboid/mods/BetterResting/
├── mod.info
├── 42/
│   ├── lua/
│   │   ├── client/
│   │   │   └── BetterRestingClient.lua
│   │   ├── server/
│   │   │   └── BetterRestingServer.lua
│   │   └── shared/
│   │       └── BetterRestingShared.lua
│   └── media/
├── common/
└── [other files]
```

### Step 4: Enable the Mod

1. Launch Project Zomboid
2. From the main menu, click **Options**
3. Go to the **Mods** tab
4. Find **Better Resting** in the list
5. Check the box to enable it
6. Click **OK** and restart the game if prompted

## Development Workflow

### Testing Changes

If you used a symlink (Option A), changes will be reflected immediately. If you copied the files, you'll need to:
1. Make your changes
2. Copy the updated files to the mods directory
3. Restart Project Zomboid

### Finding Logs

**Windows:**
Project Zomboid logs are located at:
```
C:\Users\[YourUsername]\Zomboid\logs\
```

To view logs:
- Open the folder in File Explorer
- Look for files like `console.txt` and `LuaDebug.txt`
- Open them with Notepad or any text editor

**Mac:**
Project Zomboid logs are located at:
```
~/Zomboid/logs/
```

To view logs in real-time:
```bash
tail -f ~/Zomboid/logs/*.txt
```

### Editing Lua Files

You can use any text editor. Recommended editors:
- **Visual Studio Code** (with Lua extension) - Works on both Windows and Mac
- **Sublime Text** - Works on both platforms
- **Notepad++** - Windows only
- **TextMate** - Mac only

## Platform-Specific Notes

### Windows

1. **File Paths**: Windows uses backslashes (`\`) in paths, but the mod structure should work the same
2. **Case Sensitivity**: Windows file system is case-insensitive, but mod.info references are case-sensitive
3. **Permissions**: Usually not an issue on Windows, but ensure the mod folder isn't read-only

### Mac

1. **Build 42.13 Status**: As of this writing, Build 42 is unstable on Mac. Make sure you're testing with the correct build version.

2. **File Permissions**: Ensure your mod files have read permissions:
   ```bash
   chmod -R 755 ~/Zomboid/mods/BetterResting
   ```

3. **Case Sensitivity**: Mac's default filesystem (APFS) is case-insensitive, but be careful if you plan to distribute on other platforms.

## Troubleshooting

### Mod Not Appearing in Game
- Check that `mod.info` file exists and is properly formatted
- Verify the mod folder is named exactly `BetterResting` (case-sensitive in mod.info)
- Check the game's console for error messages

### Mod Not Loading
- **Windows**: Check `C:\Users\[YourUsername]\Zomboid\logs\` for Lua errors
- **Mac**: Check `~/Zomboid/logs/` for Lua errors
- Ensure all Lua files have proper syntax
- Verify Build 42.13 compatibility

### Changes Not Reflecting
- Make sure you're not running the game when editing files
- If using copy method, recopy after changes
- Clear game cache if necessary

## Next Steps

1. Edit `mod.info` to customize your mod name, description, and author
2. Implement your resting mechanics in the Lua files
3. Add any media files (textures, sounds) to the `media/` folder
4. Test thoroughly in-game
5. Consider uploading to Steam Workshop when ready

## Resources

- [Zomboid Modding Guide](https://github.com/FWolfe/Zomboid-Modding-Guide)
- [PZ Modding Community Discord](https://pzwiki.net/wiki/PZ_Modding_Community)
- [Project Zomboid Forums](https://theindiestone.com/forums/)

