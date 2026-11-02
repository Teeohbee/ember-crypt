class_name StatText
# How stats read on an item card or the character sheet: "+12 Armour", "+3% Critical Hit Chance".
# Some stats are fractions (0.05 is 5%), so they show as percents even as flat modifiers.

const NAMES := {
	Stats.DAMAGE: "Damage", Stats.MAX_HEALTH: "Life", Stats.HEALTH_REGEN: "Life per Second",
	Stats.ARMOUR: "Armour", Stats.RESIST: "Resistance", Stats.ATTACK_SPEED: "Attack Speed",
	Stats.CRIT_CHANCE: "Critical Hit Chance", Stats.CRIT_DAMAGE: "Critical Hit Damage",
	Stats.MOVE_SPEED: "Movement Speed", Stats.COOLDOWN_REDUCTION: "Cooldown Reduction",
	Stats.LIFE_ON_HIT: "Life per Hit", Stats.MAX_POWER: "Maximum Power", Stats.POWER_REGEN: "Power per Second",
	Stats.MAGIC_FIND: "Magic Find", Stats.GOLD_FIND: "Gold Find",
}

const FRACTIONS: Array[StringName] = [Stats.CRIT_CHANCE, Stats.CRIT_DAMAGE, Stats.RESIST,
	Stats.COOLDOWN_REDUCTION, Stats.MAGIC_FIND, Stats.GOLD_FIND]

static func stat_name(stat: StringName) -> String:
	return NAMES.get(stat, String(stat).capitalize())

static func is_fraction(stat: StringName) -> bool:
	return stat in FRACTIONS

# One modifier as words. signed puts a + on gains (affixes, deltas); base stats read plain ("6 Damage").
static func line(stat: StringName, flat: float, percent: float, signed := true) -> String:
	var amount := flat
	var suffix := ""
	if percent != 0.0:
		amount = percent * 100.0
		suffix = "%"
	elif is_fraction(stat):
		amount = flat * 100.0
		suffix = "%"
	var plus := ("+" if amount >= 0.0 else "-") if signed else ("" if amount >= 0.0 else "-")
	return "%s%s%s %s" % [plus, number(absf(amount)), suffix, stat_name(stat)]

# A stat's total for the character sheet: "14", "5%", "1.1 per second" reads as "1.1"
static func total(stat: StringName, value: float) -> String:
	if is_fraction(stat):
		return number(value * 100.0) + "%"
	return number(value)

static func number(amount: float) -> String:
	if absf(amount - roundf(amount)) < 0.05:
		return "%d" % roundi(amount)
	return "%.1f" % amount
