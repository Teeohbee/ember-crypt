extends KitSuite
# The Mage's kit past Magic Missile: Frost Nova chills everything close, Arcane Orb drifts out and
# bursts on the first thing it meets, Teleport blinks out of trouble.

const FROST_NOVA := "res://src/skills/mage/frost_nova.tres"
const ARCANE_ORB := "res://src/skills/mage/arcane_orb.tres"
const TELEPORT := "res://src/skills/mage/teleport.tres"

func test_frost_nova_hurts_and_chills_everything_close() -> void:
	var mage := caster()
	var close := monster(Vector3(2, 0, 1))
	var far := monster(Vector3(0, 0, -12))
	var speed_before := close.stats.value(Stats.MOVE_SPEED)
	fire(skill(FROST_NOVA), mage)
	assert_bool(hurt(close)).is_true()
	assert_float(close.stats.value(Stats.MOVE_SPEED)).is_less(speed_before)
	assert_bool(hurt(far)).is_false()
	assert_bool(Statuses.of(far).has(&"chill")).is_false()

func test_frost_nova_is_cold() -> void:
	assert_int(skill(FROST_NOVA).damage_kind).is_equal(DamageEvent.Kind.COLD)

func _orb() -> ArcaneOrb:
	# A burst orb from an earlier test may not have been freed yet
	for orb: ArcaneOrb in find_children("*", "ArcaneOrb", false, false):
		if not orb.is_queued_for_deletion():
			return orb
	return null

func test_arcane_orb_bursts_on_the_first_thing_it_meets() -> void:
	var mage := caster()
	var first := monster(Vector3(0, 0, -6))
	var neighbour := monster(Vector3(1.5, 0, -7))
	var beyond := monster(Vector3(0, 0, -13))
	fire(skill(ARCANE_ORB), mage)
	var orb := _orb()
	assert_object(orb).is_not_null()
	assert_bool(hurt(first)).is_false()
	step(orb, 3.0)
	assert_bool(hurt(first)).is_true()
	assert_bool(hurt(neighbour)).is_true()
	assert_bool(hurt(beyond)).is_false()
	assert_bool(orb.burst).is_true()

func test_arcane_orb_bursts_at_the_end_of_its_range() -> void:
	var mage := caster()
	var orb_skill := skill(ARCANE_ORB)
	fire(orb_skill, mage, Vector3.RIGHT)
	var orb := _orb()
	var straggler := monster(Vector3(orb_skill.params.range + 0.8, 0, 0))
	step(orb, orb_skill.params.range / orb_skill.params.speed + 0.2)
	assert_bool(orb.burst).is_true()
	assert_bool(hurt(straggler)).is_true()

func test_teleport_blinks_along_the_aim() -> void:
	var mage := caster()
	var teleport := skill(TELEPORT)
	fire(teleport, mage, Vector3.LEFT)
	assert_vector(mage.global_position).is_equal_approx(Vector3(-teleport.params.distance, 0, 0), Vector3.ONE * 0.05)
