# Crown & Clover

Crown & Clover is a cozy top-down pixel-art kingdom-building exploration RPG built in Godot 4.

The player starts with a small settlement and grows it through the loop:

**gather -> build -> explore -> fight -> expand -> rule**

## Repository status

`main` is the stable public repository baseline: Godot project configuration, CI, roadmap, architecture and license-safe source structure. The uploaded **v0.3 - Kingdom Life** project is the gameplay reference used for the refactor, but its raw third-party art/audio is not redistributed from this public repository unless the individual asset license explicitly permits that.

Active development is on `agent/v0.4-foundation-refactor` (draft PR #1). That branch contains the modular v0.4 gameplay foundation.

## Open in Godot

For v0.4 development, check out `agent/v0.4-foundation-refactor`, copy the licensed asset folders from the supplied Crown & Clover project archive into `game/assets/`, then open `game/project.godot` in Godot 4.7.1 stable on Windows and press F5.

## Repository layout

- `game/scenes/` - composed Godot scenes
- `game/scripts/` - game orchestration
- `game/systems/` - inventory, items, time, saves and villager jobs
- `game/ui/` - HUD, hotbar and inventory UI
- `game/world/` - world gameplay and TileMapLayer migration target
- `game/characters/` - player and future NPC character controllers
- `game/enemies/` - enemy scenes/scripts as the combat refactor expands
- `game/buildings/` - building definitions and placement system target
- `game/items/` - item resources and definitions
- `game/assets/` - local licensed asset layout
- `game/audio/` - local game audio
- `docs/` - roadmap, design, architecture and licenses
- `.github/` - project validation and issue workflow

## Development rules

- Keep `main` stable and review larger work through feature branches/PRs.
- In-game text is English.
- Pixel-art rendering uses nearest filtering and integer scaling.
- Third-party licenses must be tracked before raw assets are committed or a commercial build ships.

See `docs/ROADMAP.md`, `docs/ARCHITECTURE.md`, `docs/ASSET_LICENSES.md` and `CHANGELOG.md`.
