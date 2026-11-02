class_name Hero
extends Combatant
# A player's hero: the class's model, its stat sheet, skill bar, bags and gear, all driven by one
# PlayerSlot. Behaviour is split into parts so milestones don't trip over each other: HeroMotor moves,
# SkillBar fights, Inventory and Equipment hold loot. This file just wires them to the slot's input.

const SKILL_ACTIONS: Array[StringName] = [&"skill_1", &"skill_2", &"skill_3", &"skill_4", &"skill_5", &"skill_6"]

var slot: PlayerSlot
var hero_class: HeroClass
var model: HeroModel
var motor: HeroMotor
var skill_bar: SkillBar
var potion: Potion
var progress: HeroProgress
var inventory := Inventory.new()
var equipment: Equipment
# Loot underfoot: gold scooped up, items picked up on A (M4)
var pickup: HeroPickup
var level := 1
var xp := 0

func _init(chosen: HeroClass, player_slot: PlayerSlot) -> void:
	team = Team.HEROES
	hero_class = chosen
	slot = player_slot
	name = "Hero%d" % player_slot.index
	stats = Stats.new(chosen.base_stats)
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	model = HeroModel.new(chosen)
	add_child(model)
	motor = HeroMotor.new(self)
	skill_bar = SkillBar.new(self)
	for i in mini(chosen.skills.size(), SkillBar.SLOTS):
		skill_bar.set_skill(i, chosen.skills[i])
	add_child(skill_bar)
	potion = Potion.new(self)
	add_child(potion)
	progress = HeroProgress.new(self)
	add_child(progress)
	equipment = Equipment.new(stats)
	equipment.changed.connect(_show_gear)
	StartingGear.give(chosen.id, equipment)
	pickup = HeroPickup.new(self)

func _ready() -> void:
	super()
	slot.hero = self
	power = hero_class.starting_power
	Events.hero_spawned.emit(self)

func _physics_process(delta: float) -> void:
	if not alive:
		return
	motor.physics_step(delta)
	if slot.just_pressed(&"potion") and not potion.drink():
		Sound.play("denied")
	if motor.rolling:
		return
	var picking_up := pickup.physics_step()
	if not picking_up and slot.just_pressed(SKILL_ACTIONS[0]) and _interact():
		return
	for i in SKILL_ACTIONS.size():
		if i == 0 and picking_up:
			continue
		if slot.pressed(SKILL_ACTIONS[i]) and skill_bar.can_use(i):
			skill_bar.use(i, aim_direction())
			break

# A uses whatever is in reach (a waypoint, the stash) when nothing hostile is close (M6)
func _interact() -> bool:
	var found := Interactable.find_for(self)
	if found:
		found.use(self)
	return found != null

# Where the player is pointing: the left stick if held, otherwise the way the hero faces
func aim_direction() -> Vector3:
	var stick := slot.move_vector()
	return Vector3(stick.x, 0, stick.y).normalized() if stick.length() > 0.1 else facing()

# Weapons and shields show in the hands; the rest of the gear has no model
func _show_gear(gear_slot: ItemBase.Slot, item: Item) -> void:
	if gear_slot == ItemBase.Slot.WEAPON or gear_slot == ItemBase.Slot.OFFHAND:
		var hand: String = item.base.hand_bone if item else HeroModel.HAND_SLOTS[0 if gear_slot == ItemBase.Slot.WEAPON else 1]
		model.hold(hand, item.base if item else null)

func play_skill_animation(skill: SkillDef, speed: float) -> void:
	if skill.animation != "":
		model.play(skill.animation, 0.08)
		model.animations.speed_scale = speed

func _on_hurt(_event: DamageEvent) -> void:
	if not skill_bar.busy and alive:
		model.play("Hit_A", 0.05)

func _on_died(event: DamageEvent) -> void:
	model.play("Death_A", 0.1, true)
	Events.hero_died.emit(self, event)

func revive() -> void:
	super()
	model.idle()
