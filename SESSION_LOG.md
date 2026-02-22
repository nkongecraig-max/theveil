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

---

## Session 3 | 2026-02-21/22 | Complete (Sprint)
**Focus:** Visual overhaul, character fixes, level progression, V1 readiness, web deploy
**Done:**
- Fixed startup crash (set_parallel on PropertyTweener → moved to Tween correctly)
- Visual overhaul: parquet herringbone floor, shelf personality (different wood tones, trim), warm glow effects, styled UI panels
- Fixed HUD/inventory overlap (added panel_closed signal, _set_hud_visible toggle)
- Changed hint icons to 🥷 ninja emoji throughout day_intro.gd
- Fixed hint overlay on puzzles (hints hide during puzzle, reappear after)
- Made characters 1.5x larger (Node2D scale) so names fit on clothing
- Added name drawing on customer shirts and "SHOP" text on player apron
- Removed iron L-bracket shapes from shelves (looked like parentheses at mobile size)
- Built complete level-driven visual progression system:
  - shop_visuals.gd: base→premium color palette lerp, 9 milestone decorations (plant, clock, rugs, sconces, curtains, flowers, crown molding)
  - player_visual.gd: outfit evolves (SHOP→PRO→MASTER text, badge pin, gold trim, collar detail, golden aura at level 10)
  - Connected to game_state_changed("player_level") signal
- V1 readiness batch:
  - AudioManager autoload: procedural SFX (9 types) + warm ambient drone, no external files
  - Daily rewards system: streak-based 5-25 coins, calendar date tracking
  - Best-day stats tracking (coins, customers served)
  - Pause handling: auto-save on app background, tree pause/resume
  - Splash screen: animated title card → save load → ambient start → game
  - Day summary enhanced with best-day records + tomorrow tease
  - Customer patience bar accessibility (colorblind patterns: stripes critical, dots medium)
  - Created docs/ pages: landing page, privacy policy, support FAQ
  - Updated project.godot with AudioManager autoload + splash screen as main scene
- GitHub deployment:
  - Pushed codebase to github.com/nkongecraig-max/theveil
  - Exported Godot web build (HTML5, no-threads) to docs/game/
  - Made repo public, enabled GitHub Pages from docs/
  - Live at: https://nkongecraig-max.github.io/theveil/
  - Game playable at: https://nkongecraig-max.github.io/theveil/game/

**Commits:**
- 0bc5ca5 — Fix startup crash (set_parallel on PropertyTweener)
- deee699 — Visual overhaul (parquet floor, shelf personality, glow effects, styled UI)
- e2b32aa — V1 readiness: audio, progression, polish, accessibility, splash screen
- d550622 — Add web build for Caia testing via GitHub Pages

**Next up:** Get Caia's feedback from web build, iterate on issues she finds, third puzzle type (memory), upgrade shop
**Blockers:** None
**Content generated:** Full web-playable demo, GitHub Pages site with privacy policy + support
