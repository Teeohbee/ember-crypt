class_name Monster
extends Combatant
# A monster in the world: its def's model and stats, flinching when hit and falling when killed. It has
# no mind of its own here; its MonsterBrain drives it through skill_bar and velocity.

const CORPSE_SECONDS := 4.0

var def: MonsterDef
var model: Node3D
var animations: AnimationPlayer
var skill_bar: SkillBar
var brain: MonsterBrain
var elite := false
var affixes: Array[StringName] = []
var _holding := false

func _init(monster_def: MonsterDef) -> void:
	team = Team.MONSTERS
	def = monster_def
	name = String(def.id).to_pascal_case()
	stats = Stats.new(def.base_stats)
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45 * def.scale
	capsule.height = 1.8 * def.scale
	shape.shape = capsule
	shape.position.y = 0.9 * def.scale
	add_child(shape)
	model = def.model.instantiate()
	model.scale = Vector3.ONE * def.scale
	add_child(model)
	animations = model.find_child("AnimationPlayer", true, false)
	for slot in HeroModel.HAND_SLOTS:
		var bone := model.find_child(slot, true, false)
		if bone:
			for prop in bone.get_children():
				if not prop.name in def.held:
					prop.free()
	_arm(def.weapon_right, "handslot.r")
	_arm(def.weapon_left, "handslot.l")
	for looping in [def.idle_animation, def.walk_animation, def.run_animation]:
		if animations.has_animation(looping):
			animations.get_animation(looping).loop_mode = Animation.LOOP_LINEAR
	skill_bar = SkillBar.new(self)
	for i in mini(def.skills.size(), SkillBar.SLOTS):
		skill_bar.set_skill(i, def.skills[i])
	add_child(skill_bar)
	brain = MonsterBrain.new(self)
	add_child(brain)

func _ready() -> void:
	super()
	play(def.idle_animation)
	animations.seek(randf() * animations.current_animation_length, true)
	animations.animation_finished.connect(func(finished: StringName) -> void:
		if alive and not _holding and finished != StringName(def.idle_animation):
			play(def.idle_animation))
	Events.monster_spawned.emit(self)

# Shields and elite affixes soften a hit before the usual bookkeeping
func take_hit(event: DamageEvent) -> void:
	if alive:
		brain.mitigate(event)
	super(event)

# KayKit skeletons come empty-handed; weapons ride a BoneAttachment3D on the hand slot bone
func _arm(weapon: PackedScene, bone: String) -> void:
	var rig: Skeleton3D = model.find_child("Skeleton3D", true, false)
	if weapon == null or rig == null or rig.find_bone(bone) < 0:
		return
	var attachment := BoneAttachment3D.new()
	attachment.name = bone.replace(".", "_")
	attachment.bone_name = bone
	rig.add_child(attachment)
	attachment.add_child(weapon.instantiate())

func play(animation: String, blend := 0.15, hold := false) -> void:
	_holding = hold
	if animations.has_animation(animation):
		animations.play(animation, blend)

func play_skill_animation(skill: SkillDef, speed: float) -> void:
	play(skill.animation, 0.08)
	animations.speed_scale = speed

func _on_hurt(_event: DamageEvent) -> void:
	if alive and not skill_bar.busy:
		play(def.hit_animation, 0.05)

func _on_died(event: DamageEvent) -> void:
	animations.speed_scale = 1.0
	play(def.death_animation, 0.1, true)
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	Events.monster_killed.emit(self, event)
	get_tree().create_timer(CORPSE_SECONDS, false).timeout.connect(queue_free)
