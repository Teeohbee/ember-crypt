# Ember Crypt

A low-poly action-RPG in Godot 4.7, in the vein of Diablo 3 and Grim Dawn, made to be played on a pad
on the Steam Deck / Steam Machine. Never to be released; art is [KayKit](https://kaylousberg.itch.io/)
(CC0), pushed dark.

## where it's up to

**M0 - the shell.** Title, main menu, class select (Barbarian or Mage), a test room with the
chosen hero, pause, and options (audio, display, gameplay, the pad layout). Every screen works on the
pad, B always steps back, and the world never cuts away between menus. The hero can't move yet; that's
M1.

**M4 - loot.** Skeletons drop items and gold, rolled from seeded loot tables: rarity weights tilted
by magic find, bases gated by item level and leaning toward your class, affixes by slot and level.
Drops arc out of the corpse, land with a sound that tells you their rarity, and stand under a beam
in its colour. Walk over gold; press A to pick up an item when nothing hostile is close. Each pickup
shows a card with green / red changes over what you wear; hold D-pad up to put it on. Select opens
the bags and paper doll (A wear / take off, X drop). Weapons and shields show in the hero's hands,
and each class starts with its own. Content is data: `src/items/bases/` and `src/items/affixes/`.

## controls

Pad first; keys exist for testing.

| | Pad | Keys |
|---|---|---|
| Menus | Left stick / D-pad, A, B | Arrows / WASD, Enter, Esc |
| Options tabs | LB / RB | Q / E |
| Pause | Start | Esc |
| Pick up (loot in reach, nothing hostile close) | A | J |
| Hold to equip what you picked up | D-pad up | F |
| Inventory | Select | I / Tab |

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
