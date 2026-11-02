class_name HeroProgress
extends Node
# A hero's level, XP and runes. Kills (from Events.monster_killed) pay XP; a level grows the class's
# stats, heals, unlocks skills on the skill bar and sets off the fanfare. Runes are kept by skill id
# and put on the skill bar as rune-changed copies of the class's skills. hero.level and hero.xp stay
# the numbers everyone else reads; this is what changes them.

signal xp_changed(xp: int, needed: int)
signal levelled_up(level: int)
signal runes_changed

var hero: Hero
# Skill id -> rune id
var runes := {}
# The level before the last level-up, so a jump of several levels can list everything it unlocked
var level_before := 1

func _init(owner_hero: Hero) -> void:
	name = "Progress"
	hero = owner_hero

func _ready() -> void:
	Events.monster_killed.connect(_on_monster_killed)
	set_level(hero.level, hero.xp)

func _exit_tree() -> void:
	if Events.monster_killed.is_connected(_on_monster_killed):
		Events.monster_killed.disconnect(_on_monster_killed)

func _on_monster_killed(monster: Monster, _event: DamageEvent) -> void:
	if is_instance_valid(monster) and monster.def:
		gain_xp(Levels.kill_xp(monster.def.xp, monster.def.level, hero.level, monster.elite))

func gain_xp(amount: int) -> void:
	if not hero.alive or hero.level >= Levels.MAX_LEVEL:
		return
	var before := hero.level
	var after := Levels.add_xp(hero.level, hero.xp, amount)
	set_level(after[0], after[1])
	if hero.level > before:
		level_before = before
		hero.heal(hero.max_health())
		levelled_up.emit(hero.level)
		Events.hero_levelled_up.emit(hero, hero.level)
		if hero.is_inside_tree():
			hero.add_child(LevelUpBurst.new())

# Jumps straight to a level, quietly: for loading a save
func set_level(level: int, xp: int) -> void:
	hero.level = clampi(level, 1, Levels.MAX_LEVEL)
	hero.xp = clampi(xp, 0, maxi(Levels.xp_to_next(hero.level) - 1, 0))
	Levels.apply_growth(hero.stats, hero.hero_class.growth, hero.level)
	hero.skill_bar.level = hero.level
	xp_changed.emit(hero.xp, Levels.xp_to_next(hero.level))

# 0-1 through the current level; full at the cap
func fraction() -> float:
	var needed := Levels.xp_to_next(hero.level)
	return 1.0 if needed == 0 else float(hero.xp) / needed

# What reaching level brings: "New skill: Cleave", "New rune: Frenzy"
func unlocks_at(level: int) -> Array[String]:
	var found: Array[String] = []
	for skill in hero.hero_class.skills:
		if skill and skill.unlock_level == level and level > 1:
			found.append("New skill: %s" % skill.display_name)
	for skill in hero.hero_class.skills:
		if skill:
			for rune in RuneLibrary.runes_for(skill.id):
				if rune.unlock_level == level:
					found.append("New rune: %s" % rune.display_name)
	return found

# Everything unlocked by the levels after `from` up to and including `to`
func unlocks_between(from: int, to: int) -> Array[String]:
	var found: Array[String] = []
	for level in range(from + 1, to + 1):
		found.append_array(unlocks_at(level))
	return found

func rune_for(skill_id: StringName) -> RuneDef:
	return RuneLibrary.rune(skill_id, runes.get(skill_id, &""))

func has_skill(skill_id: StringName) -> bool:
	for skill in hero.hero_class.skills:
		if skill and skill.id == skill_id:
			return true
	return false

# Puts a rune on one of the hero's skills, or takes it off with an empty id. False (and nothing
# changed) for a rune that's locked, unknown or another skill's.
func set_rune(skill_id: StringName, rune_id: StringName) -> bool:
	if not has_skill(skill_id):
		return false
	if rune_id == &"":
		runes.erase(skill_id)
	else:
		var rune := RuneLibrary.rune(skill_id, rune_id)
		if rune == null or rune.unlock_level > hero.level:
			return false
		runes[skill_id] = rune_id
	refresh_skills()
	runes_changed.emit()
	return true

# The class's skills onto the skill bar, each with its rune if it has one
func refresh_skills() -> void:
	var skills := hero.hero_class.skills
	for i in mini(skills.size(), SkillBar.SLOTS):
		var skill := skills[i]
		var rune := rune_for(skill.id) if skill else null
		hero.skill_bar.set_skill(i, rune.apply(skill) if rune else skill)

func to_dict() -> Dictionary:
	var saved_runes := {}
	for skill_id: StringName in runes:
		saved_runes[String(skill_id)] = String(runes[skill_id])
	return {"level": hero.level, "xp": hero.xp, "runes": saved_runes}

# Restores a saved hero at full health. Anything out of range is clamped; unknown runes are dropped.
func load_dict(data: Dictionary) -> void:
	set_level(_int(data.get("level"), 1), _int(data.get("xp"), 0))
	runes.clear()
	var saved: Variant = data.get("runes", {})
	if saved is Dictionary:
		for skill_id: Variant in saved:
			var rune := RuneLibrary.rune(StringName(str(skill_id)), StringName(str(saved[skill_id])))
			if rune and has_skill(rune.skill) and rune.unlock_level <= hero.level:
				runes[rune.skill] = rune.id
	refresh_skills()
	runes_changed.emit()
	hero.health = hero.max_health()
	hero.health_changed.emit(hero.health, hero.max_health())

static func _int(value: Variant, fallback: int) -> int:
	return int(value) if value is int or value is float else fallback
