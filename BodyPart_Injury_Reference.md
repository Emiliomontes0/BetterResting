# BodyPart Injury Properties Reference

Complete list of all injury-related properties and methods from `BodyPart.java`

## Injury Types (Boolean Flags)

### Basic Injury States
- `bandaged` - Whether the body part is bandaged
  - Methods: `bandaged()`, `setBandaged(boolean, float)`
  
- `bitten` - Whether the body part has been bitten
  - Methods: `bitten()`, `setBitten(boolean, float)`
  
- `scratched` - Whether the body part is scratched
  - Methods: `scratched()`, `setScratched(boolean, boolean)`
  
- `cut` - Whether the body part is cut
  - Methods: `isCut()`, `setCut(boolean)`
  
- `bleeding` - Whether the body part is bleeding
  - Methods: `bleeding()`, `setBleeding(boolean)`
  
- `stitched` - Whether the body part is stitched
  - Methods: `stitched()`, `setStitched(boolean)`
  
- `deepWounded` - Whether the body part has a deep wound
  - Methods: `isDeepWounded()`, `deepWounded()`, `setDeepWounded(boolean)`

### Infection & Treatment States
- `isInfected` - Whether the body part is infected (zombie infection)
  - Methods: `IsInfected()`, `SetInfected(boolean)`
  
- `isFakeInfected` - Whether fake infection (for certain game modes)
  - Methods: `IsFakeInfected()`, `SetFakeInfected(boolean)`, `DisableFakeInfection()`
  
- `infectedWound` - Whether the wound itself is infected
  - Methods: `isInfectedWound()`, `setInfectedWound(boolean)`
  
- `isBleedingStemmed` - Whether bleeding has been stemmed
  - Methods: `IsBleedingStemmed()`, `setIsBleedingStemmed(boolean)`
  
- `isCauterized` - Whether the wound has been cauterized
  - Methods: `IsCauterized()`, `setIsCauterized(boolean)`

### Other Injury States
- `haveGlass` - Whether there's glass in the wound
  - Methods: `haveGlass()`, `setHaveGlass(boolean)`
  
- `haveBullet` - Whether there's a bullet in the body part
  - Methods: `haveBullet()`, `setHaveBullet(boolean, int)`
  
- `splint` - Whether the body part has a splint
  - Methods: `isSplint()`, `setSplint(boolean, float)`
  
- `isBurnt()` - Whether the body part is burnt (checks if burnTime > 0)
  - Method: `isBurnt()`

## Injury Time Values (Float)

### Wound Healing Times
- `scratchTime` - Time remaining for scratch to heal
  - Methods: `getScratchTime()`, `setScratchTime(float)`
  - Range: 0.0 - 100.0
  
- `cutTime` - Time remaining for cut to heal
  - Methods: `getCutTime()`, `setCutTime(float)`
  - Range: 0.0 - 100.0
  
- `biteTime` - Time remaining for bite to heal
  - Methods: `getBiteTime()`, `setBiteTime(float)`
  
- `deepWoundTime` - Time remaining for deep wound to heal
  - Methods: `getDeepWoundTime()`, `setDeepWoundTime(float)`
  
- `bleedingTime` - Time remaining for bleeding to stop
  - Methods: `getBleedingTime()`, `setBleedingTime(float)`
  
- `stitchTime` - Time remaining for stitches to heal
  - Methods: `getStitchTime()`, `setStitchTime(float)`

### Other Time Values
- `burnTime` - Time remaining for burn to heal
  - Methods: `getBurnTime()`, `setBurnTime(float)`
  
- `fractureTime` - Time remaining for fracture to heal
  - Methods: `getFractureTime()`, `setFractureTime(float)`
  
- `lastTimeBurnWash` - Last time burn was washed
  - Methods: `getLastTimeBurnWash()`, `setLastTimeBurnWash(float)`

## Treatment & Healing Properties

### Bandaging
- `bandageLife` - Remaining life of the bandage
  - Methods: `getBandageLife()`, `setBandageLife(float)`
  
- `bandageType` - Type of bandage applied
  - Methods: `getBandageType()`, `setBandageType(String)`
  
- `alcoholicBandage` - Whether bandage has alcohol
  - Field: `alcoholicBandage`

### Splinting
- `splintFactor` - Factor affecting splint effectiveness
  - Methods: `getSplintFactor()`, `setSplintFactor(float)`
  
- `splintItem` - Item used as splint
  - Methods: `getSplintItem()`, `setSplintItem(String)`

### Herbal Treatments
- `plantainFactor` - Plantain treatment factor
  - Methods: `getPlantainFactor()`, `setPlantainFactor(float)`
  - Range: 0.0 - 100.0
  
- `comfreyFactor` - Comfrey treatment factor
  - Methods: `getComfreyFactor()`, `setComfreyFactor(float)`
  - Range: 0.0 - 100.0
  
- `garlicFactor` - Garlic treatment factor
  - Methods: `getGarlicFactor()`, `setGarlicFactor(float)`
  - Range: 0.0 - 100.0

### Infection Treatment
- `woundInfectionLevel` - Level of wound infection (0-10)
  - Methods: `getWoundInfectionLevel()`, `setWoundInfectionLevel(float)`
  - Range: -2.0 - 10.0
  
- `alcoholLevel` - Alcohol level for disinfection
  - Methods: `getAlcoholLevel()`, `setAlcoholLevel(float)`
  
- `needBurnWash` - Whether burn needs washing
  - Methods: `isNeedBurnWash()`, `setNeedBurnWash(boolean)`

## Pain & Discomfort

- `additionalPain` - Additional pain value
  - Methods: `getAdditionalPain()`, `getAdditionalPain(boolean includeStiffness)`, `setAdditionalPain(float)`
  
- `stiffness` - Muscle stiffness (0-100)
  - Methods: `getStiffness()`, `setStiffness(float)`, `addStiffness(float)`
  - Range: 0.0 - 100.0

- `getPain()` - Calculates total pain from all injuries
  - Returns: Combined pain from scratches, cuts, bites, deep wounds, fractures, burns, etc.

## Health

- `health` - Health of the body part (0-100)
  - Methods: `getHealth()`, `setHealth(float)`, `ReduceHealth(float)`, `AddDamage(float)`
  - Range: 0.0 - 100.0

## Speed Modifiers (Injury Impact on Movement)

- `scratchSpeedModifier` - Speed modifier from scratch
  - Methods: `getScratchSpeedModifier()`, `setScratchSpeedModifier(float)`
  
- `cutSpeedModifier` - Speed modifier from cut
  - Methods: `getCutSpeedModifier()`, `setCutSpeedModifier(float)`
  
- `burnSpeedModifier` - Speed modifier from burn
  - Methods: `getBurnSpeedModifier()`, `setBurnSpeedModifier(float)`
  
- `deepWoundSpeedModifier` - Speed modifier from deep wound
  - Methods: `getDeepWoundSpeedModifier()`, `setDeepWoundSpeedModifier(float)`

## XP Flags

- `getBandageXp` - Whether to give XP for bandaging
  - Methods: `isGetBandageXp()`, `setGetBandageXp(boolean)`
  
- `getStitchXp` - Whether to give XP for stitching
  - Methods: `isGetStitchXp()`, `setGetStitchXp(boolean)`
  
- `getSplintXp` - Whether to give XP for splinting
  - Methods: `isGetSplintXp()`, `setGetSplintXp(boolean)`

## Damage Constants

- `scratchDamage` = 0.9375F
- `cutDamage` = 1.875F
- `woundDamage` = 3.125F
- `burnDamage` = 3.75F
- `bulletDamage` = 3.125F
- `fractureDamage` = 3.125F
- `biteDamage` = 2.1875F
- `bleedDamage` = 0.2857143F

## Utility Methods

- `RestoreToFullHealth()` - Restores body part to full health
- `isBandageDirty()` - Checks if bandage needs changing
- `getBandageNeededDamageLevel()` - Gets damage level needed for bandage
- `getDamageScaler()` - Gets damage scaler for this body part

## Network Sync IDs (from BodyDamageSync.java)

- BD_Health = 1
- BD_bandaged = 2
- BD_bitten = 3
- BD_bleeding = 4
- BD_IsBleedingStemmed = 5
- BD_IsCauterized = 6
- BD_scratched = 7
- BD_stitched = 8
- BD_deepWounded = 9
- BD_IsInfected = 10
- BD_IsFakeInfected = 11
- BD_bandageLife = 12
- BD_scratchTime = 13
- BD_biteTime = 14
- BD_alcoholicBandage = 15
- BD_woundInfectionLevel = 16
- BD_infectedWound = 17
- BD_bleedingTime = 18
- BD_deepWoundTime = 19
- BD_haveGlass = 20
- BD_stitchTime = 21
- BD_alcoholLevel = 22
- BD_additionalPain = 23
- BD_bandageType = 24
- BD_fractureTime = 28
- BD_splint = 29
- BD_splintFactor = 30
- BD_haveBullet = 31
- BD_burnTime = 32
- BD_needBurnWash = 33
- BD_lastTimeBurnWash = 34
- BD_splintItem = 35
- BD_plantainFactor = 36
- BD_comfreyFactor = 37
- BD_garlicFactor = 38
- BD_cut = 39
- BD_cutTime = 40
- BD_stiffness = 41

