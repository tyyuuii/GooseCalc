# Fractal Block World (Xar) — 1:1 Mechanics Alignment Changelog

Researched against the official **FBW (Xar) Game Manual** (danthemanhathaway.com, Aug 2026 ed.),
the Steam store page, the fractalblockworld.wiki.gg wiki, and community guides.
All changes are in `src/fbw_core.goose` + `src/fbw_mobile.goose`. Typechecked with goose v2026.4
(0 errors) and smoke-tested headless (64s of simulated flight/combat, no crashes).

## Fixed gameplay-logic bugs (divergences from the Steam version)

| # | Bug | Was | Now (authentic) |
|---|-----|-----|-----------------|
| 1 | Death penalties | kept armor & ammo | lose **all armor**, lose **all ammo except plasma (refilled)**, −30 gold (kept upgrades/long markers) — manual §4 |
| 2 | Damage split | armor ate a flat 2/3 | shield first, then **75% armor / 25% health**; **100% health when overhealed** — manual §7.4 |
| 3 | Shield formula | 50 + 15/armor-upg, 0.625/s regen | **max = 25 + health level**; regen **(1 + X/4)/s** — manual §7.1 |
| 4 | Health formula | 0.5→1→1.5/s steps | regen **(1 + X/4)/2 per second**, X = regen level; **overheal above 2B decays 1 hp/s** — manual §7.2 |
| 5 | Armor model | +25 max armor blocks | armor is a **resource topped up to B-fractions** (bronze→B, silver→1.5B, gold→2B, ivory→6B, jade→10B, shards) — manual §7.3 |
| 6 | XP / leveling | XP was a dead score counter | **kills grant XP; level-ups (max 500) grant +1 damage (all weapons), +1 max health, +1 regen** — manual §10 |
| 7 | Ammo caps | invented (laser 120, homing 32, minigun 400…) | per-weapon manual caps: plasma 40+10, cannon 100+5, laser 32+8, rocket 20+4, homing 200+10, minigun 48+12, railgun 48+12, EMP 2+1, nuke 1+1, dark hole 1+1 |
| 8 | Plasma regen | 4.5 ammo/s (trivialized plasma) | **0.5 ammo/s** (manual §9.2) |
| 9 | Dark Hole drives | 180s/300s boosts for 1 ammo | **Black Hole Drive: 20 ammo, 30s; Quasar Drive: 60 ammo, 30s** — manual §9.11 |
| 10 | Dark Hole "blood pact" | −75 HP → +2 ammo | **Exchange Health for Ammo: +1 ammo, 100 self-damage** (can kill you, as in Xar) |
| 11 | EMP | mode 0 was a damage projectile | **both modes are player-centered pulses; primary = stun-only, secondary = damage + 100 self-damage** — manual §9.9 |
| 12 | Laser "Shield Pulse" mode | invented AoE | replaced with the authentic **Freeze Ray** (6× dmg, *stacking* freeze) |
| 13 | Laser freeze | Ice Laser couldn't freeze | **Ice 2.5s, Cold Beam 2.5× that, Freeze Ray stacks to 20s**; **any laser shot fully recharges your shield** (manual §9.4) |
| 14 | Laser Disco | missing | added: 32× dmg, 50 self-damage, **kills splash Ice Lasers at nearby monsters** |
| 15 | Minigun poison | mode 1 was just "faster" | authentic **poison dart**: no impact damage, poison = 20 primary shots over 10s, re-hits extend duration |
| 16 | Cannon Sheriff/Judge | missing | added: **Sheriff 10× dmg (1/s), Judge 100× dmg (1/5s)** |
| 17 | Cannon chaining | missing | **Chaining Ball / Sheriff / Judge chain to the next closest monster on kill** (manual §9.3) |
| 18 | Vampire railgun | fixed +12 HP | heals **¼ of damage dealt** (up to 2B); Super Vampire added |
| 19 | Rocket modes | 2 generic modes | 5 authentic modes: **Basic (splash = ½ direct dmg), High Velocity (3× spd, 2× dmg), Big Radius (2× radius), Kinetic (4× dmg, no AoE), Progressive (18× dmg, no AoE)** |
| 20 | Homing | 1/2-ammo shots | **primary costs 20 ammo, locks on + free minigun bullets at nearby monsters; secondary: 20 rockets for 10 ammo** |
| 21 | Nuke HV mode | *more* damage & 2 ammo | **3× speed, 2× radius, ½ damage, 1 ammo** (was inverted) |
| 22 | Splash damage | full damage to everyone | **splash = ½ direct damage; direct-hit target excluded** (manual §9.5) |
| 23 | Dark Hole AoE | uniform damage | authentic chain: **direct 2D, then D/2, D/3, D/4…** + pull |
| 24 | Free emergency plasma bolt | free shots when OOA | removed — plasma trickle regen is the Xar economy |
| 25 | Marker costs | short 5g / long free | **short 10g, long 20g** (manual §6) |
| 26 | Upgrade pickups | armor upg granted +max armor/shields | armor upg tops armor **to B**; health upg also raises the derived shield cap |

## Added depth (features that were missing entirely)

- **XP/Level system** — per-kill XP scaled by enemy kind & depth; HUD shows `Lv` + XP%; F3 shows player level.
- **Upgrade Station** (manual §8.6) — new block/biome placement/screen: per-weapon damage upgrades
  (plasma/cannon/laser/rocket/EMP 100g, railgun/nuke 200g, dark hole 300g), health capacity 200g,
  health regen 100g. **Buying a weapon's upgrade unlocks the weapon** (authentic "any upgrade unlocks" rule).
- **Authentic Buy Station menu** (§8.4): 20 cannon/100 laser/50 rocket/1000 homing/100 minigun/20 railgun/1 EMP per 100g,
  200% health 100g, 100%/150%/200% armor 100/150/200g (brings you *up to* that amount).
- **Authentic Black Market** (§8.5): 50 railgun / 2 EMP / 2 nukes per 100g.
- **Sell Station sells surplus ammo** (fixed prices; Xar rolls per station color).
- **Per-weapon ammo boxes** (small sizes per manual) instead of one generic "+everything" pack; plasma boxes **refill to full**.
- **Pickup tiers** via entity metadata: health (small/med/to-B/to-2B/mega), armor (bronze→jade), shield-recharge box.

## Documented simplifications (kept, not silently wrong)

- Damage numbers use the port's own scale (rooms are 16 blocks, not Xar's scale); *ratios* between
  weapon modes follow the manual. Absolute velocities are port-tuned.
- One global damage/fire-rate/ammo-capacity upgrade level instead of per-weapon upgrade pools with
  "beyond max" conversion tables.
- LOD damage rules (dark hole only hits coarser enemies, minigun hits 1 coarser, etc.) aren't
  representable — the port has single-scale monsters.
- Quasar Drive stays gated behind defeating The Singularity (port-level progression twist).
- Plasma ammo-regen upgrades, flare lighting, marker expiry (3h), and enemy freeze/stun immunities
  are future work.

## Verification

- `goose check src/calc_main.goose` — 0 errors (106 style warnings, pre-existing class).
- Regenerated `calc_main.c/h` and rebuilt the x86 headless harness: calculator + Sudoku paths unchanged,
  FBW ran a 4000-frame fly-and-fight scenario (flight stick, held fire, look drags) with zero crashes;
  HUD now reports authentic start stats (`HP 100/100 SHD 25 ARM 0`) and `Lv1 XP0%`.

---

# Round 2 — Map/progression fidelity, optional size change, kilochunk view distance

## Evidence the port's map & progression diverged from the Steam original

- **Official Steam screenshot** (`ss_edf19e21bfcc2c1995e50072e6d0927.1920x1080.jpg`, steambase.io mirror of
  Steam CDN): HUD shows `Level: 15`, and the terrain's black chunk-boundary grid lines run continuously
  across **dozens of chunks** into the distance — structures do *not* pop in/out one chunk away.
  (saved for reference in `image-search/fractal-block-world-steam-game-screensho-3.jpg`, second view in
  `...-2.jpg`).
- **Wiki, Tutorial page** (fractalblockworld.wiki.gg/wiki/Tutorial, fetched 2026-11-25):
  - *"The **Tutorial** is a location in the **Ying World** … found inside every Ying Flower"* — the
    Tutorial Island is one landmark inside a much larger same-scale region, not a sealed world.
  - *"In the surrounding **Kilochunk**, the player can see the entire structure of the Tutorial."*
    A kilochunk = 4096³ blocks ≈ 16 chunks per axis. The original renders the whole structure; the port
    drew 1 chunk + 10 neighbors (pop-in at every chunk boundary).
  - *"**If the player doesn't grow after exiting the Tutorial**, the Blue Ring … will be replaced by
    another pedestal with a smaller Blue Ring (which will still take the player to the start)"* —
    **growing after the Tutorial is optional**, and *"The player can grow using the Expander"* —
    size changes happen only through rings/expanders, never automatically at a boundary.
- **Steam discussion** (16³ chunks per level, recursive; whole world in one root chunk) confirms the
  scale model the port already uses — the divergence was purely the *view distance* and the forced grow.

## Fixes in this round

| # | Bug | Was | Now (authentic) |
|---|-----|-----|-----------------|
| 1 | **Forced size change leaving Tutorial Island** | any boundary crossing at depth ≤ 0 with a solid parent chunk force-grew 16× (`grow_out_axis`) — you could not fly around the island at the same size | boundary crossings at **every depth** use the same-size lateral world shift (`step_air_single_axis`); `grow_out_axis` remains only for ring/expander use; a soft in-bounds clamp is the sole safety net |
| 2 | **Chunk pop-in (1-chunk view distance)** | 1 chunk + 10 neighbors (6 faces + 4 diagonals), `world_block_rel`/`chunk_at` limited to ±1 | **ring-ordered sibling set out to radius 1–3** (26 / 124 / 340 sibling chunks; full 7³−1 kilochunk ring at radius 3), resolved nearest-ring-first on every chunk load |
| 3 | **No view-distance option** | fixed invisible cap | new **`VIEW DIST: N CHUNKS` slider** in the pause menu (1–3, default 2, validated + persisted like the LOD slider); tapping it reloads chunks instantly and reports `VIEW DIST: 3 CHUNKS (342 LOADED)` |
| 4 | Renderer capacity | C side hardcoded `MAX_NEIGHBORS 10` with O(n) offset scans | C side raised to **342** with an O(1) offset→slot hash map (`neighbor_map_rebuild` on meta sync), `chunk_at`/`world_block_rel` ranges widened to ±3 chunks; meshing is dirty-flagged so the cost is one rebuild per change |

Pause menu layout: the two full-width bottom buttons became side-by-side **RESTART RUN | EXIT** to make
room for the new slider row.

## APK / UnsatisfiedLinkError safety (verified)

- The Java-visible JNI surface is exactly the same 7 exported functions as before
  (`goose_init`, `goose_exit`, `goose_draw`, `goose_handle_back`, `goose_handle_pointer`,
  `goose_handle_touch`, `goose_force_resize`) — verified by diffing `calc_main.h` exports and
  `nm calc_main.o` before/after: **identical**.
- `fbw_gl.h` is unchanged; `fbw_gl.c` adds only a `static` helper. All 19 `fbw_gl_*` symbols referenced
  by the regenerated `calc_main.o` are defined in `fbw_gl.o` (checked with `nm`); the 3 remaining
  externs (`fbw_now_ms`, `fbw_sound_fx`, `fbw_set_orientation`) are provided by `main.c` as before.
- The Makefile regenerates `calc_main.c` from `src/calc_main.goose` on build
  (`goose --standalone --header calc_main.h -o $@ $<`), so source and generated C can never desync.
- No new Goose `export fn`, no new `extern` declarations, no signature changes anywhere.

## Verification (this round)

- `goose check` → 0 errors; headless harness full regression (calculator/sudoku/FBW) exit 0.
- Boundary flight test (2500 frames, forward+up+yaw sweep into the island edges): **0 forced-grow
  events, LVL stayed 0** (was: every edge reach force-grew + leveled up).
- Pause → drag VIEW DIST slider to 3 → resume → 900-frame flight at radius 3 (342 neighbors):
  exit 0, status `VIEW DIST: 3 CHUNKS (342 LOADED)`, modal shows `VIEW DIST: 3 CHUNKS`.
- `fbw_gl.c` syntax-checked (GLES3 stub headers); host link of calc_main.o + fbw_gl.o symbol-complete.

---

# Round 3 — SHRK far-teleport exploit, chunk streaming, LOD tiering & sync culling

## Bug 1 (user-reported): shrink teleports you into a far block

**Reproduced headless**: with SHRINK ANY toggled, pressing [SHRK] at spawn (Black Cube 3.8 blocks
away) printed `Shrank 16x into fractal block!` — instant teleport, no travel. Root causes:

1. `shrink_targeted_block()` ray reach was **4.5 blocks under SHRINK ANY** (2.4 otherwise) — Xar only
   shrinks into blocks you are **touching** (ShrinkAny widens *which* blocks qualify, never the reach).
2. A free **in-place fallback** shrank you 16× from anywhere under SHRINK ANY or Genesis mode — Xar
   never shrinks with nothing near.

**Fix**: ray reach **1.45** for every mode; ring/USE proximity tightened to **1.2** (fly-into-ring,
was 2.6); in-place fallback removed (message instead); tutorial tip now says "fly to the Black Cube".
Verified: SHRK at spawn does nothing in normal/Genesis/ShrinkAny modes; flying adjacent to the cube
and pressing SHRK still shrinks into it (legit path preserved). The touch-collision shrink path is
untouched (authentic).

## Bug 2 (user-reported): LOD & culling broken after the chunk-distance update

Measured root causes, all fixed:

| Problem | Effect | Fix |
|---|---|---|
| **Batch4 script bug**: the `view_chunk_radius = 2` default was silently lost (patch script asserted after applying it in memory but before writing the file) | the initial chunk load ran with radius **0** → *zero* neighbors resolved at spawn → visible void/pop-in at the start and after every settings change | default restored at enter; the per-frame clamp now reloads chunks when it corrects an out-of-range value |
| GL sync pushed **342 chunks × 1024 quads (~350k FFI calls)** on every chunk change, even for empty air | multi-hundred-ms stalls; far geometry appeared in bursts | per-slot **non-air fill counter** + **dirty flags**: only non-empty chunks sync, only changed slots re-push, zero-packed quads skipped (C side clears slot buffers on meta). Measured: **5,722 pushes instead of ~127k (22× less)** |
| All 342 neighbors meshed at **full per-block detail** | huge vertex buffers, FPS collapse | **distance-tiered meshing**: ring 1 full detail, ring 2 = 2×2×2 decimated cells (⅛ cubes), ring 3 = 4×4×4 (1/64); cell faces culled cell-to-cell and across chunk borders through the neighbor map; ring 1 keeps the exact previous per-block path |
| All far rings generated **at once** during a chunk crossing | giant hitch at every boundary | **chunk streaming**: ring 1 resolves immediately, rings 2–3 are queued and resolved **8 slots per frame** (`resolve_pending_neighbors`) — measured 8→42→74→**124/124 slots by frame 20** at radius 2 with no hitch |

## Verification (round 3)

- `goose check` → 0 errors; JNI exports byte-identical; all `fbw_gl` symbols resolve.
- Harness: 4 shrink scenarios (normal / Genesis / ShrinkAny at spawn = no teleport; adjacent = legit
  shrink), streaming counters (124/124 by frame 20), 0 forced grows, slider + full calculator/sudoku
  regression — exit 0.
