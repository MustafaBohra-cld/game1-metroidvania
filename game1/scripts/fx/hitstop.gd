class_name HitStop
extends RefCounted
## HitStop — FX module. Brief time freeze on hit land for impact feel.
## Static helper: HitStop.freeze(get_tree(), 0.05, 0.1)
## Works with Engine.time_scale. Fire-and-forget (does not block caller).


static func freeze(tree: SceneTree, duration: float = 0.05, time_scale: float = 0.1) -> void:
	if tree == null:
		return
	Engine.time_scale = time_scale
	await tree.create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
