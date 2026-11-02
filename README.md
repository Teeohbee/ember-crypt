# Ember Crypt

A low-poly action-RPG in Godot 4.7, in the vein of Diablo 3 and Grim Dawn, made to be played on a pad
on the Steam Deck / Steam Machine. Never to be released; art is [KayKit](https://kaylousberg.itch.io/)
(CC0), pushed dark.

## where it's up to

**M0 - the shell.** Title, main menu, class select (Barbarian or Mage), a test room with the
chosen hero, pause, and options (audio, display, gameplay, the pad layout). Every screen works on the
pad, B always steps back, and the world never cuts away between menus. The hero can't move yet; that's
M1.

**M2 - the combat kit.** Health and power globes either side of a skill bar, D3 style: a socket per
button with a cooldown sweep, a red wash when you can't afford it and a shake when you press it anyway.
A health potion on LB heals 60% and then needs 30 seconds. Fury drains away steadily, so keep landing
blows; Arcane Power flows back on its own. Three skills each on X, Y and B (A is the primary, M1):

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

**M5 - progression.** Kills pay XP (more for tougher monsters and elites) up a level curve to 30; each
level grows the class's stats, heals, and sets off a shaft of gold light, a toll and a banner naming
what it unlocked. Skills stay locked until their `SkillDef.unlock_level`. Each skill takes one rune
(`RuneDef`, in `src/skills/runes/<skill id>/`), chosen on the skills screen (D-pad left). Characters
are saved to `user://characters.json` - class, level, XP, runes, bags, gear, zone - on level-ups,
pickups, checkpoints and leaving; the main menu has Continue, a character list (X deletes) and New
Game.

## controls

Pad first; keys exist for testing.

| | Pad | Keys |
|---|---|---|
| Menus | Left stick / D-pad, A, B | Arrows / WASD, Enter, Esc |
| Options tabs | LB / RB | Q / E |
| Skills | A, X, Y, B, RB, RT | J, K, L, ;, U, O |
| Potion | LB | Q |
| Pause | Start | Esc |
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

- Characters, weapons and dungeon: KayKit by Kay Lousberg, CC0
- Cinzel (Natanael Gama) and Alegreya Sans (Huerta Tipográfica), SIL Open Font License
