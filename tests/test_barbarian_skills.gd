extends KitSuite
# The Barbarian's kit past Bash: Cleave sweeps an arc, Leap crashes down on a target, War Cry hardens
# the war band and stokes Fury.

const CLEAVE := "res://src/skills/barbarian/cleave.tres"
const LEAP := "res://src/skills/barbarian/leap.tres"
const WAR_CRY := "res://src/skills/barbarian/war_cry.tres"

func test_cleave_hits_everything_in_the_arc_and_nothing_behind() -> void:
	var barbarian := caster()
	var ahead := monster(Vector3(0, 0, -2))
	var aside := monster(Vector3(1.6, 0, -1))
	var behind := monster(Vector3(0, 0, 2))
	fire(skill(CLEAVE), barbarian)
	assert_bool(hurt(ahead)).is_true()
	assert_bool(hurt(aside)).is_true()
	assert_bool(hurt(behind)).is_false()

func test_cleave_costs_fury() -> void:
	assert_float(skill(CLEAVE).cost).is_greater(0.0)

func test_leap_lands_by_the_target_and_hits_around_it() -> void:
	var barbarian := caster()
	var target := monster(Vector3(0, 0, -6))
	var neighbour := monster(Vector3(1.5, 0, -6.5))
	var far := monster(Vector3(0, 0, -14))
	fire(skill(LEAP), barbarian, Vector3.FORWARD, target)
	var flight: Node = barbarian.get_node("LeapFlight")
	step(flight, 2.0)
	assert_float(barbarian.global_position.distance_to(target.global_position)).is_less(2.0)
	assert_float(barbarian.global_position.y).is_equal_approx(0.0, 0.01)
	assert_bool(hurt(target)).is_true()
	assert_bool(hurt(neighbour)).is_true()
	assert_bool(hurt(far)).is_false()

func test_leap_with_nothing_in_reach_jumps_ahead() -> void:
	var barbarian := caster()
	var leap := skill(LEAP)
	fire(leap, barbarian, Vector3.RIGHT)
	step(barbarian.get_node("LeapFlight"), 2.0)
	assert_float(barbarian.global_position.x).is_equal_approx(leap.params.distance, 0.05)

func test_leap_doesnt_hurt_before_it_lands() -> void:
	var barbarian := caster()
	var target := monster(Vector3(0, 0, -6))
	fire(skill(LEAP), barbarian, Vector3.FORWARD, target)
	step(barbarian.get_node("LeapFlight"), 0.1)
	assert_bool(hurt(target)).is_false()

func test_war_cry_hardens_the_caster_and_allies_nearby() -> void:
	var barbarian := caster()
	var ally := caster()
	ally.position = Vector3(3, 0, 0)
	var armour_before := barbarian.stats.value(Stats.ARMOUR)
	fire(skill(WAR_CRY), barbarian)
	assert_float(barbarian.stats.value(Stats.ARMOUR)).is_greater(armour_before)
	assert_bool(Statuses.of(ally).has(&"war_cry")).is_true()

func test_war_cry_stokes_fury() -> void:
	var barbarian := caster()
	barbarian.power = 0.0
	fire(skill(WAR_CRY), barbarian)
	assert_float(barbarian.power).is_greater(0.0)

func test_war_cry_wears_off() -> void:
	var barbarian := caster()
	var armour_before := barbarian.stats.value(Stats.ARMOUR)
	var war_cry := skill(WAR_CRY)
	fire(war_cry, barbarian)
	Statuses.of(barbarian).tick(war_cry.params.seconds + 0.1)
	assert_float(barbarian.stats.value(Stats.ARMOUR)).is_equal(armour_before)
