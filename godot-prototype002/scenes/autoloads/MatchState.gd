extends Node
# Per-match player state: XP, level, active/passive skill slots, insurance slot.
# Server-authoritative. Replaces the old Inventory.gd for match-duration data.

signal xp_gained(player_id: int, xp: int, total_xp: int)
signal level_up(player_id: int, new_level: int, options: Array)
signal skill_applied(player_id: int, skill_id: String)
signal state_updated(player_id: int)

# { player_id: { xp, level, active_skills[3], passive_skills[2], insurance_slot } }
var states: Dictionary = {}


func register_player(player_id: int, player_class: String) -> void:
	if not multiplayer.is_server():
		return
	var base_skills: Dictionary = GameData.class_base_skills.get(player_class, {})
	states[player_id] = {
		"xp": 0,
		"level": 1,
		"player_class": player_class,
		"active_skills": base_skills.get("active", ["", "", ""]).duplicate(),
		"passive_skills": base_skills.get("passive", ["", ""]).duplicate(),
		"insurance_slot": "",
		"extracted": false,
	}
	_sync_state.rpc_id(player_id, player_id, states[player_id])


func unregister_player(player_id: int) -> void:
	states.erase(player_id)


func set_insurance_slot(player_id: int, item_id: String) -> void:
	if player_id in states:
		states[player_id]["insurance_slot"] = item_id


func add_xp(player_id: int, amount: int) -> void:
	if not multiplayer.is_server():
		return
	if player_id not in states:
		return

	var s: Dictionary = states[player_id]
	if s["level"] >= Constants.MAX_MATCH_LEVEL:
		return

	s["xp"] += amount
	xp_gained.emit(player_id, amount, s["xp"])
	_rpc_xp_update.rpc_id(player_id, s["xp"], s["level"])

	# Check for level up
	var thresholds: Array = Constants.XP_THRESHOLDS
	while s["level"] < Constants.MAX_MATCH_LEVEL and s["xp"] >= thresholds[s["level"]]:
		s["level"] += 1
		var options: Array = GameData.get_levelup_options(
			s["player_class"],
			s["active_skills"] + s["passive_skills"]
		)
		level_up.emit(player_id, s["level"], options)
		_rpc_level_up.rpc_id(player_id, s["level"], options)


func apply_skill(player_id: int, skill_id: String) -> void:
	if not multiplayer.is_server():
		return
	if player_id not in states or skill_id not in GameData.skills:
		return

	var s: Dictionary = states[player_id]
	var skill: Dictionary = GameData.skills[skill_id]

	match skill["type"]:
		"active_replace":
			var slot: int = skill["slot"]
			if slot >= 0 and slot < s["active_skills"].size():
				s["active_skills"][slot] = skill_id
		"active_enhance":
			var slot: int = skill["slot"]
			if slot >= 0 and slot < s["active_skills"].size():
				s["active_skills"][slot] = skill_id
		"passive":
			var slot: int = skill["slot"]
			if slot >= 0 and slot < s["passive_skills"].size():
				s["passive_skills"][slot] = skill_id
		"stat_boost":
			pass  # Stat boosts are handled by player.gd listening to skill_applied

	skill_applied.emit(player_id, skill_id)
	_rpc_skill_applied.rpc_id(player_id, skill_id, s["active_skills"], s["passive_skills"])


func mark_extracted(player_id: int) -> void:
	if player_id in states:
		states[player_id]["extracted"] = true


func get_state(player_id: int) -> Dictionary:
	return states.get(player_id, {})


# ---------------------------------------------------------------------------
# RPCs — server → client sync
# ---------------------------------------------------------------------------
@rpc("authority", "call_local", "reliable")
func _sync_state(player_id: int, data: Dictionary) -> void:
	states[player_id] = data
	state_updated.emit(player_id)


@rpc("authority", "call_local", "reliable")
func _rpc_xp_update(xp: int, level: int) -> void:
	var pid := multiplayer.get_remote_sender_id() if not multiplayer.is_server() else 1
	# Caller's own state update; find by context
	state_updated.emit(multiplayer.get_unique_id())
	# We keep local xp/level in our own state entry; update it
	var my_id := multiplayer.get_unique_id()
	if my_id in states:
		states[my_id]["xp"] = xp
		states[my_id]["level"] = level


@rpc("authority", "call_local", "reliable")
func _rpc_level_up(new_level: int, options: Array) -> void:
	var my_id := multiplayer.get_unique_id()
	if my_id in states:
		states[my_id]["level"] = new_level
	level_up.emit(my_id, new_level, options)


@rpc("authority", "call_local", "reliable")
func _rpc_skill_applied(skill_id: String, active_skills: Array, passive_skills: Array) -> void:
	var my_id := multiplayer.get_unique_id()
	if my_id in states:
		states[my_id]["active_skills"] = active_skills
		states[my_id]["passive_skills"] = passive_skills
	skill_applied.emit(my_id, skill_id)
