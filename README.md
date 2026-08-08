# Crown & Clover

Crown & Clover is a cozy top-down pixel-art kingdom-building exploration RPG built in Godot 4.

The player starts with a small settlement and grows it through the loop:

**gather -> build -> explore -> fight -> expand -> rule**

## Current stable prototype

`main` contains the v0.3 - Kingdom Life baseline source. The raw third-party art/audio stays local while redistribution rights are verified, because this repository is public.

## Open in Godot

Open `game/project.godot` in Godot 4.7.1 stable on Windows and press F5.

## Repository layout

- `game/` - Godot project and local asset layout
- `docs/` - roadmap, design and architecture notes
- `licenses/` - retained third-party license files
- `.github/` - issue templates and project validation

## Development rules

- Keep `main` as the stable baseline.
- Develop larger features on dedicated branches.
- In-game text is English.
- Pixel-art rendering uses nearest filtering and integer scaling.
- Third-party asset licenses must be tracked before commercial release.

See `docs/ROADMAP.md` and `CHANGELOG.md`.
