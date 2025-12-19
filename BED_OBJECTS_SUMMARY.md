# Bed Objects Extraction Summary

## Results from newtiledefinitions.tiles.txt

**Total objects with BedType: 707**
- **averageBed**: 204 objects
- **badBed**: 411 objects  
- **goodBed**: 92 objects

## Unique CustomItems Found (23 total)

### Tents
1. `Base.CampingTentKit2` - Tent (badBed)
2. `Base.HideTent` - Tent (badBed)
3. `Base.ImprovisedTentKit` - Tent (badBed)
4. `Base.TentBlue` - Tent (badBed)
5. `Base.TentBrown` - Tent (badBed)
6. `Base.TentGreen` - Tent (badBed)
7. `Base.TentYellow` - Tent (badBed)

### Sleeping Bags
8. `Base.SleepingBag_BluePlaid` - Plaid Sleeping Bag (badBed)
9. `Base.SleepingBag_Camo` - Sleeping Bag (badBed)
10. `Base.SleepingBag_Cheap_Blue` - Cheap Sleeping Bag (badBed)
11. `Base.SleepingBag_Cheap_Green` - Cheap Sleeping Bag (badBed)
12. `Base.SleepingBag_Cheap_Green2` - Cheap Sleeping Bag (badBed)
13. `Base.SleepingBag_Green` - Sleeping Bag (badBed)
14. `Base.SleepingBag_GreenPlaid` - Plaid Sleeping Bag (badBed)
15. `Base.SleepingBag_Hide` - Sleeping Bag (badBed)
16. `Base.SleepingBag_HighQuality_Brown` - High Quality Sleeping Bag (badBed)
17. `Base.SleepingBag_RedPlaid` - Plaid Sleeping Bag (badBed)
18. `Base.SleepingBag_Spiffo` - Spiffo Sleeping Bag (badBed)

### Beds and Bed-like Objects
19. `Base.Mov_Cot` - Bed (averageBed)
20. `Base.Mov_FlatCoffin` - Coffin (badBed)
21. `Base.Mov_Gurney` - Bed (averageBed)
22. `Mov_Gurney` - Bed (averageBed)
23. `Base.Mov_GymnMat` - Mat (badBed)

## Notes

- All objects with `BedType` are bed/sleeping related objects
- **Picnic tables and seating furniture (chairs, benches, stools) are NOT found with BedType parameter**
- These seating objects likely use different parameters or sprite name patterns
- We may need to search for other parameters like:
  - `SeatType` or similar
  - Sprite names containing "chair", "bench", "stool", "picnic", etc.
  - Furniture categories

## Next Steps

1. Search for seating-related parameters in the tiles file
2. Search sprite names for seating furniture patterns
3. Cross-reference with the current mod detection logic

