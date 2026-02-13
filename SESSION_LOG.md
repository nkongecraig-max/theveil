# SESSION LOG -- The Veil
## Ni Biashara LLC

---

## Session 1 | 2026-02-13 | Complete
**Focus:** Project foundation -- structure, core systems, main menu
**Done:**
- Created full project directory structure (scenes, scripts, assets, data, content, ops, exports)
- Created project.godot configured for mobile (720x1280, portrait, mobile renderer)
- Built 4 autoload singletons:
  - game_manager.gd -- central state, progression, phase transitions, day system
  - save_manager.gd -- JSON save/load to device storage
  - ad_manager.gd -- diegetic ad engine with placeholder content, surface registration, impression/interaction tracking
  - analytics.gd -- silent behavioral profiling (puzzle style, social style, aesthetic preferences, play patterns)
- Created all 4 sacred documents (this file, ROADMAP, DECISIONS, BUDGET)
- Main menu scene with New Game / Continue / Settings
- Moved project to local drive (~/Documents/NiBiashara/the-veil) -- OBS works here
- External drive backup at /Volumes/LaCie/Twe Gaming Industries/the-veil
- Created sync-backup.sh for one-command rsync to external
- Updated project to Godot 4.6
- Art direction: Flat Minimal (D008) -- optimized for diegetic ad surfaces
- Built shop interior scene (shop.tscn) with flat minimal style:
  - Floor, walls, counter, 4 shelves with collision
  - 3 diegetic ad surfaces: billboard (back wall), 2 wall posters
  - Player character with tap-to-move touch controls
  - Camera2D with smooth follow and scene bounds
  - HUD overlay (day counter, coin display)
  - Ad surfaces auto-register with AdManager on scene load
**Decisions:** See DECISIONS.md Session 1 entries (D001-D008)
**Next up:** Open in Godot 4.6, test shop walkability, add shelf interaction (tap shelf to see items)
**Blockers:** None
**Content generated:** Project structure + shop scene screenshot opportunities
