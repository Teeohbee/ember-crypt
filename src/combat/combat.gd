class_name Combat
# Every hit goes through hit(): it resolves the numbers, applies them and hands the result to Feedback,
# so damage maths and hit feel each live in one place. resolve() is pure, so it's what the tests poke.

# The whole damage formula. rng is passed in so tests can seed it.
static func resolve(event: DamageEvent, attacker: Stats, defender: Stats, rng: RandomNumberGenerator) -> DamageEvent:
	var amount := event.amount
	event.crit = rng.randf() < attacker.value(Stats.CRIT_CHANCE)
	if event.crit:
		amount *= 1.0 + attacker.value(Stats.CRIT_DAMAGE)
	if event.kind == DamageEvent.Kind.PHYSICAL:
		var armour := maxf(defender.value(Stats.ARMOUR), 0.0)
		amount *= 100.0 / (100.0 + armour)
	else:
		amount *= 1.0 - clampf(defender.value(Stats.RESIST), 0.0, 0.75)
	event.amount = maxf(amount, 0.0)
	return event

# source hits target with skill for multiplier x the source's weapon damage. Returns the resolved
# event, or null if the target was already dead.
static func hit(source: Combatant, target: Combatant, skill: SkillDef, multiplier := -1.0) -> DamageEvent:
	if not is_instance_valid(target) or not target.alive:
		return null
	var event := DamageEvent.new()
	event.source = source
	event.target = target
	event.skill = skill
	if skill:
		event.kind = skill.damage_kind
		event.knockback = skill.knockback
		if multiplier < 0.0:
			multiplier = skill.damage_multiplier
	event.amount = source.stats.value(Stats.DAMAGE) * maxf(multiplier, 0.0)
	resolve(event, source.stats, target.stats, source.rng)
	target.take_hit(event)
	var life := source.stats.value(Stats.LIFE_ON_HIT)
	if life > 0.0 and source.alive:
		source.heal(life)
	Feedback.hit(event)
	return event
