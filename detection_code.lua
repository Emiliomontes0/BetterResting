-- Detect what type of rest location the player is at
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
                           spriteName:find("bed") or
                           spriteName:find("beds") or
                           spriteName:find("block") or
                           spriteName:find("chair") or
                           spriteName:find("cheap sleeping bag") or
                           spriteName:find("cheap_sleeping_bag") or
                           spriteName:find("cheapsleepingbag") or
                           spriteName:find("cheap") or
                           spriteName:find("coffin") or
                           spriteName:find("couch") or
                           spriteName:find("doublestackedhay") or
                           spriteName:find("double_stacked_hay") or
                           spriteName:find("double stacked hay") or
                           spriteName:find("double") or
                           spriteName:find("high quality sleeping bag") or
                           spriteName:find("high_quality_sleeping_bag") or
                           spriteName:find("high") or
                           spriteName:find("highqualitysleepingbag") or
                           spriteName:find("mat") or
                           spriteName:find("plaidsleepingbag") or
                           spriteName:find("plaid") or
                           spriteName:find("plaid_sleeping_bag") or
                           spriteName:find("plaid sleeping bag") or
                           spriteName:find("seat") or
                           spriteName:find("seating") or
                           spriteName:find("shelter") or
                           spriteName:find("single_stacked_hay") or
                           spriteName:find("singlestackedhay") or
                           spriteName:find("single stacked hay") or
                           spriteName:find("single") or
                           spriteName:find("sleeping bag") or
                           spriteName:find("sleeping_bag") or
                           spriteName:find("sleepingbag") or
                           spriteName:find("sleeping") or
                           spriteName:find("spiffo sleeping bag") or
                           spriteName:find("spiffo") or
                           spriteName:find("spiffosleepingbag") or
                           spriteName:find("spiffo_sleeping_bag") or
                           spriteName:find("stump") or
                           spriteName:find("tent") or
                           false then
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
                           spriteName:find("50sbarstool") or
                           spriteName:find("50s") or
                           spriteName:find("50s_barstool") or
                           spriteName:find("50s barstool") or
                           spriteName:find("bar") or
                           spriteName:find("bar_stool") or
                           spriteName:find("barstool") or
                           spriteName:find("bar stool") or
                           spriteName:find("bench") or
                           spriteName:find("blue bar stool") or
                           spriteName:find("bluebarstool") or
                           spriteName:find("blue") or
                           spriteName:find("blue_bar_stool") or
                           spriteName:find("chair") or
                           spriteName:find("chairs") or
                           spriteName:find("ottoman") or
                           spriteName:find("pew") or
                           spriteName:find("picknic table") or
                           spriteName:find("picknic") or
                           spriteName:find("picknic_table") or
                           spriteName:find("picknictable") or
                           spriteName:find("seat") or
                           spriteName:find("stool") or
                           spriteName:find("table") or
                           false then
                            return BetterResting.RestType.CHAIR
                        end
                    end
                end
            end
        end
    end
    
    return BetterResting.RestType.FLOOR
end