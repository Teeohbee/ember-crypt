extends Node
# The game's signal bus. Systems that shouldn't know about each other meet here: a monster dies and
# doesn't care who drops its loot, who hands out its XP or who counts the kill.

# Every hit that lands, after Combat has resolved it
signal damage_dealt(event: DamageEvent)
signal hero_spawned(hero: Hero)
signal hero_died(hero: Hero, event: DamageEvent)
signal monster_spawned(monster: Monster)
signal monster_killed(monster: Monster, event: DamageEvent)
signal skill_used(caster: Combatant, skill: SkillDef)
signal item_dropped(item: Item, at: Vector3, owner: PlayerSlot)
signal item_picked_up(item: Item, hero: Hero)
signal gold_picked_up(amount: int, hero: Hero)
signal checkpoint_reached(checkpoint: Checkpoint, hero: Hero)
signal zone_entered(zone: Zone)
