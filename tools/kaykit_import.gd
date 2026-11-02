@tool
extends EditorScenePostImport
# Every KayKit .glb embeds its pack's whole texture atlas, so 200 dungeon pieces would mean 200 copies
# in VRAM. Embedded images are discarded on import (see [importer_defaults] in project.godot) and each
# mesh is pointed at its atlas's one shared material in assets/kaykit/materials/ instead. Weapons are
# .gltf files that already share an external png, so they're left alone.

func _post_import(scene: Node) -> Object:
	var material := _material_for(get_source_file())
	if material == null:
		return scene
	for mesh_instance: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			mesh.surface_set_material(surface, material)
	return scene

static func _material_for(source: String) -> Material:
	if not source.get_extension() == "glb":
		return null
	var atlas := ""
	if source.contains("/dungeon/"):
		atlas = "dungeon"
	elif source.contains("/skeletons/"):
		atlas = "skeleton"
	else:
		# Barbarian.glb -> barbarian, Rogue_Hooded.glb -> rogue
		atlas = source.get_file().get_basename().to_lower().get_slice("_", 0)
	return load("res://assets/kaykit/materials/%s.tres" % atlas)
