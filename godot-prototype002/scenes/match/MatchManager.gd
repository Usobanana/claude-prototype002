extends Node
# Server-authoritative match state machine.
# Manages the match timer, shrinking circle, and extraction point reveal.
# All timing decisions are made server-side and broadcast to clients via RPC.

signal phase_changed(phase_index: int)
signal circle_updated(center: Vector2, radius: float, damage_per_sec: float)
signal extraction_points_revealed()
signal match_ended()

var match_time_elapsed := 0.0
var is_match_running := false

# Circle state
var circle_center := Vector2.ZERO
var circle_initial_radius := 0.0
var circle_current_radius := 0.0
var circle_target_radius := 0.0
var circle_phase_index := -1
var circle_phase_elapsed := 0.0
var circle_damage_per_sec := 0.0

# Extraction
var extraction_revealed := false


func start_match(map_center: Vector2, map_radius: float) -> void:
	if not multiplayer.is_server():
		return
	circle_center = map_center
	circle_initial_radius = map_radius
	circle_current_radius = map_radius
	circle_target_radius = map_radius
	match_time_elapsed = 0.0
	circle_phase_index = -1
	circle_phase_elapsed = 0.0
	extraction_revealed = false
	is_match_running = true
	_sync_state.rpc(map_center, map_radius)


@rpc("authority", "call_local", "reliable")
func _sync_state(map_center: Vector2, map_radius: float) -> void:
	circle_center = map_center
	circle_initial_radius = map_radius
	circle_current_radius = map_radius
	is_match_running = true


func _process(delta: float) -> void:
	if not is_match_running or not multiplayer.is_server():
		return

	match_time_elapsed += delta

	# Reveal extraction points at 3 minutes
	if not extraction_revealed and match_time_elapsed >= Constants.EXTRACTION_REVEAL_TIME:
		extraction_revealed = true
		_reveal_extraction.rpc()

	# Advance circle phase
	_update_circle(delta)

	# Broadcast circle state every 0.5 seconds (avoid flooding)
	_broadcast_timer += delta
	if _broadcast_timer >= 0.5:
		_broadcast_timer = 0.0
		_sync_circle.rpc(circle_current_radius, circle_damage_per_sec, circle_phase_index)


var _broadcast_timer := 0.0


func _update_circle(delta: float) -> void:
	var phases: Array = Constants.CIRCLE_PHASES

	# Determine which phase we're in based on elapsed time
	var cumulative := 0.0
	var new_phase := -1
	for i in range(phases.size()):
		cumulative += phases[i]["duration"]
		if match_time_elapsed < cumulative:
			new_phase = i
			break

	if new_phase == -1:
		# All phases done — circle fully closed
		if is_match_running:
			is_match_running = false
			match_ended.emit()
			_on_match_ended.rpc()
		return

	# Phase transition
	if new_phase != circle_phase_index:
		circle_phase_index = new_phase
		circle_phase_elapsed = 0.0
		circle_target_radius = circle_initial_radius * phases[new_phase]["end_radius"]
		circle_damage_per_sec = phases[new_phase]["damage"]
		phase_changed.emit(circle_phase_index)
		_sync_phase.rpc(circle_phase_index, circle_target_radius, circle_damage_per_sec)

	# Lerp current radius toward target over the phase duration
	circle_phase_elapsed += delta
	var phase_duration: float = phases[new_phase]["duration"]
	var t := clampf(circle_phase_elapsed / phase_duration, 0.0, 1.0)
	circle_current_radius = lerpf(
		circle_initial_radius * (phases[max(0, new_phase - 1)]["end_radius"] if new_phase > 0 else 1.0),
		circle_target_radius,
		t
	)
	circle_updated.emit(circle_center, circle_current_radius, circle_damage_per_sec)


@rpc("authority", "call_local", "reliable")
func _reveal_extraction() -> void:
	extraction_revealed = true
	extraction_points_revealed.emit()


@rpc("authority", "call_local", "reliable")
func _sync_phase(phase_idx: int, target_radius: float, damage: float) -> void:
	circle_phase_index = phase_idx
	circle_target_radius = target_radius
	circle_damage_per_sec = damage
	phase_changed.emit(phase_idx)


@rpc("authority", "call_local", "unreliable")
func _sync_circle(radius: float, damage: float, phase_idx: int) -> void:
	circle_current_radius = radius
	circle_damage_per_sec = damage
	circle_phase_index = phase_idx
	circle_updated.emit(circle_center, radius, damage)


@rpc("authority", "call_local", "reliable")
func _on_match_ended() -> void:
	is_match_running = false
	match_ended.emit()


func is_position_inside_circle(world_pos: Vector2) -> bool:
	return world_pos.distance_to(circle_center) <= circle_current_radius


func get_remaining_seconds() -> float:
	return maxf(0.0, Constants.MATCH_DURATION - match_time_elapsed)


func get_phase_name() -> String:
	match circle_phase_index:
		0: return "Phase 1"
		1: return "Phase 2"
		2: return "Phase 3"
		3: return "Phase 4"
		_: return "Waiting"
