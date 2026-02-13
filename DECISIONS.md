# DECISIONS LOG -- The Veil
## Every design and business decision with reasoning

---

## Session 1 | 2026-02-13

### D001: Engine -- Godot 4.3
**Decision:** Use Godot 4.3 (standard, not .NET)
**Why:** Free, no royalties, no licensing fees. Lightweight. Excellent 2D support. Active community. Aligns with Climber budget ($0 engine cost). All diegetic ad SDKs (Anzu, Frameplay) offer Unity plugins but Godot can use GDExtension or HTTP-based ad serving for the same result.
**Alternative rejected:** Unity (licensing concerns, runtime fee controversy). Unreal (overkill for 2D puzzle game).

### D002: Target -- Mobile portrait, 720x1280
**Decision:** Design for portrait orientation, 720x1280 base resolution
**Why:** Puzzle-RPG games perform best in portrait on mobile. One-hand play. Matches user behavior (phone held naturally). 720x1280 scales well to all modern devices.

### D003: Platform -- Android first
**Decision:** Launch on Android first. iOS follows after revenue proves concept.
**Why:** Google Play costs $25 one-time vs Apple's $99/year. Android has larger global reach. Validates the game before investing in iOS toolchain. Both share 95% of the same Godot codebase.

### D004: Architecture -- 4 autoload singletons
**Decision:** GameManager, SaveManager, AdManager, Analytics as autoloads
**Why:** Autoloads persist across scenes. Clean separation of concerns. GameManager is the single source of truth for game state. Analytics runs silently from day 1, building the behavioral profile the AI companion needs in Act 3.

### D005: Ad system -- Placeholder-first, SDK-later
**Decision:** Build diegetic ad system with placeholder content. Integrate real ad SDK after 5K DAU.
**Why:** No point paying for SDK integration before traffic exists. Placeholder system lets us design the narrative ad experience (billboards, newspapers, products) without being constrained by SDK limitations. When real ads come, they slot into the same surfaces.

### D006: Data storage -- JSON on device
**Decision:** Use JSON files in user:// for saves and analytics
**Why:** Simple. Works offline. No server needed for Phase 0-3. Player data stays on their device (privacy-friendly). Can migrate to cloud sync later when backend exists.

### D007: Publishing entity -- Ni Biashara LLC
**Decision:** Publish under Ni Biashara LLC
**Why:** Existing LLC in good standing with active bank account. Clean separation of business and personal finances. Required for bank loan approach.
