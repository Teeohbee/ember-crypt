class_name Levels
# The rules of levelling, kept pure so they can be tested and tuned in one place: the XP curve, how much
# a kill is worth, and per-level stat growth. HeroProgress applies them to a hero.

const MAX_LEVEL := 30
# xp_to_next(level) = CURVE_BASE + CURVE_SCALE * level ^ CURVE_POWER: 100 for level 2, ~9,400 for the cap
const CURVE_BASE := 40.0
const CURVE_SCALE := 60.0
const CURVE_POWER := 1.5
# Each level a monster is above (or below) the hero adds (or takes) this share of its XP
const LEVEL_GAP_SHARE := 0.15
const GAP_FLOOR := 0.2
const GAP_CEILING := 2.0
const ELITE_MULTIPLIER := 3.0
# The Stats modifier source that growth sits under
const GROWTH_SOURCE := &"level"

# XP needed to go from level to level + 1; 0 at the cap
static func xp_to_next(level: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	return roundi(CURVE_BASE + CURVE_SCALE * pow(level, CURVE_POWER))

# Adds amount to xp at level, rolling over as many levels as it pays for. Returns [level, xp].
static func add_xp(level: int, xp: int, amount: int) -> Array:
	xp += maxi(amount, 0)
	while level < MAX_LEVEL and xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level += 1
	if level >= MAX_LEVEL:
		return [MAX_LEVEL, 0]
	return [level, xp]

# What killing a monster worth base_xp is worth to a hero, scaled by the level gap; never less than 1
static func kill_xp(base_xp: int, monster_level: int, hero_level: int, elite: bool) -> int:
	var scale := clampf(1.0 + LEVEL_GAP_SHARE * (monster_level - hero_level), GAP_FLOOR, GAP_CEILING)
	if elite:
		scale *= ELITE_MULTIPLIER
	return maxi(roundi(base_xp * scale), 1)

# Puts growth (Stats names to per-level amounts) on sheet for level, replacing any earlier growth
static func apply_growth(sheet: Stats, growth: Dictionary, level: int) -> void:
	sheet.clear_source(GROWTH_SOURCE)
	if level <= 1:
		return
	for stat: StringName in growth:
		sheet.add_modifier(GROWTH_SOURCE, StringName(stat), float(growth[stat]) * (level - 1))
