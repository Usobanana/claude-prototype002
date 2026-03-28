extends Node
# Reusable channeling component.
# Attach to any node that needs a timed-hold interaction (extraction, revive, finish-off).
# The parent node drives start/cancel; this node tracks the timer and fires signals.
#
# Interruption:
#   Set interrupt_group to a group name (e.g. "player", "enemy").
#   Any node in that group entering the interrupt_area will cancel the channel.
#   If interrupt_area is null, no automatic interruption occurs.

signal channel_completed()
signal channel_interrupted()
signal channel_progress(ratio: float)  # 0.0 to 1.0

@export var channel_time: float = 5.0
@export var interrupt_group: String = ""

# Assign an Area2D node on the parent that detects interruptors.
# Leave null to disable automatic interruption.
var interrupt_area: Area2D = null

var _elapsed: float = 0.0
var _active: bool = false
var _channeler_id: int = -1  # peer id of the player channeling


func start_channel(channeler_id: int) -> void:
	_elapsed = 0.0
	_active = true
	_channeler_id = channeler_id
	if interrupt_area and not interrupt_area.body_entered.is_connected(_on_interruptor_entered):
		interrupt_area.body_entered.connect(_on_interruptor_entered)


func cancel_channel() -> void:
	if _active:
		_active = false
		channel_interrupted.emit()


func is_active() -> bool:
	return _active


func get_channeler_id() -> int:
	return _channeler_id


func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	var ratio := clampf(_elapsed / channel_time, 0.0, 1.0)
	channel_progress.emit(ratio)

	if _elapsed >= channel_time:
		_active = false
		channel_completed.emit()


func _on_interruptor_entered(body: Node) -> void:
	if not _active:
		return
	if interrupt_group == "":
		return
	# Only interrupt if the body is NOT the channeler themselves
	if body.is_in_group(interrupt_group) and str(body.name) != str(_channeler_id):
		cancel_channel()
