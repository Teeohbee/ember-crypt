# Ember Crypt

A low-poly action-RPG in Godot 4.7, in the vein of Diablo 3 and Grim Dawn, made to be played on a pad
on the Steam Deck / Steam Machine. Never to be released; art is [KayKit](https://kaylousberg.itch.io/)
(CC0), pushed dark.

## where it's up to

**M0 - the shell.** Title, main menu, class select (Barbarian or Mage), a test room with the
chosen hero, pause, and options (audio, display, gameplay, the pad layout). Every screen works on the
pad, B always steps back, and the world never cuts away between menus. The hero can't move yet; that's
M1.

**M1 - feel.** The hero gets up to speed quickly, walks or runs by how far the stick is pushed, and
rolls out of trouble on LT or a flick of the right stick (untouchable for most of the roll). Each
class has its primary on A: the Barbarian's Bash steps in to reach and knocks skeletons back; the Mage's Magic Missile curls
onto whatever aim assist picked. Hits land with a hit-stop, a white flash and squash, a damage number,
camera shake, rumble and a crunch; skeletons burst into bones and their corpses sink away. The camera
leans ahead of a running hero and dithers away any wall in the way. Hit feel is tuned in one place,
`src/core/feedback.gd`, and per skill through its `params` (`hit_stop`, `shake`, `strike_range`...).

**M2 - the combat kit.** Health and power globes either side of a skill bar, D3 style: a socket per
button with a cooldown sweep, a red wash when you can't afford it and a shake when you press it anyway.
A health potion on LB heals 60% and then needs 30 seconds. Fury holds while you fight and drains once
things go quiet for a few seconds; Arcane Power flows back on its own. Three skills each on X, Y and B (A is the primary, M1):

- Barbarian: **Cleave** (an arc of axe, costs Fury), **Leap** (crash down on a target), **War Cry**
  (armour for you and allies close by, and 30 Fury to start a fight with)
- Mage: **Frost Nova** (hurts and chills everything close), **Arcane Orb** (a slow orb that bursts on
  the first thing it meets), **Teleport** (blink along the stick, never through a wall)

Buffs and slows are timed `Statuses` on the stat sheet (`src/combat/statuses.gd`), so anything that
reads move or attack speed slows down when chilled.

**M3 - monsters.** The four skeletons fight back. Each has a `MonsterBrain` (idle, chase, attack,
hurt, die) and its attacks are `SkillDef`s in `src/skills/monsters/`: Minions swarm, Warriors block
hits from the front and telegraph a Grave Smash on the floor, Rogues kite with a crossbow, Mages raise
Minions and throw witchfire. Monsters spawn in packs (`src/monsters/packs/`) that wake together, and a
pack may be led by a named elite with affixes (Fast, Extra Health, Vampiric, Molten, Shielding; in
`src/monsters/affixes/`) and a name plate. Die and "You Have Died" comes up; A rises at the last
checkpoint.

**M4 - loot.** Skeletons drop items and gold, rolled from seeded loot tables: rarity weights tilted
by magic find, bases gated by item level and leaning toward your class, affixes by slot and level.
Drops arc out of the corpse, land with a sound that tells you their rarity, and stand under a beam
in its colour. Walk over gold; press A to pick up an item when nothing hostile is close. Each pickup
shows a card with green / red changes over what you wear; hold D-pad up to put it on. Select opens
the bags and paper doll (A wear / take off, X drop). Weapons and shields show in the hero's hands,
and each class starts with its own. Content is data: `src/items/bases/` and `src/items/affixes/`.

**M5 - progression.** Kills pay XP (more for tougher monsters and elites) up a level curve to 30; each
level grows the class's stats, heals, and sets off a shaft of gold light, a toll and a banner naming
what it unlocked. Skills stay locked until their `SkillDef.unlock_level`. Each skill takes one rune
(`RuneDef`, in `src/skills/runes/<skill id>/`), chosen on the skills screen (D-pad left). Characters
are saved to `user://characters.json` - class, level, XP, runes, bags, gear, zone - on level-ups,
pickups, checkpoints and leaving; the main menu has Continue, a character list (X deletes) and New
Game.

**M6 - the world.** New characters start in **Emberfall**, a walled town square under the moon with
a waypoint, a shared stash (A moves items between bag and chest) and a merchant (A buys and sells;
she pays a quarter of what she charges). The north gate leads to **the Hollow Graveyard**, rows of
graves in thick fog, and the mausoleum there goes down into **the Ember Crypt**: a dungeon grown
from a seed out of hand-made rooms (`src/world/dungeon/chunks/*.tres`; a new room is a new resource),
with a checkpoint halfway and the boss in the furthest dead end. **Vargoth, the Bone Warden** fights
in three phases - quicker each time, raising the dead from the second - and paints his slam on the
floor before it lands; killing him opens a waypoint home. A uses whatever is in reach (waypoint,
stash, merchant, stairs) when nothing hostile is close. Waypoints you've touched, the crypt's seed and
the stash are saved. The graveyard is built from the dungeon kit until the Halloween Bits pack lands.

## controls

Pad first; keys exist for testing.

| | Pad | Keys |
|---|---|---|
| Menus | Left stick / D-pad, A, B | Arrows / WASD, Enter, Esc |
| Options tabs | LB / RB | Q / E |
| Move | Left stick | WASD / arrows |
| Skills | A, X, Y, B, RB, RT | J, K, L, ;, U, O |
| Potion | LB | Q |
| Evade roll | LT, or flick the right stick | C |
| Pause | Start | Esc |
| Pick up (loot in reach, nothing hostile close) | A | J |
| Hold to equip what you picked up | D-pad up | F |
| Inventory | Select | I / Tab |

| Skills screen | D-pad left | P |

## running

Open `project.godot` in Godot 4.7 and run. No external dependencies at runtime.

## tests

[gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) via [gd-plug](https://github.com/imjp94/gd-plug).
Addons aren't committed, so after cloning:

```sh
godot --headless -s plug.gd install
tests/run.sh                                  # everything, headless
tests/run.sh res://tests/test_front_end.gd   # one suite
```

## how things are made

- **KayKit models.** Every `.glb` embeds its pack's whole texture atlas. `tools/kaykit_import.gd` throws
  the embedded copies away on import and points each mesh at one shared material per atlas in
  `assets/kaykit/materials/`, so the atlas is in VRAM once. Character rigs come holding every prop
  they were modelled with; a `HeroClass` lists the ones it keeps.
- **The dark.** `src/world/look.gd` holds the environment, torch and hero lights, and flames. Tune the
  tone there.
- **Audio** is composed in code (`src/audio/compositions.gd`) and rendered to WAVs, which are committed.
  After changing a recipe:

  ```sh
  godot --headless --path . -s tools/render_audio.gd
  ```

## credits

- Characters, weapons, dungeon and Halloween Bits: KayKit by Kay Lousberg, CC0
- Cinzel (Natanael Gama) and Alegreya Sans (Huerta Tipográfica), SIL Open Font License
