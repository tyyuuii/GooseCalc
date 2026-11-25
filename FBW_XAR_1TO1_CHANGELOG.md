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
