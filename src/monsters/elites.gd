class_name Elites
# Turning an ordinary monster into a named elite: much tougher, harder hitting, bigger, glowing, with a
# name plate and one or more affixes. Rolls take an RNG so they're seeded in tests and repeatable.

const AFFIXES: Array[EliteAffixDef] = [
	preload("res://src/monsters/affixes/fast.tres"),
	preload("res://src/monsters/affixes/extra_health.tres"),
	preload("res://src/monsters/affixes/vampiric.tres"),
	preload("res://src/monsters/affixes/molten.tres"),
	preload("res://src/monsters/affixes/shielding.tres"),
]
const SOURCE := &"elite"
const HEALTH_BONUS := 2.0     # +200%
const DAMAGE_BONUS := 0.4
const SCALE := 1.2

const NAMES := ["Grimjaw", "Marrowgast", "Sepulchra", "Vexbone", "Hollowmere", "Rattlecrown", "Ashmaw",
	"Cindertooth", "Gravewick", "Mournhusk", "Ossuin", "Knell"]
const EPITHETS := ["the Unburied", "the Hollow", "Bonegnasher", "the Restless", "of the Deep Crypt",
	"Grave-Warden", "the Rotting", "Skullsplitter", "the Forsworn", "Tombcaller"]

# count different affixes, picked at random
static func roll_affixes(rng: RandomNumberGenerator, count: int) -> Array[EliteAffixDef]:
	var pool := AFFIXES.duplicate()
	var picked: Array[EliteAffixDef] = []
	for i in mini(count, pool.size()):
		picked.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return picked

static func roll_name(rng: RandomNumberGenerator) -> String:
	return "%s %s" % [NAMES[rng.randi_range(0, NAMES.size() - 1)], EPITHETS[rng.randi_range(0, EPITHETS.size() - 1)]]

static func find(id: StringName) -> EliteAffixDef:
	for affix in AFFIXES:
		if affix.id == id:
			return affix
	return null

# Makes monster an elite called title with affixes. Safe before or after it enters the tree.
static func promote(monster: Monster, affixes: Array[EliteAffixDef], title: String) -> void:
	monster.elite = true
	monster.affixes.clear()
	monster.stats.add_modifier(SOURCE, Stats.MAX_HEALTH, 0.0, HEALTH_BONUS)
	monster.stats.add_modifier(SOURCE, Stats.DAMAGE, 0.0, DAMAGE_BONUS)
	for affix in affixes:
		monster.affixes.append(affix.id)
		var source := StringName("affix:%s" % affix.id)
		for stat: StringName in affix.percent:
			monster.stats.add_modifier(source, stat, 0.0, affix.percent[stat])
		for stat: StringName in affix.flat:
			monster.stats.add_modifier(source, stat, affix.flat[stat])
		if affix.behaviour:
			monster.add_child(affix.behaviour.new(monster))
	monster.health = monster.max_health()
	monster.health_changed.emit(monster.health, monster.max_health())
	monster.model.scale *= SCALE
	var glow := OmniLight3D.new()
	glow.name = "EliteGlow"
	glow.light_color = affixes[0].colour if not affixes.is_empty() else UiTheme.GOLD
	glow.light_energy = 1.4
	glow.omni_range = 3.0
	glow.position = Vector3(0, 0.6, 0)
	monster.add_child(glow)
	var lines := PackedStringArray()
	for affix in affixes:
		lines.append(affix.display_name)
	monster.add_child(NamePlate.new(monster, title, ", ".join(lines)))
