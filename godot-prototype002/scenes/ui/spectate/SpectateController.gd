extends CanvasLayer
# Spectate mode controller.
# Activated on the local client when their player dies.
# Cycles through alive teammates using Left/Right arrow keys.
#
# Editor setup (create SpectateController.tscn):
#   CanvasLayer
#   ├── Camera2D  ← $SpectateCamera  (enabled = false initially)
#   └── Label     ← $WatchingLabel   ("Watching: [name]")

@onready var spectate_camera: Camera2D = $SpectateCamera
@onready var watching_label: Label = $WatchingLabel

var _targets: Array = []      # list of alive player nodes
var _target_index: int = 0
var _active: bool = false


func activate() -> void:
	_active = true
	visible = true
	spectate_camera.enabled = true
	_refresh_targets()
	_focus_current()


func deactivate() -> void:
	_active = false
	visible = false
	spectate_camera.enabled = false


func _process(_delta: float) -> void:
	if not _active:
		return
	if Input.is_action_just_pressed("ui_left"):
		_prev_target()
	elif Input.is_action_just_pressed("ui_right"):
		_next_target()
	# Follow current target
	if _targets.size() > 0 and _target_index < _targets.size():
		var t: Node = _targets[_target_index]
		if is_instance_valid(t):
			spectate_camera.global_position = t.global_position
		else:
			_refresh_targets()


func _refresh_targets() -> void:
	_targets.clear()
	var players_node := get_tree().get_first_node_in_group("players_container")
	if players_node == null:
		return
	for p in players_node.get_children():
		if p.is_in_group("player") and is_instance_valid(p):
			_targets.append(p)
	_target_index = clampi(_target_index, 0, maxi(0, _targets.size() - 1))


func _focus_current() -> void:
	if _targets.is_empty():
		watching_label.text = "全員死亡"
		return
	var t: Node = _targets[_target_index]
	watching_label.text = "観戦中: %s" % t.get("playerName")


func _next_target() -> void:
	if _targets.is_empty():
		return
	_target_index = (_target_index + 1) % _targets.size()
	_focus_current()


func _prev_target() -> void:
	if _targets.is_empty():
		return
	_target_index = (_target_index - 1 + _targets.size()) % _targets.size()
	_focus_current()
