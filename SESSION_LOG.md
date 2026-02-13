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

---

## Session 2 | 2026-02-13 | In Progress (Sprint)
**Focus:** Testing, shelf interaction, items, customers, first puzzle
**Done:**
- Fixed player movement (mouse_filter blocking clicks, switched to _input)
- Added text labels to all shop elements (SHELF, COUNTER, AD SPACE, EXIT, YOU)
- Tested in Godot 4.6 -- shop runs, player moves, layout readable
- Built shelf interaction system (tap shelf when nearby to open inventory panel)
- Created 6 starter items with JSON data (bread, candle, herbs, soap, tea, pottery)
- Built inventory panel with slide-up animation and colored item cards
- Built sorting puzzle -- customers request items in order, player taps items in sequence
- Created NPC customer system with 5 customer templates (Mara, Old Jin, Kess, Davi, Renna)
- Customer manager: 3 customers per day, auto-spawns with delays between
- Full gameplay loop: customer arrives → walks to counter → player taps counter → puzzle opens → solve order → earn coins → next customer → day advances
- All interactions tracked via Analytics
- Fixed counter interaction (customer collision, tap zone sizing, proximity detection)
- Fixed shelf interaction (centralized all input in shop.gd, Rect2 zone-based hit detection)
- Wired save system -- auto-saves at day end
- Added day summary screen between days (shows coins + level, Next Day button)
- Added puzzle visual polish: fade-in/out, colored buttons, scale bounce, green/red flash feedback
- Built recipe combining puzzle (second puzzle type):
  - Customer requests a crafted product (Herbal Soap, Tea Set, etc.)
  - Player picks correct ingredients from a pool (includes decoys)
  - Order doesn't matter -- teaches pattern matching vs sorting's sequential ordering
  - 6 recipes: Herbal Soap, Scented Candle, Bread Basket, Tea Set, Gift Bundle, Herb Tea
- Expanded customer pool to 7 templates with both puzzle types
- Economy balancing: customers/day scales (3→4→5), day bonus on rewards, HUD shows level
- Synced backup to LaCie external drive
**Next up:** Third puzzle type, playtesting, shop upgrades (spend coins on something)
**Blockers:** None
**Content generated:** Two puzzle types working, full economy loop, save/load functional
