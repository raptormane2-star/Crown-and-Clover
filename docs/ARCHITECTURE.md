# Architecture

## v0.3 baseline
The uploaded v0.3 prototype places most runtime behavior in one large `main.gd`. That version remains the gameplay reference while v0.4 is refactored.

## v0.4 target
- `scenes/` - composition and reusable objects
- `systems/` - items, inventory, saves, day/night, villagers/jobs
- `world/` - overworld state and TileMapLayer migration
- `characters/` - player/NPC logic
- `enemies/` - combat actors
- `buildings/` - definitions and placement
- `ui/` - HUD, hotbar, inventory and dialogue

The refactor should preserve behavior first, then replace prototype world drawing and collision incrementally.
