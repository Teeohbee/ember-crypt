class_name MoltenAffix
extends Node
# Molten: leaves a trail of burning pools as it walks, and bursts when it dies. Both are telegraphed on
# the floor, so the counterplay is to not stand there.

const BURN := preload("res://src/skills/monsters/molten_burn.tres")
const DROP_EVERY := 0.8
const POOL_RADIUS := 1.1
const POOL_SECONDS := 4.0
const BLAST_RADIUS := 3.2
const BLAST_WIND_UP := 1.4

var monster: Monster
var _since_drop := 0.0

func _init(owner_monster: Monster) -> void:
	name = "Molten"
	monster = owner_monster

func _ready() -> void:
	monster.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	if not monster.alive:
		return
	_since_drop += delta
	if _since_drop >= DROP_EVERY and monster.velocity.length_squared() > 0.25:
		_since_drop = 0.0
		monster.get_parent().add_child(Hazard.pool(monster, BURN, monster.global_position, POOL_RADIUS, POOL_SECONDS))

func _on_died(_event: DamageEvent) -> void:
	monster.get_parent().add_child(Hazard.blast(monster, BURN, monster.global_position, BLAST_RADIUS, BLAST_WIND_UP))
	Sound.play("telegraph", 0.8)
