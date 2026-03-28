extends Node

# Called by Multihelper after connect/host to load the base scene.
# Each peer calls this independently, so just execute locally — no RPC needed here.
func start_game() -> void:
	%MainMenu.queue_free()
	get_tree().paused = false
	_load_scene("res://scenes/base/Base.tscn")

# Called from Base when the host starts a match.
func start_field() -> void:
	if not multiplayer.is_server():
		return
	_load_scene.rpc("res://scenes/main/main.tscn")

# Called when a field match ends — all return to base.
func return_to_base() -> void:
	if not multiplayer.is_server():
		return
	_load_scene.rpc("res://scenes/base/Base.tscn")

@rpc("authority", "call_local", "reliable")
func _load_scene(path: String) -> void:
	var scene: PackedScene = load(path)
	change_level(scene)

func change_level(scene: PackedScene) -> void:
	var level: Node = %Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	level.add_child(scene.instantiate())
