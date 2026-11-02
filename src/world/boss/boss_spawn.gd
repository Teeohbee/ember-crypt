class_name BossSpawn
extends SpawnPoint
# Where the boss waits. It spawns the boss with its own brain instead of a pack, and when the boss
# falls a waypoint opens where it stood, so the way home is right there.

const BOSS := &"skeleton_lord"

var waypoint_zone := "crypt"

func _init() -> void:
	name = "BossSpawn"
	elite_chance = 0.0

func spawn() -> Array[Monster]:
	var parent := get_parent() as Node3D
	var boss := MonsterLibrary.spawn(BOSS, parent, global_position)
	if boss == null:
		return []
	boss.face(Vector3.BACK)
	var brain := BossBrain.new(boss)
	if parent is Zone:
		brain.return_music = parent.music
		waypoint_zone = parent.id
	boss.add_child(brain)
	boss.died.connect(func(_event: DamageEvent) -> void: _open_way_home.call_deferred())
	var spawned: Array[Monster] = [boss]
	return spawned

func _open_way_home() -> void:
	if not is_inside_tree():
		return
	var waypoint := Waypoint.new(waypoint_zone)
	waypoint.position = position + Vector3(0, 0, 3)
	get_parent().add_child(waypoint)
