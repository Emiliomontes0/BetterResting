# BetterResting - Development Notes

## Project Overview

BetterResting is a mod for Project Zomboid Build 42.13 that enhances the resting and sleeping mechanics.

## Build 42.13 Considerations

**Important Notes:**
- Build 42.13 is an **unstable build** - expect changes and potential breaking updates
- Multiplayer support has been added, so consider both single-player and multiplayer scenarios
- Previous Build 41 mods are **not compatible** with Build 42
- Some API functions may have changed from Build 41

## Mod Structure

```
BetterResting/
├── mod.info              # Mod metadata
├── lua/
│   ├── client/          # Client-side scripts (UI, local player effects)
│   ├── server/          # Server-side scripts (game logic, mechanics)
│   └── shared/          # Shared code (utilities, config)
├── media/
│   ├── textures/        # Custom textures/images
│   └── sounds/          # Custom sounds/audio
└── [docs]               # Documentation files
```

## Lua Scripting Basics

### Client vs Server vs Shared

- **Client scripts** (`lua/client/`): Run only on the client
  - UI modifications
  - Local player visual effects
  - Client-side calculations
  
- **Server scripts** (`lua/server/`): Run on the server (or host in SP)
  - Game mechanics
  - Server-side calculations
  - Data persistence
  
- **Shared scripts** (`lua/shared/`): Loaded by both client and server
  - Configuration
  - Utility functions
  - Constants

### Common Events (Build 42)

```lua
-- Player events
Events.OnPlayerUpdate.Add(function(player)
    -- Called every frame for each player
end)

Events.OnPlayerDeath.Add(function(player)
    -- Called when player dies
end)

-- World events
Events.OnTick.Add(function()
    -- Called every game tick
end)

-- UI events
Events.OnGameStart.Add(function()
    -- Called when game starts
end)
```

### Accessing Player Data

```lua
local player = getPlayer()
if player then
    local stats = player:getStats()
    local fatigue = stats:getFatigue()
    local tiredness = stats:getTiredness()
    -- Modify stats here
end
```

## Resting/Sleep Mechanics

### Key Functions to Override/Modify

1. **Sleep Quality Calculation**
   - Bed quality affects sleep
   - Fatigue level affects sleep
   - Comfort level affects sleep

2. **Rest Effectiveness**
   - Time vs. recovery ratio
   - Different rest types (sitting, lying, sleeping)

3. **Fatigue/Tiredness**
   - How quickly tiredness builds
   - How quickly fatigue recovers

### Example Hook Points

```lua
-- In server script
local originalSleep = ISSleepDialog.onSleep
function ISSleepDialog.onSleep(self, hours)
    -- Your custom logic before sleep
    local result = originalSleep(self, hours)
    -- Your custom logic after sleep
    return result
end
```

## Testing Checklist

- [ ] Mod loads without errors
- [ ] Mod appears in mod list
- [ ] No Lua errors in console
- [ ] Resting mechanics work as intended
- [ ] Tested in single-player
- [ ] Tested in multiplayer (if applicable)
- [ ] Compatible with Build 42.13
- [ ] No conflicts with other mods (test with common mods)

## Debugging Tips

### Viewing Logs

```bash
# View recent log
tail -f ~/Zomboid/logs/console.txt

# Search for errors
grep -i error ~/Zomboid/logs/*.txt
```

### Print Statements

```lua
-- Use print() for debugging
print("BetterResting: Player fatigue = " .. fatigue)

-- Check if in sandbox mode
if isClient() then
    print("Running on client")
elseif isServer() then
    print("Running on server")
end
```

### Common Issues

1. **Mod not loading**: Check `mod.info` syntax
2. **Lua errors**: Check logs for syntax errors
3. **Nil errors**: Always check if objects exist before use
4. **Timing issues**: Use events instead of direct calls when possible

## API Documentation

For Build 42.13 API documentation:
- Check the Zomboid Modding Guide
- Look at vanilla game scripts in:
  - Windows: `Steam/steamapps/common/ProjectZomboid/media/lua/`
  - Mac: Similar path in your Steam library

## Version History

- **1.0** - Initial release for Build 42.13

## TODO

- [ ] Implement improved sleep quality calculations
- [ ] Add configurable rest bonuses
- [ ] Test multiplayer compatibility
- [ ] Add custom UI elements (if needed)
- [ ] Create custom textures/sounds (if needed)

## Notes

- Always backup your save files before testing mods
- Test on a fresh save first to avoid conflicts
- Document your changes for future reference

