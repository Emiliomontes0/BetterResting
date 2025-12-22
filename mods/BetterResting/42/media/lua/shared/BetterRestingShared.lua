-- BetterResting Shared Script
-- Configuration accessible by both client and server

BetterResting = BetterResting or {}
BetterResting.Version = "1.1"
BetterResting.ModID = "BetterResting"

-- Configuration values
BetterResting.Config = {
    -- Chair/Sofa bonuses
    ChairStaminaRegenMultiplier = 1.07,       -- 7% faster stamina regen on chairs
    ChairBuffDuration = 600,                  -- 10 minutes = 600 seconds (game time)
    ChairStaminaConsumptionReduction = 0.75,  -- 25% reduction when buff active
    MinChairRestTime = 0.1,
    MinBuffDuration = 0.1,
    MaxBuffDuration = 1.0,
    
    -- Vehicle bonuses
    VehicleStaminaRegenMultiplier = 1.10,     -- 10% faster stamina regen in vehicle
    VehicleStaminaConsumptionReduction = 0.5, -- 50% reduction while in vehicle
    
    -- Bed bonuses
    BedStaminaRegenMultiplier = 1.2,          -- 20% faster stamina regen in bed
    BedHPRegenMultiplier = 2.0,               -- 2x faster HP regen (gradual healing)
    BedMuscleFatigueReduction = 0.30,         -- 30% faster muscle fatigue recovery (increased from 15%)

}

-- Rest location types
BetterResting.RestType = {
    FLOOR = "floor",
    CHAIR = "chair",
    VEHICLE = "vehicle",
    BED = "bed",
}

-- Lookup tables for CustomItem detection (most reliable method)
-- Extracted from newtiledefinitions.tiles.txt - all objects with BedType parameter
BetterResting.BedCustomItems = {
    -- Tents
    ["Base.CampingTentKit2"] = true,
    ["Base.HideTent"] = true,
    ["Base.ImprovisedTentKit"] = true,
    ["Base.TentBlue"] = true,
    ["Base.TentBrown"] = true,
    ["Base.TentGreen"] = true,
    ["Base.TentYellow"] = true,
    -- Sleeping Bags
    ["Base.SleepingBag_BluePlaid"] = true,
    ["Base.SleepingBag_Camo"] = true,
    ["Base.SleepingBag_Cheap_Blue"] = true,
    ["Base.SleepingBag_Cheap_Green"] = true,
    ["Base.SleepingBag_Cheap_Green2"] = true,
    ["Base.SleepingBag_Green"] = true,
    ["Base.SleepingBag_GreenPlaid"] = true,
    ["Base.SleepingBag_Hide"] = true,
    ["Base.SleepingBag_HighQuality_Brown"] = true,
    ["Base.SleepingBag_RedPlaid"] = true,
    ["Base.SleepingBag_Spiffo"] = true,
    -- Beds and Cots
    ["Base.Mov_Cot"] = true,
    ["Base.Mov_Gurney"] = true,
    ["Mov_Gurney"] = true,  -- Some variants don't have Base. prefix
    -- Other bed-like objects
    ["Base.Mov_GymnMat"] = true,
    -- Coffins (treated as beds for resting)
    ["Base.Mov_FlatCoffin"] = true,
}

-- Sprite Name Lookup Tables
-- Generated from bedtype_tiles.md - 707 sprites total (264 beds, 443 chairs)
-- These provide exact sprite name matching for reliable detection
BetterResting.BedSprites = {
    ["camping_01_0"] = true,  -- Tent (badBed)
    ["camping_01_1"] = true,  -- Tent (badBed)
    ["camping_01_2"] = true,  -- Tent (badBed)
    ["camping_01_3"] = true,  -- Tent (badBed)
    ["camping_02_0"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_1"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_10"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_11"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_12"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_13"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_14"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_15"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_16"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_17"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_18"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_19"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_2"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_20"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_21"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_22"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_23"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_24"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_25"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_26"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_27"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_28"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_29"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_3"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_30"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_31"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_32"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_33"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_34"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_35"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_36"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_37"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_38"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_39"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_4"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_40"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_41"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_42"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_43"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_44"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_45"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_46"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_47"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_48"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_49"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_5"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_50"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_51"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_52"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_53"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_54"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_55"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_56"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_57"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_58"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_59"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_6"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_60"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_61"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_62"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_63"] = true,  -- Cheap Sleeping Bag (badBed)
    ["camping_02_64"] = true,  -- Spiffo Sleeping Bag (badBed)
    ["camping_02_65"] = true,  -- Spiffo Sleeping Bag (badBed)
    ["camping_02_66"] = true,  -- Spiffo Sleeping Bag (badBed)
    ["camping_02_67"] = true,  -- Spiffo Sleeping Bag (badBed)
    ["camping_02_68"] = true,  -- Spiffo Sleeping Bag (badBed)
    ["camping_02_69"] = true,  -- Spiffo Sleeping Bag (badBed)
    ["camping_02_7"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_70"] = true,  -- Spiffo Sleeping Bag (badBed)
    ["camping_02_71"] = true,  -- Spiffo Sleeping Bag (badBed)
    ["camping_02_72"] = true,  -- High Quality Sleeping Bag (badBed)
    ["camping_02_73"] = true,  -- High Quality Sleeping Bag (badBed)
    ["camping_02_74"] = true,  -- High Quality Sleeping Bag (badBed)
    ["camping_02_75"] = true,  -- High Quality Sleeping Bag (badBed)
    ["camping_02_76"] = true,  -- High Quality Sleeping Bag (badBed)
    ["camping_02_77"] = true,  -- High Quality Sleeping Bag (badBed)
    ["camping_02_78"] = true,  -- High Quality Sleeping Bag (badBed)
    ["camping_02_79"] = true,  -- High Quality Sleeping Bag (badBed)
    ["camping_02_8"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_02_80"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_81"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_82"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_83"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_84"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_85"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_86"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_87"] = true,  -- Sleeping Bag (badBed)
    ["camping_02_9"] = true,  -- Plaid Sleeping Bag (badBed)
    ["camping_03_0"] = true,  -- Shelter (badBed)
    ["camping_03_1"] = true,  -- Shelter (badBed)
    ["camping_03_10"] = true,  -- Shelter (badBed)
    ["camping_03_11"] = true,  -- Shelter (badBed)
    ["camping_03_12"] = true,  -- Shelter (badBed)
    ["camping_03_13"] = true,  -- Shelter (badBed)
    ["camping_03_14"] = true,  -- Shelter (badBed)
    ["camping_03_15"] = true,  -- Shelter (badBed)
    ["camping_03_2"] = true,  -- Shelter (badBed)
    ["camping_03_24"] = true,  -- Tent (badBed)
    ["camping_03_25"] = true,  -- Tent (badBed)
    ["camping_03_26"] = true,  -- Tent (badBed)
    ["camping_03_27"] = true,  -- Tent (badBed)
    ["camping_03_3"] = true,  -- Shelter (badBed)
    ["camping_03_32"] = true,  -- Tent (badBed)
    ["camping_03_33"] = true,  -- Tent (badBed)
    ["camping_03_34"] = true,  -- Tent (badBed)
    ["camping_03_35"] = true,  -- Tent (badBed)
    ["camping_03_36"] = true,  -- Tent (badBed)
    ["camping_03_37"] = true,  -- Tent (badBed)
    ["camping_03_38"] = true,  -- Tent (badBed)
    ["camping_03_39"] = true,  -- Tent (badBed)
    ["camping_03_4"] = true,  -- Shelter (badBed)
    ["camping_03_40"] = true,  -- Shelter (badBed)
    ["camping_03_41"] = true,  -- Shelter (badBed)
    ["camping_03_42"] = true,  -- Shelter (badBed)
    ["camping_03_43"] = true,  -- Shelter (badBed)
    ["camping_03_44"] = true,  -- Shelter (badBed)
    ["camping_03_45"] = true,  -- Shelter (badBed)
    ["camping_03_46"] = true,  -- Shelter (badBed)
    ["camping_03_47"] = true,  -- Shelter (badBed)
    ["camping_03_5"] = true,  -- Shelter (badBed)
    ["camping_03_6"] = true,  -- Shelter (badBed)
    ["camping_03_7"] = true,  -- Shelter (badBed)
    ["camping_03_8"] = true,  -- Shelter (badBed)
    ["camping_03_9"] = true,  -- Shelter (badBed)
    ["camping_04_100"] = true,  -- Tent (badBed)
    ["camping_04_111"] = true,  -- Tent (badBed)
    ["camping_04_119"] = true,  -- Tent (badBed)
    ["camping_04_124"] = true,  -- Tent (badBed)
    ["camping_04_15"] = true,  -- Tent (badBed)
    ["camping_04_23"] = true,  -- Tent (badBed)
    ["camping_04_28"] = true,  -- Tent (badBed)
    ["camping_04_36"] = true,  -- Tent (badBed)
    ["camping_04_4"] = true,  -- Tent (badBed)
    ["camping_04_47"] = true,  -- Tent (badBed)
    ["camping_04_55"] = true,  -- Tent (badBed)
    ["camping_04_60"] = true,  -- Tent (badBed)
    ["camping_04_68"] = true,  -- Tent (badBed)
    ["camping_04_79"] = true,  -- Tent (badBed)
    ["camping_04_87"] = true,  -- Tent (badBed)
    ["camping_04_92"] = true,  -- Tent (badBed)
    ["crafted_02_85"] = true,  -- Block (badBed)
    ["crafted_02_86"] = true,  -- Stump (badBed)
    ["crafted_04_44"] = true,  -- Coffin (badBed)
    ["crafted_04_47"] = true,  -- Coffin (badBed)
    ["crafted_04_48"] = true,  -- Coffin (badBed)
    ["crafted_04_51"] = true,  -- Coffin (badBed)
    ["crafted_04_52"] = true,  -- Coffin (badBed)
    ["crafted_04_53"] = true,  -- Coffin (badBed)
    ["crafted_04_54"] = true,  -- Coffin (badBed)
    ["crafted_04_55"] = true,  -- Coffin (badBed)
    ["furniture_bedding_01_0"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_1"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_10"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_11"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_12"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_13"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_14"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_15"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_16"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_17"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_18"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_19"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_2"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_20"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_21"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_22"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_23"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_24"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_25"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_26"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_27"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_28"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_29"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_3"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_30"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_31"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_32"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_33"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_34"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_35"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_36"] = true,  -- Beds (goodBed)
    ["furniture_bedding_01_37"] = true,  -- Beds (goodBed)
    ["furniture_bedding_01_38"] = true,  -- Beds (goodBed)
    ["furniture_bedding_01_39"] = true,  -- Beds (goodBed)
    ["furniture_bedding_01_4"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_40"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_41"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_42"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_43"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_44"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_45"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_46"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_47"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_48"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_49"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_5"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_50"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_51"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_52"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_53"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_54"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_55"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_56"] = true,  -- Bed (averageBed)
    ["furniture_bedding_01_57"] = true,  -- Bed (averageBed)
    ["furniture_bedding_01_58"] = true,  -- Bed (averageBed)
    ["furniture_bedding_01_59"] = true,  -- Bed (averageBed)
    ["furniture_bedding_01_6"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_60"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_61"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_62"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_63"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_64"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_65"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_66"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_67"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_68"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_69"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_7"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_70"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_71"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_72"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_73"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_74"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_75"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_76"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_77"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_78"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_79"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_8"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_80"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_81"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_82"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_83"] = true,  -- Bed (goodBed)
    ["furniture_bedding_01_84"] = true,  -- Beds (goodBed)
    ["furniture_bedding_01_85"] = true,  -- Beds (goodBed)
    ["furniture_bedding_01_86"] = true,  -- Beds (goodBed)
    ["furniture_bedding_01_87"] = true,  -- Beds (goodBed)
    ["furniture_bedding_01_9"] = true,  -- Bed (goodBed)
    ["location_community_medical_01_16"] = true,  -- Bed (goodBed)
    ["location_community_medical_01_17"] = true,  -- Bed (goodBed)
    ["location_community_medical_01_18"] = true,  -- Bed (goodBed)
    ["location_community_medical_01_19"] = true,  -- Bed (goodBed)
    ["location_community_medical_01_20"] = true,  -- Bed (goodBed)
    ["location_community_medical_01_21"] = true,  -- Bed (goodBed)
    ["location_community_medical_01_22"] = true,  -- Bed (goodBed)
    ["location_community_medical_01_23"] = true,  -- Bed (goodBed)
    ["location_community_medical_01_72"] = true,  -- Bed (averageBed)
    ["location_community_medical_01_73"] = true,  -- Bed (averageBed)
    ["location_community_medical_01_74"] = true,  -- Bed (averageBed)
    ["location_community_medical_01_75"] = true,  -- Bed (averageBed)
    ["recreational_sports_01_34"] = true,  -- Mat (badBed)
    ["recreational_sports_01_35"] = true,  -- Mat (badBed)
    ["vegetation_farm_01_10"] = true,  -- Double Stacked Hay (badBed)
    ["vegetation_farm_01_11"] = true,  -- Double Stacked Hay (badBed)
    ["vegetation_farm_01_16"] = true,  -- Single Stacked Hay (badBed)
    ["vegetation_farm_01_17"] = true,  -- Single Stacked Hay (badBed)
    ["vegetation_farm_01_18"] = true,  -- Double Stacked Hay (badBed)
    ["vegetation_farm_01_19"] = true,  -- Double Stacked Hay (badBed)
    ["vegetation_farm_01_8"] = true,  -- Single Stacked Hay (badBed)
    ["vegetation_farm_01_9"] = true,  -- Single Stacked Hay (badBed)
}

BetterResting.ChairSprites = {
    ["camping_01_10"] = true,  -- Table (badBed)
    ["camping_01_11"] = true,  -- Table (badBed)
    ["camping_01_12"] = true,  -- Table (badBed)
    ["camping_01_13"] = true,  -- Table (badBed)
    ["camping_01_14"] = true,  -- Table (badBed)
    ["camping_01_15"] = true,  -- Table (badBed)
    ["camping_01_8"] = true,  -- Table (badBed)
    ["camping_01_9"] = true,  -- Table (badBed)
    ["carpentry_01_36"] = true,  -- Chair (badBed)
    ["carpentry_01_37"] = true,  -- Chair (badBed)
    ["carpentry_01_38"] = true,  -- Chair (badBed)
    ["carpentry_01_39"] = true,  -- Chair (badBed)
    ["carpentry_01_40"] = true,  -- Chair (badBed)
    ["carpentry_01_41"] = true,  -- Chair (badBed)
    ["carpentry_01_42"] = true,  -- Chair (badBed)
    ["carpentry_01_43"] = true,  -- Chair (badBed)
    ["carpentry_01_44"] = true,  -- Chair (badBed)
    ["carpentry_01_45"] = true,  -- Chair (badBed)
    ["carpentry_01_46"] = true,  -- Chair (badBed)
    ["carpentry_01_47"] = true,  -- Chair (badBed)
    ["crafted_02_56"] = true,  -- Bench (badBed)
    ["crafted_02_57"] = true,  -- Bench (badBed)
    ["crafted_02_58"] = true,  -- Bench (badBed)
    ["crafted_02_59"] = true,  -- Bench (badBed)
    ["crafted_02_92"] = true,  -- Stool (badBed)
    ["crafted_02_93"] = true,  -- Stool (badBed)
    ["crafted_02_94"] = true,  -- Stool (badBed)
    ["crafted_02_95"] = true,  -- Stool (badBed)
    ["crafted_04_112"] = true,  -- Stool (badBed)
    ["crafted_04_113"] = true,  -- Stool (badBed)
    ["furniture_seating_indoor_01_0"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_1"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_10"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_11"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_12"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_13"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_14"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_15"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_16"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_17"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_18"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_19"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_2"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_20"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_21"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_22"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_23"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_24"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_25"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_26"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_27"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_28"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_29"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_3"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_30"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_31"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_32"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_33"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_34"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_35"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_36"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_37"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_38"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_39"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_4"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_40"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_41"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_42"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_43"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_44"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_45"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_46"] = true,  -- Ottoman (badBed)
    ["furniture_seating_indoor_01_47"] = true,  -- Ottoman (badBed)
    ["furniture_seating_indoor_01_48"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_49"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_5"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_50"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_51"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_52"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_53"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_54"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_55"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_56"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_57"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_58"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_59"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_6"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_60"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_61"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_62"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_63"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_01_7"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_01_8"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_01_9"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_0"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_1"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_10"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_11"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_12"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_13"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_14"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_15"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_16"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_02_17"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_02_18"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_02_19"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_02_2"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_20"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_21"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_22"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_23"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_24"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_25"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_26"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_27"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_28"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_29"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_3"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_30"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_31"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_32"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_33"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_34"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_35"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_36"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_37"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_38"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_39"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_4"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_40"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_41"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_42"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_43"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_44"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_45"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_46"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_47"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_02_48"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_49"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_5"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_50"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_51"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_52"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_53"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_54"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_55"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_02_56"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_57"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_58"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_59"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_6"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_60"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_02_61"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_02_62"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_02_63"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_02_7"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_8"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_02_9"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_0"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_03_1"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_03_10"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_100"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_101"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_102"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_103"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_104"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_105"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_106"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_107"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_108"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_109"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_11"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_110"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_111"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_112"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_113"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_114"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_115"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_116"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_117"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_118"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_119"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_12"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_120"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_121"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_122"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_123"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_124"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_125"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_126"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_127"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_128"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_129"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_13"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_130"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_131"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_132"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_133"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_134"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_135"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_136"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_137"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_138"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_139"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_14"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_140"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_141"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_142"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_143"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_144"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_145"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_146"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_147"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_148"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_149"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_15"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_150"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_151"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_16"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_17"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_18"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_19"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_2"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_03_20"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_21"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_22"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_23"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_24"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_25"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_26"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_27"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_28"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_29"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_3"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_03_30"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_31"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_32"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_33"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_34"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_35"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_36"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_37"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_38"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_39"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_4"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_40"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_41"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_42"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_43"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_44"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_45"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_46"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_47"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_48"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_49"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_5"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_50"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_51"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_52"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_03_53"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_03_54"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_03_55"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_03_56"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_57"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_58"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_59"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_6"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_60"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_61"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_64"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_03_65"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_03_66"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_03_67"] = true,  -- Bench (badBed)
    ["furniture_seating_indoor_03_68"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_69"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_7"] = true,  -- Chair (averageBed)
    ["furniture_seating_indoor_03_70"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_71"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_72"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_73"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_74"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_75"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_76"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_77"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_78"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_79"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_8"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_80"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_81"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_82"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_83"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_84"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_85"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_86"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_87"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_88"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_89"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_9"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_90"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_91"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_92"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_93"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_94"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_95"] = true,  -- Couch (averageBed)
    ["furniture_seating_indoor_03_96"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_97"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_98"] = true,  -- Chair (badBed)
    ["furniture_seating_indoor_03_99"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_0"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_1"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_10"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_11"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_12"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_13"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_14"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_15"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_16"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_17"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_18"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_19"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_2"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_20"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_21"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_22"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_23"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_24"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_25"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_26"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_27"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_28"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_29"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_3"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_30"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_31"] = true,  -- Chair (badBed)
    ["furniture_seating_outdoor_01_4"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_5"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_6"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_7"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_8"] = true,  -- Bench (badBed)
    ["furniture_seating_outdoor_01_9"] = true,  -- Bench (badBed)
    ["location_community_church_small_01_48"] = true,  -- Pew (badBed)
    ["location_community_church_small_01_49"] = true,  -- Pew (badBed)
    ["location_community_church_small_01_50"] = true,  -- Pew (badBed)
    ["location_community_church_small_01_51"] = true,  -- Pew (badBed)
    ["location_community_church_small_01_52"] = true,  -- Pew (badBed)
    ["location_community_church_small_01_53"] = true,  -- Pew (badBed)
    ["location_community_church_small_01_56"] = true,  -- Pew (badBed)
    ["location_community_church_small_01_57"] = true,  -- Pew (badBed)
    ["location_community_church_small_01_58"] = true,  -- Pew (badBed)
    ["location_community_church_small_01_59"] = true,  -- Pew (badBed)
    ["location_community_church_small_01_60"] = true,  -- Pew (badBed)
    ["location_community_church_small_01_61"] = true,  -- Pew (badBed)
    ["location_community_medical_01_32"] = true,  -- Chair (averageBed)
    ["location_community_medical_01_33"] = true,  -- Chair (averageBed)
    ["location_community_medical_01_34"] = true,  -- Chair (averageBed)
    ["location_community_medical_01_35"] = true,  -- Chair (averageBed)
    ["location_community_medical_01_56"] = true,  -- Chairs (badBed)
    ["location_community_medical_01_57"] = true,  -- Chairs (badBed)
    ["location_community_medical_01_58"] = true,  -- Chairs (badBed)
    ["location_community_medical_01_59"] = true,  -- Chairs (badBed)
    ["location_community_medical_01_60"] = true,  -- Chairs (badBed)
    ["location_community_medical_01_61"] = true,  -- Chairs (badBed)
    ["location_community_medical_01_62"] = true,  -- Chairs (badBed)
    ["location_community_medical_01_63"] = true,  -- Chairs (badBed)
    ["location_community_medical_01_76"] = true,  -- Table (badBed)
    ["location_community_medical_01_77"] = true,  -- Table (badBed)
    ["location_community_medical_01_78"] = true,  -- Table (badBed)
    ["location_community_medical_01_79"] = true,  -- Table (badBed)
    ["location_entertainment_theatre_01_0"] = true,  -- Chair (badBed)
    ["location_entertainment_theatre_01_1"] = true,  -- Chair (badBed)
    ["location_entertainment_theatre_01_2"] = true,  -- Chair (badBed)
    ["location_entertainment_theatre_01_3"] = true,  -- Chair (badBed)
    ["location_entertainment_theatre_01_88"] = true,  -- Chair (badBed)
    ["location_entertainment_theatre_01_89"] = true,  -- Chair (badBed)
    ["location_entertainment_theatre_01_90"] = true,  -- Chair (badBed)
    ["location_entertainment_theatre_01_91"] = true,  -- Chair (badBed)
    ["location_restaurant_bar_01_10"] = true,  -- Seating (averageBed)
    ["location_restaurant_bar_01_11"] = true,  -- Seating (averageBed)
    ["location_restaurant_bar_01_12"] = true,  -- Seating (averageBed)
    ["location_restaurant_bar_01_13"] = true,  -- Seating (averageBed)
    ["location_restaurant_bar_01_14"] = true,  -- Seating (averageBed)
    ["location_restaurant_bar_01_15"] = true,  -- Seating (averageBed)
    ["location_restaurant_bar_01_25"] = true,  -- Blue Bar Stool (badBed)
    ["location_restaurant_bar_01_26"] = true,  -- Bar Stool (badBed)
    ["location_restaurant_bar_01_8"] = true,  -- Seating (averageBed)
    ["location_restaurant_bar_01_9"] = true,  -- Seating (averageBed)
    ["location_restaurant_diner_01_32"] = true,  -- Seat (averageBed)
    ["location_restaurant_diner_01_33"] = true,  -- Seat (averageBed)
    ["location_restaurant_diner_01_34"] = true,  -- Seat (averageBed)
    ["location_restaurant_diner_01_35"] = true,  -- Seat (averageBed)
    ["location_restaurant_diner_01_36"] = true,  -- Seat (averageBed)
    ["location_restaurant_diner_01_37"] = true,  -- Seat (averageBed)
    ["location_restaurant_diner_01_38"] = true,  -- Seat (averageBed)
    ["location_restaurant_diner_01_39"] = true,  -- Seat (averageBed)
    ["location_restaurant_diner_01_42"] = true,  -- 50s Barstool (badBed)
    ["location_restaurant_generic_01_0"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_1"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_10"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_11"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_12"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_13"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_14"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_15"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_2"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_3"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_4"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_5"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_6"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_7"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_8"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_generic_01_9"] = true,  -- Picknic Table (badBed)
    ["location_restaurant_pizzawhirled_01_40"] = true,  -- Seat (averageBed)
    ["location_restaurant_pizzawhirled_01_41"] = true,  -- Seat (averageBed)
    ["location_restaurant_pizzawhirled_01_42"] = true,  -- Seat (averageBed)
    ["location_restaurant_pizzawhirled_01_43"] = true,  -- Seat (averageBed)
    ["location_restaurant_pizzawhirled_01_44"] = true,  -- Seat (averageBed)
    ["location_restaurant_pizzawhirled_01_45"] = true,  -- Seat (averageBed)
    ["location_restaurant_pizzawhirled_01_46"] = true,  -- Seat (averageBed)
    ["location_restaurant_pizzawhirled_01_47"] = true,  -- Seat (averageBed)
    ["location_restaurant_spiffos_02_16"] = true,  -- Seat (badBed)
    ["location_restaurant_spiffos_02_17"] = true,  -- Seat (badBed)
    ["location_restaurant_spiffos_02_18"] = true,  -- Seat (badBed)
    ["location_restaurant_spiffos_02_19"] = true,  -- Seat (badBed)
    ["location_restaurant_spiffos_02_20"] = true,  -- Seat (badBed)
    ["location_restaurant_spiffos_02_21"] = true,  -- Seat (badBed)
    ["location_restaurant_spiffos_02_22"] = true,  -- Seat (badBed)
    ["location_restaurant_spiffos_02_23"] = true,  -- Seat (badBed)
    ["location_restaurant_spiffos_02_24"] = true,  -- Chair (badBed)
    ["location_restaurant_spiffos_02_25"] = true,  -- Chair (badBed)
    ["location_restaurant_spiffos_02_26"] = true,  -- Chair (badBed)
    ["location_restaurant_spiffos_02_27"] = true,  -- Chair (badBed)
    ["location_services_beauty_01_0"] = true,  -- Chair (badBed)
    ["location_services_beauty_01_1"] = true,  -- Chair (badBed)
    ["location_services_beauty_01_2"] = true,  -- Chair (badBed)
    ["location_services_beauty_01_3"] = true,  -- Chair (badBed)
    ["location_shop_mall_01_40"] = true,  -- Chair (badBed)
    ["location_shop_mall_01_41"] = true,  -- Chair (badBed)
    ["location_shop_mall_01_42"] = true,  -- Chair (badBed)
    ["location_shop_mall_01_43"] = true,  -- Chair (badBed)
    ["recreational_01_10"] = true,  -- Stool (badBed)
    ["recreational_01_11"] = true,  -- Stool (badBed)
    ["recreational_01_14"] = true,  -- Stool (badBed)
    ["recreational_01_15"] = true,  -- Stool (badBed)
}


local gameTime
Events.OnGameTimeLoaded.Add(function()
    gameTime = GameTime.getInstance()
end)

-- Get current game time in hours
function BetterResting.getCurrentGameHours()
    if not gameTime then --checker incase api changes
        print("BetterResting [SHARED] ERROR: getGameTime() returned nil!")
        return 0 
    end
    return gameTime:getMultiplier()
end


-- Check if player is actually resting (not just standing on furniture)
-- Uses game's built-in resting detection methods from ISRestAction.lua
function BetterResting.isPlayerResting(player)
    if not player then return false end
    -- Use game's built-in resting detection methods (from ISRestAction.lua)
    -- These methods are set by the game's ISRestAction and other rest actions
    
    -- Check if player has isResting() method (set by ISRestAction:setIsResting())
    if player.isResting then
        local isResting = player:isResting()
        if isResting then
            return true
        end
    end
    
    -- Check if sitting on furniture (chairs, sofas, etc.)
    if player.isSittingOnFurniture then
        local isSittingOnFurniture = player:isSittingOnFurniture()
        if isSittingOnFurniture then
            return true
        end
    end
    
    -- Check if sitting on ground
    if player.isSitOnGround then
        local isSitOnGround = player:isSitOnGround()
        if isSitOnGround then
            return true
        end
    end
    
    -- Check if on bed
    if player.isOnBed then
        local isOnBed = player:isOnBed()
        if isOnBed then
    return true
        end
    end
    
    return false
end

-- Detect what type of rest location the player is at
function BetterResting.detectRestType(player)
    if not player then return BetterResting.RestType.FLOOR end
    
    -- First check: If player is moving, they're not resting - default to floor
    -- This fixes the bug where sleeping bag state persists after getting up
    if player.currentSpeed and player.currentSpeed > 0.0 then
        print("[BetterResting] detectRestType: Player is moving, returning FLOOR")
        return BetterResting.RestType.FLOOR
    end
    
    -- Also check if player is actually resting using game API
    local isActuallyResting = false
    if player.isResting then
        isActuallyResting = player:isResting()
    end
    if not isActuallyResting and player.isSittingOnFurniture then
        isActuallyResting = player:isSittingOnFurniture()
    end
    if not isActuallyResting and player.isSitOnGround then
        isActuallyResting = player:isSitOnGround()
    end
    if not isActuallyResting and player.getBed then
        isActuallyResting = (player:getBed() ~= nil)
    end
    
    if not isActuallyResting then
        print("[BetterResting] detectRestType: Player is not actually resting, returning FLOOR")
        return BetterResting.RestType.FLOOR
    end
    
    -- Priority 1: Check if in vehicle (using game API)
    local vehicle = player:getVehicle()
    if vehicle then
        print("[BetterResting] detectRestType: VEHICLE detected")
        return BetterResting.RestType.VEHICLE
    end
    
    -- Priority 2: Check if on bed (using game API from ISRestAction.lua)
    local isOnBed = false
    if player.isOnBed then
        isOnBed = player:isOnBed()
        print("[BetterResting] detectRestType: isOnBed() = " .. tostring(isOnBed))
    else
        print("[BetterResting] detectRestType: isOnBed method not available")
    end
    
    if isOnBed then
        print("[BetterResting] detectRestType: BED detected (via isOnBed)")
        return BetterResting.RestType.BED
    end
    
    -- Check bed object directly (for sleeping bags and other bed types)
    -- IMPORTANT: Validate that getBed() returns an actual bed, not seating furniture
    local bed = nil
    if player.getBed then
        bed = player:getBed()
        print("[BetterResting] detectRestType: getBed() = " .. tostring(bed))
        
        -- Validate that the bed object is actually a bed, not seating furniture
        if bed then
            local isActuallyBed = false
            
            -- Check sprite name to confirm it's a bed
            if bed.getSprite then
                local sprite = bed:getSprite()
                if sprite then
                    local spriteName = sprite:getName()
                    if spriteName then
                        local spriteNameLower = tostring(spriteName):lower()
                        print("[BetterResting] detectRestType: bed object sprite: " .. spriteNameLower)
                        
                        -- Check if it's seating furniture (should NOT be treated as bed)
                        if spriteNameLower:find("seating") or 
                           spriteNameLower:find("chair") or 
                           spriteNameLower:find("sofa") or 
                           spriteNameLower:find("couch") or
                           spriteNameLower:find("stool") or
                           spriteNameLower:find("bench") or
                           spriteNameLower:find("seat") then
                            print("[BetterResting] detectRestType: getBed() returned seating furniture, ignoring")
                            bed = nil  -- Don't treat as bed
                        -- Check if it's actually a bed
                        elseif spriteNameLower:find("bed") or 
                               spriteNameLower:find("bedding") or 
                               spriteNameLower:find("sleeping") or
                               spriteNameLower:find("tent") or
                               spriteNameLower:find("cot") or
                               spriteNameLower:find("gurney") or
                               spriteNameLower:find("camping_") then  -- Check for any camping sprite (tents, sleeping bags, etc.)
                            isActuallyBed = true
                            print("[BetterResting] detectRestType: bed object sprite confirms it's a bed")
                        end
                    end
                end
            end
            
            -- If sprite check didn't confirm it's a bed, check CustomItem
            -- Only check if bed is still valid (not set to nil)
            if bed and not isActuallyBed and bed.getCustomItem then
                local customItem = bed:getCustomItem()
                print("[BetterResting] detectRestType: Checking CustomItem: " .. tostring(customItem))
                if customItem then
                    local customItemStr = nil
                    if type(customItem) == "string" then
                        customItemStr = customItem
                    elseif customItem.getType then
                        customItemStr = customItem:getType()
                    elseif customItem.getFullType then
                        customItemStr = customItem:getFullType()
                    end
                    
                    print("[BetterResting] detectRestType: CustomItem string: " .. tostring(customItemStr))
                    if customItemStr and BetterResting.BedCustomItems[customItemStr] then
                        isActuallyBed = true
                        print("[BetterResting] detectRestType: bed object CustomItem confirms it's a bed: " .. tostring(customItemStr))
                    else
                        print("[BetterResting] detectRestType: CustomItem not in BedCustomItems list")
                    end
                end
            end
            
            -- If we couldn't confirm it's a bed, don't treat it as one
            -- Only set to nil if bed is still valid (not already nil)
            if bed and not isActuallyBed then
                print("[BetterResting] detectRestType: getBed() returned object that is not confirmed as bed, ignoring")
                bed = nil
                    end
                end
            end
            
    if bed then
        print("[BetterResting] detectRestType: BED detected (via getBed)")
        return BetterResting.RestType.BED
    end
    
    -- Priority 3: Check if sitting on furniture (chairs/sofas using game API from ISRestAction.lua)
    local isSittingOnFurniture = false
    if player.isSittingOnFurniture then
        isSittingOnFurniture = player:isSittingOnFurniture()
        print("[BetterResting] detectRestType: isSittingOnFurniture() = " .. tostring(isSittingOnFurniture))
    else
        print("[BetterResting] detectRestType: isSittingOnFurniture method not available")
    end
    
    if isSittingOnFurniture then
        -- Check if the furniture object is actually a bed or a chair/sofa
        local furnitureObj = nil
        if player.getSitOnFurnitureObject then
            furnitureObj = player:getSitOnFurnitureObject()
            print("[BetterResting] detectRestType: getSitOnFurnitureObject() = " .. tostring(furnitureObj))
            
            if furnitureObj then
                local isSeatingFurniture = false
                local isBedObject = false
                
                -- PRIORITY 1: Check sprite name FIRST to identify seating furniture (chairs/sofas/couches)
                -- This prevents couches from being detected as beds even if they have bed properties
                if furnitureObj.getSprite then
                    local sprite = furnitureObj:getSprite()
                    if sprite then
                        local spriteName = sprite:getName()
                        if spriteName then
                            local spriteNameLower = tostring(spriteName):lower()
                            print("[BetterResting] detectRestType: furniture sprite name: " .. spriteNameLower)
                            
                            -- Check for seating furniture keywords (chairs, sofas, couches, etc.)
                            if spriteNameLower:find("seating") or 
                               spriteNameLower:find("chair") or 
                               spriteNameLower:find("sofa") or 
                               spriteNameLower:find("couch") or
                               spriteNameLower:find("stool") or
                               spriteNameLower:find("bench") or
                               spriteNameLower:find("seat") then
                                isSeatingFurniture = true
                                print("[BetterResting] detectRestType: furniture is seating furniture (chair/sofa/couch)")
                            -- Check for bed keywords
                            elseif spriteNameLower:find("bed") or 
                                   spriteNameLower:find("bedding") or 
                                   spriteNameLower:find("sleeping") then
                                isBedObject = true
                                print("[BetterResting] detectRestType: furniture sprite indicates bed: " .. spriteNameLower)
                end
            end
                    end
                end
                
                -- PRIORITY 2: If not identified by sprite, check CustomItem
                if not isSeatingFurniture and not isBedObject and furnitureObj.getCustomItem then
                    local customItem = furnitureObj:getCustomItem()
                    if customItem then
                        local customItemStr = nil
                        if type(customItem) == "string" then
                            customItemStr = customItem
                        elseif customItem.getType then
                            customItemStr = customItem:getType()
                        elseif customItem.getFullType then
                            customItemStr = customItem:getFullType()
                        end
                        
                        if customItemStr then
                            if BetterResting.BedCustomItems[customItemStr] then
                                isBedObject = true
                                print("[BetterResting] detectRestType: furniture CustomItem is bed: " .. tostring(customItemStr))
                        end
                    end
                end
            end
            
                -- PRIORITY 3: Only check bed properties if sprite didn't indicate seating furniture
                -- This prevents couches (which have bed properties) from being detected as beds
                if not isSeatingFurniture and not isBedObject then
                    if furnitureObj.getProperties then
                        local props = furnitureObj:getProperties()
                        if props then
                            if props:get("bed") or props:get("BedType") then
                                isBedObject = true
                                print("[BetterResting] detectRestType: furniture has bed property")
                            end
                        end
                    end
                    if furnitureObj.bed or furnitureObj.BedType then
                        isBedObject = true
                        print("[BetterResting] detectRestType: furniture has bed property (direct)")
                end
            end
            
                if isBedObject then
                    print("[BetterResting] detectRestType: BED detected (furniture is bed)")
                    return BetterResting.RestType.BED
                end
            end
        end
        
        print("[BetterResting] detectRestType: CHAIR detected (via isSittingOnFurniture)")
        return BetterResting.RestType.CHAIR
    end
    
    -- Priority 4: Final fallback - Check sprite name lookup tables
    -- This is the last resort method using the comprehensive sprite lookup tables
    local square = player:getCurrentSquare()
    if square then
        local objects = square:getObjects()
        if objects then
            for i = 0, objects:size() - 1 do
                local obj = objects:get(i)
                if obj and obj.getSprite then
                    local sprite = obj:getSprite()
                    if sprite then
                        local spriteName = sprite:getName()
                        if spriteName then
                            local spriteNameStr = tostring(spriteName)
                            print("[BetterResting] detectRestType: Checking sprite in lookup tables: " .. spriteNameStr)
                            
                            -- Check bed sprites first
                            if BetterResting.BedSprites[spriteNameStr] then
                                print("[BetterResting] detectRestType: BED detected (via BedSprites lookup table)")
                                return BetterResting.RestType.BED
                            end
                            
                            -- Check chair sprites
                            if BetterResting.ChairSprites[spriteNameStr] then
                                print("[BetterResting] detectRestType: CHAIR detected (via ChairSprites lookup table)")
                                return BetterResting.RestType.CHAIR
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Fallback: Default to floor if none of the above conditions are met
    print("[BetterResting] detectRestType: FLOOR (fallback)")
    return BetterResting.RestType.FLOOR
end



-- Check if we're on the server side (works in both single-player and multiplayer)
local function isServerSide()
    local result = false
    if isServer and type(isServer) == "function" then
        result = isServer()
        print(string.format("[BetterResting SHARED] isServer() check: %s", tostring(result)))
    elseif isClient and type(isClient) == "function" then
        result = not isClient()
        print(string.format("[BetterResting SHARED] isClient() check: %s, so server side: %s", tostring(isClient()), tostring(result)))
    else
        -- Default: assume server (for single-player compatibility)
        result = true
        print("[BetterResting SHARED] No isServer/isClient functions, assuming server side")
    end
    return result
end

-- Track player states (game mechanics) - server authoritative
local playerRestData = {}

-- Initialize player data tracking
local function initPlayerData(player)
    local playerNum = player:getPlayerNum()
    if not playerRestData[playerNum] then
        playerRestData[playerNum] = {
            currentRestType = nil,
            chairBuffActive = false,
            chairBuffEndTime = 0,
            lastStaminaLevel = 1.0,
            wasFullStamina = false,
            chairRestStartTime = 0,
            lastRestType = nil,
        }
    end
    return playerRestData[playerNum]
end

-- Track last heal time for each body part (for gradual healing)
local bodyPartHealCooldowns = {}

-- Track previous values to detect unexpected changes
local previousValues = {}

-- Apply chair buff when stamina is full
local function applyChairBuff(player, data)
    local stats = player:getStats()
    if not stats then return end
    
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
    if stamina >= 0.99 and not data.wasFullStamina then
        local currentGameHours = BetterResting.getCurrentGameHours()
        local restDurationHours = currentGameHours - data.chairRestStartTime

        if restDurationHours >= BetterResting.Config.MinChairRestTime then
            local BuffDurationHours = math.min(
                BetterResting.Config.MaxBuffDuration,
                math.max(
                    BetterResting.Config.MinBuffDuration,
                    restDurationHours
                )
            )

            data.chairBuffActive = true
            data.chairBuffEndTime = currentGameHours + BuffDurationHours
            
            if not BetterResting.ClientBuffData then
                BetterResting.ClientBuffData = {}
            end
            BetterResting.ClientBuffData.chairBuffEndTime = data.chairBuffEndTime
            BetterResting.ClientBuffData.chairBuffActive = true

            data.chairRestStartTime = 0
        end
        data.wasFullStamina = true
    end
    if stamina < 0.99 then 
        data.wasFullStamina = false
    end 
end

-- Process chair/sofa resting bonuses
local function processChairResting(player, data, updateCounter)
    local stats = player:getStats()
    if not stats then return end
    
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
    if stamina < 1.0 then
        local baseRegen = 0.001
        local bonusRegen = baseRegen * (BetterResting.Config.ChairStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        stats:set(CharacterStat.ENDURANCE, newStamina)
    end
    
    applyChairBuff(player, data)
end

-- Process vehicle resting bonuses
local function processVehicleResting(player, data, updateCounter)
    local stats = player:getStats()
    if not stats then return end
    
    local stamina = stats:get(CharacterStat.ENDURANCE)
    if not stamina then return end
    
    if stamina < 1.0 then
        local baseRegen = 0.001
        local bonusRegen = baseRegen * (BetterResting.Config.VehicleStaminaRegenMultiplier - 1.0)
        local newStamina = math.min(1.0, stamina + bonusRegen)
        stats:set(CharacterStat.ENDURANCE, newStamina)
    end
end

-- Process bed resting bonuses
local function processBedResting(player, data, updateCounter)
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end
    
    local stats = player:getStats()
    if stats then
        local stamina = stats:get(CharacterStat.ENDURANCE)
        if stamina and stamina < 1.0 then
            local baseRegen = 0.001
            local bonusRegen = baseRegen * (BetterResting.Config.BedStaminaRegenMultiplier - 1.0)
            local newStamina = math.min(1.0, stamina + bonusRegen)
            stats:set(CharacterStat.ENDURANCE, newStamina)
        end
    end
    
    local health = bodyDamage:getHealth() / 100.0
    if health and health < 1.0 then
        local bodyParts = bodyDamage:getBodyParts()
        if bodyParts then
            local woundHealCooldown = 6
            local playerKey = tostring(player:getPlayerNum())
            
            for i = 1, bodyParts:size() do
                local part = bodyParts:get(i - 1)
                if part then
                    local partHealth = part:getHealth()
                    if partHealth and partHealth < 100.0 then
                        local partKey = playerKey .. "_" .. tostring(i)
                        local lastWoundHeal = bodyPartHealCooldowns[partKey .. "_wound"] or 0
                        local partHealed = false
                        
                        if updateCounter - lastWoundHeal >= woundHealCooldown then
                            -- Reduce scratch time
                            if part.getScratchTime and part.setScratchTime and part.setScratched then
                                local scratchTime = part:getScratchTime()
                                if scratchTime and scratchTime > 0 then
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
                                    local newTime = math.max(0, scratchTime - reduction)
                                    if newTime <= 0 then
                                        part:setScratched(false, true)
                                    else
                                        part:setScratchTime(newTime)
                                    end
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce cut time
                            if part.getCutTime and part.setCutTime and part.setCut then
                                local cutTime = part:getCutTime()
                                if cutTime and cutTime > 0 then
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
                                    local newTime = math.max(0, cutTime - reduction)
                                    if newTime <= 0 then
                                        part:setCut(false)
                                    else
                                        part:setCutTime(newTime)
                                    end
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce deep wound time
                            if part.getDeepWoundTime and part.setDeepWoundTime and part.setDeepWounded then
                                local deepWoundTime = part:getDeepWoundTime()
                                if deepWoundTime and deepWoundTime > 0 then
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
                                    local newTime = math.max(0, deepWoundTime - reduction)
                                    part:setDeepWoundTime(newTime)
                                    if newTime <= 0 then
                                        part:setDeepWounded(false)
                                    end
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce bleeding time
                            if part.getBleedingTime and part.setBleedingTime then
                                local bleedingTime = part:getBleedingTime()
                                if bleedingTime and bleedingTime > 0 then
                                    local reduction = 0.001 * BetterResting.Config.BedHPRegenMultiplier
                                    local newTime = math.max(0, bleedingTime - reduction)
                                    part:setBleedingTime(newTime)
                                    partHealed = true
                                end
                            end
                            
                            -- Reduce muscle strain (stiffness)
                            if part.getStiffness and part.setStiffness then
                                local stiffness = part:getStiffness()
                                if stiffness and stiffness > 0 then
                                    local oldStiffness = stiffness
                                    local partKeyStiff = playerKey .. "_part" .. i .. "_stiffness"
                                    local previousStiffness = previousValues[partKeyStiff]
                                    
                                    if previousStiffness and math.abs(stiffness - previousStiffness) > 0.5 then
                                        print(string.format("[BetterResting SHARED] WARNING: Stiffness changed unexpectedly! Expected ~%.2f but got %.2f", 
                                            previousStiffness, stiffness))
                                    end
                                    
                                    local reduction = 0.005 * BetterResting.Config.BedMuscleFatigueReduction * 100
                                    local newStiffness = math.max(0, stiffness - reduction)
                                    
                                    if updateCounter % 60 == 0 then
                                        print(string.format("[BetterResting SHARED] Part %d: Stiffness %.2f -> %.2f (tick %d)", 
                                            i, oldStiffness, newStiffness, updateCounter))
                                    end
                                    
                                    part:setStiffness(newStiffness)
                                    
                                    -- Immediately verify and log
                                    local verifyStiffness = part:getStiffness()
                                    if math.abs(verifyStiffness - newStiffness) > 0.01 then
                                        print(string.format("[BetterResting SHARED] WARNING: Stiffness mismatch! Set %.2f but got %.2f (diff: %.2f)", 
                                            newStiffness, verifyStiffness, verifyStiffness - newStiffness))
                                        -- Try setting again
                                        part:setStiffness(newStiffness)
                                        local verify2 = part:getStiffness()
                                        if math.abs(verify2 - newStiffness) > 0.01 then
                                            print(string.format("[BetterResting SHARED] CRITICAL: Stiffness still wrong after retry! Something is resetting it!"))
                                        end
                                    end
                                    
                                    previousValues[partKeyStiff] = newStiffness
                                    
                                    if newStiffness <= 0 and player.getFitness then
                                        local fitness = player:getFitness()
                                        if fitness and fitness.removeStiffnessValue then
                                            fitness:removeStiffnessValue(BodyPartType.ToString(part:getType()))
                                        end
                                    end
                                    
                                    partHealed = true
                                end
                            end
                            
                            if partHealed then
                                bodyPartHealCooldowns[partKey .. "_wound"] = updateCounter
                            end
                        end
                        
                        if part.RestoreToFullHealth and partHealth < 70.0 then
                            local lastHeal = bodyPartHealCooldowns[partKey] or 0
                            local healCooldown = math.max(1, math.floor(600 / BetterResting.Config.BedHPRegenMultiplier))
                            
                            if updateCounter - lastHeal >= healCooldown then
                                part:RestoreToFullHealth()
                                bodyPartHealCooldowns[partKey] = updateCounter
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Reduce muscle fatigue faster
    local parts = bodyDamage:getBodyParts()
    if parts then
        for i = 0, parts:size() - 1 do
            local part = parts:get(i)
            if part then
                if part.getPain and part.setPain then
                    local pain = part:getPain()
                    if pain and pain > 0 then
                        local reduction = pain * BetterResting.Config.BedMuscleFatigueReduction * 0.01
                        local newPain = math.max(0, pain - reduction)
                        part:setPain(newPain)
                    end
                end
            end
        end
    end
end

-- Main server update loop - handles game mechanics (runs in shared script with server check)
local updateCounter = 0
local hasLoggedStart = false

Events.OnPlayerUpdate.Add(function(player)
    if not player then return end
    
    -- Check if we're on server side
    local onServer = isServerSide()
    
    -- Log first time to confirm detection
    if not hasLoggedStart then
        print(string.format("[BetterResting SHARED] OnPlayerUpdate handler - isServerSide: %s", tostring(onServer)))
        hasLoggedStart = true
    end
    
    -- Only run game mechanics on server side
    if not onServer then
        if updateCounter == 0 then
            print("[BetterResting SHARED] WARNING: OnPlayerUpdate running on CLIENT side - game mechanics disabled!")
        end
        return
    end
    
    -- Log first time to confirm it's running on server
    if updateCounter == 0 then
        print("[BetterResting SHARED] OnPlayerUpdate handler is ACTIVE on server side!")
    end
    
    updateCounter = updateCounter + 1
    
    local data = initPlayerData(player)
    local restType = BetterResting.detectRestType(player)

    if data.lastRestType ~= restType then
        if restType == BetterResting.RestType.CHAIR then 
            data.chairRestStartTime = BetterResting.getCurrentGameHours()
        elseif data.lastRestType == BetterResting.RestType.CHAIR then 
            data.chairRestStartTime = 0
            data.wasFullStamina = false
        end
    end
    
    data.lastRestType = restType
    data.currentRestType = restType
    
    if restType == BetterResting.RestType.CHAIR then
        processChairResting(player, data, updateCounter)
    elseif restType == BetterResting.RestType.VEHICLE then
        processVehicleResting(player, data, updateCounter)
    elseif restType == BetterResting.RestType.BED then
        if updateCounter % 60 == 0 then
            print(string.format("[BetterResting SHARED] Processing BED resting (tick %d)", updateCounter))
        end
        processBedResting(player, data, updateCounter)
    end
    
    if data.chairBuffActive then
        local currentHours = BetterResting.getCurrentGameHours()
        if currentHours >= data.chairBuffEndTime then
            data.chairBuffActive = false
            if BetterResting.ClientBuffData then
                BetterResting.ClientBuffData.chairBuffActive = false
                BetterResting.ClientBuffData.chairBuffEndTime = 0
            end
        end
    end
end)

-- Use both print and writeLog to ensure we see output
print("=========================================")
print("BetterResting shared script loaded - Version " .. BetterResting.Version)
print("BetterResting - GAME MECHANICS ENABLED IN SHARED SCRIPT")
print("=========================================")
if writeLog then
    writeLog("BetterResting", "Shared script loaded - Version " .. BetterResting.Version)
end

-- Also verify on game start
Events.OnGameStart.Add(function()
    print("BetterResting [EVENT] OnGameStart fired - Shared script confirmed loaded!")
    print("BetterResting [SHARED] isServer check: " .. tostring(isServer and isServer() or "function not available"))
    print("BetterResting [SHARED] isClient check: " .. tostring(isClient and isClient() or "function not available"))
    print("BetterResting [SHARED] isServerSide() = " .. tostring(isServerSide()))
end)