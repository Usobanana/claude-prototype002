extends CharacterBody2D

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal mob_killed()
signal player_killed()

# ---------------------------------------------------------------------------
# Exports / identity
# ---------------------------------------------------------------------------
@export var playerName: String:
	set(value):
		playerName = value
		if is_node_ready():
			$PlayerUi.setPlayerName(value)

@export var characterFile: String:
	set(value):
		characterFile = value
		if is_node_ready():
			$MovingParts/Sprite2D.texture = load("res://assets/characters/bodies/" + value)

# ---------------------------------------------------------------------------
# Class & stats
# ---------------------------------------------------------------------------
var player_class: String = "warrior":
	set(value):
		player_class = value
		_apply_class_stats()

@export var maxHP: float = 300.0
@export var hp: float = maxHP:
	set(value):
		hp = value
		if is_node_ready():
			$bloodParticles.emitting = true
			$PlayerUi.setHPBarRatio(hp / maxHP)
		if hp <= 0.0 and not is_downed and not _dying:
			enter_downed_state()

@export var speed: float = 200.0
@export var attackDamage: float = 30.0
var weapon_type: String = "sword"
var damage_reduction: float = 0.0   # 0.0–1.0 from passive skills
var damage_bonus: float = 0.0       # multiplier bonus from skills

# ---------------------------------------------------------------------------
# Down state
# ---------------------------------------------------------------------------
var is_downed: bool = false
var _downed_hp: float = 100.0       # drains over DOWN_DRAIN_TIME seconds
var _downed_timer: float = 0.0
var _dying: bool = false            # prevents re-entrant die()

# Revive channeling (active channel node; target tracked by ExtractionPoint)
var _revive_channel: Node = null

# ---------------------------------------------------------------------------
# Skill state
# ---------------------------------------------------------------------------
var active_skills: Array = ["", "", ""]   # skill IDs in slots 0/1/2
var passive_skills: Array = ["", ""]
var _attack_cooldown_remaining: float = 0.0

# ---------------------------------------------------------------------------
# Extraction channeling (managed by ExtractionPoint; we just track it here
# so that taking damage can interrupt it)
# ---------------------------------------------------------------------------
var _extraction_point_ref: Node = null

# ---------------------------------------------------------------------------
# Circle damage tracking
# ---------------------------------------------------------------------------
var _circle_damage_accum: float = 0.0

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	add_to_group("player")
	add_to_group("damageable")
	if multiplayer.is_server():
		mob_killed.connect(_on_mob_killed)
		player_killed.connect(_on_player_killed)
		MatchManager.circle_updated.connect(_on_circle_updated)
	if name == str(multiplayer.get_unique_id()):
		$Camera2D.enabled = true
		MatchState.level_up.connect(_on_level_up)
		MatchState.skill_applied.connect(_on_skill_applied)
	Multihelper.player_disconnected.connect(_on_disconnected)


func _apply_class_stats() -> void:
	if player_class not in GameData.classes:
		return
	var c: Dictionary = GameData.classes[player_class]
	maxHP = c["base_hp"]
	hp = maxHP
	speed = c["base_speed"]
	attackDamage = c["base_damage"]
	weapon_type = c["weapon"]


# ---------------------------------------------------------------------------
# Process
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	_attack_cooldown_remaining = maxf(0.0, _attack_cooldown_remaining - delta)

	if str(multiplayer.get_unique_id()) != name:
		return

	if is_downed:
		_process_downed_input(delta)
		return

	var vel := Input.get_vector("walkLeft", "walkRight", "walkUp", "walkDown") * speed
	var mouse_pos := get_global_mouse_position()
	var angle := (mouse_pos - global_position).angle()
	var doing_action := Input.is_action_pressed("leftClickAction")

	# Skill input
	var skill_slot := -1
	if Input.is_action_just_pressed("skill_1"):
		skill_slot = 0
	elif Input.is_action_just_pressed("skill_2"):
		skill_slot = 1
	elif Input.is_action_just_pressed("skill_3"):
		skill_slot = 2

	# Interaction (revive / finish-off)
	var interacting := Input.is_action_pressed("interact")

	moveProcess(vel, angle, doing_action)
	sendInputstwo.rpc_id(1, {
		"vel": vel,
		"angle": angle,
		"doingAction": doing_action,
		"skill_slot": skill_slot,
		"interacting": interacting,
	})
	sendPos.rpc(position)


func _process_downed_input(_delta: float) -> void:
	# Downed: can crawl at reduced speed only
	var vel := Input.get_vector("walkLeft", "walkRight", "walkUp", "walkDown") * (speed * 0.25)
	moveProcess(vel, 0.0, false)
	sendInputstwo.rpc_id(1, {
		"vel": vel, "angle": 0.0, "doingAction": false, "skill_slot": -1, "interacting": false,
	})
	sendPos.rpc(position)


# ---------------------------------------------------------------------------
# RPC: input relay
# ---------------------------------------------------------------------------
@rpc("any_peer", "call_local", "reliable")
func sendInputstwo(data: Dictionary) -> void:
	moveServer(data["vel"], data["angle"], data["doingAction"], data.get("skill_slot", -1), data.get("interacting", false))


@rpc("any_peer", "call_local", "reliable")
func moveServer(vel: Vector2, angle: float, doing_action: bool, skill_slot: int, _interacting: bool) -> void:
	$MovingParts.rotation = angle
	handleAnims(vel, doing_action)
	# Server-side: handle skill use
	if multiplayer.is_server() and skill_slot >= 0 and _attack_cooldown_remaining <= 0.0:
		_use_skill(skill_slot)


@rpc("any_peer", "call_local", "reliable")
func sendPos(pos: Vector2) -> void:
	position = pos


func moveProcess(vel: Vector2, angle: float, doing_action: bool) -> void:
	velocity = vel
	if velocity != Vector2.ZERO:
		move_and_slide()
	$MovingParts.rotation = angle
	handleAnims(vel, doing_action)


func handleAnims(vel: Vector2, doing_action: bool) -> void:
	var anim := $AnimationPlayer
	if is_downed:
		if anim.has_animation("walking") and anim.current_animation != "walking":
			anim.play("walking")
		return
	if doing_action:
		if anim.has_animation("swinging") and anim.current_animation != "swinging":
			anim.play("swinging")
	elif vel != Vector2.ZERO:
		if anim.has_animation("walking") and anim.current_animation != "walking":
			anim.play("walking")
	else:
		anim.stop()


# ---------------------------------------------------------------------------
# Attack / skill
# ---------------------------------------------------------------------------
func _use_skill(slot: int) -> void:
	if not multiplayer.is_server():
		return
	var player_id := int(str(name))
	var state := MatchState.get_state(player_id)
	var skills_arr: Array = state.get("active_skills", ["", "", ""])
	if slot >= skills_arr.size():
		return
	var skill_id: String = skills_arr[slot]
	if skill_id == "":
		_do_basic_attack()
		return
	# TODO: dispatch skill-specific logic based on skill_id
	_do_basic_attack()


func _do_basic_attack() -> void:
	var weapon_data: Dictionary = GameData.weapons.get(weapon_type, {})
	if weapon_data.is_empty():
		return
	_attack_cooldown_remaining = weapon_data.get("cooldown", 0.6)
	var attack_type: String = weapon_data.get("attack_type", "fan_aoe")
	match attack_type:
		"fan_aoe":
			punchCheckCollision()
		"linear_aoe":
			punchCheckCollision()
		"frontal_aoe":
			punchCheckCollision()
		"projectile":
			var proj: String = weapon_data.get("projectile", "")
			if proj != "" and str(int(str(name))) == str(multiplayer.get_unique_id()):
				sendProjectile.rpc_id(1, get_global_mouse_position())


func punchCheckCollision() -> void:
	if !is_multiplayer_authority():
		return
	var effective_damage := attackDamage * (1.0 + damage_bonus)
	for body in %HitArea.get_overlapping_bodies():
		if body != self and body.is_in_group("damageable"):
			body.getDamage(self, effective_damage, "normal")


@rpc("any_peer", "reliable")
func sendProjectile(towards: Vector2) -> void:
	var weapon_data: Dictionary = GameData.weapons.get(weapon_type, {})
	var proj_id: String = weapon_data.get("projectile", "")
	if proj_id != "":
		GameData.spawn_projectile(self, proj_id, towards, "damageable")


# ---------------------------------------------------------------------------
# Damage
# ---------------------------------------------------------------------------
func getDamage(causer: Node, amount: float, _type: String) -> void:
	if not multiplayer.is_server():
		return
	var reduced := amount * (1.0 - damage_reduction)
	hp -= reduced
	# Interrupt extraction if channeling
	if _extraction_point_ref:
		_extraction_point_ref.interrupt_player(int(str(name)))
	# Interrupt revive if channeling
	if _revive_channel and _revive_channel.is_active():
		_revive_channel.cancel_channel()
	if hp > 0.0 and causer.is_in_group("player"):
		causer.player_killed.emit()


# ---------------------------------------------------------------------------
# Down state
# ---------------------------------------------------------------------------
func enter_downed_state() -> void:
	if not multiplayer.is_server():
		return
	is_downed = true
	_downed_timer = 0.0
	_downed_hp = 100.0
	_sync_downed.rpc()


@rpc("authority", "call_local", "reliable")
func _sync_downed() -> void:
	is_downed = true
	# TODO: play downed animation, show downed UI


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if not is_downed:
		return
	_downed_timer += delta
	_downed_hp = (1.0 - (_downed_timer / Constants.DOWN_DRAIN_TIME)) * 100.0
	if _downed_hp <= 0.0:
		die()


func revive(healer: Node) -> void:
	if not multiplayer.is_server():
		return
	if not is_downed:
		return
	is_downed = false
	hp = maxHP * Constants.REVIVE_HP_PERCENT
	_revived.rpc()
	healer.mob_killed.emit()  # reward healer


@rpc("authority", "call_local", "reliable")
func _revived() -> void:
	is_downed = false
	# TODO: play revive animation, restore controls


# ---------------------------------------------------------------------------
# Death
# ---------------------------------------------------------------------------
func die() -> void:
	if not multiplayer.is_server():
		return
	if _dying:
		return
	_dying = true
	var peer_id := int(str(name))
	MatchState.unregister_player(peer_id)
	Multihelper._deregister_character.rpc(peer_id)
	queue_free()
	if peer_id in multiplayer.get_peers():
		Multihelper.showSpawnUI.rpc_id(peer_id)


# ---------------------------------------------------------------------------
# XP / level
# ---------------------------------------------------------------------------
func _on_mob_killed() -> void:
	if not multiplayer.is_server():
		return
	MatchState.add_xp(int(str(name)), Constants.ENEMY_KILL_XP)


func _on_player_killed() -> void:
	if not multiplayer.is_server():
		return
	MatchState.add_xp(int(str(name)), Constants.ENEMY_KILL_XP * 2)


func _on_level_up(player_id: int, _new_level: int, options: Array) -> void:
	if player_id != int(str(name)):
		return
	# Show skill picker UI
	get_tree().get_first_node_in_group("skill_picker_ui").show_options(options)


func _on_skill_applied(player_id: int, skill_id: String) -> void:
	if player_id != int(str(name)):
		return
	var skill: Dictionary = GameData.skills.get(skill_id, {})
	if skill.is_empty():
		return
	# Apply stat boosts immediately
	var mods: Dictionary = skill.get("stat_mod", {})
	if "max_hp" in mods:
		maxHP += mods["max_hp"]
		hp = minf(hp + mods["max_hp"], maxHP)
	if "damage_reduction" in mods:
		damage_reduction = minf(damage_reduction + mods["damage_reduction"], 0.9)
	if "damage_bonus" in mods:
		damage_bonus += mods["damage_bonus"]
	if "speed_bonus" in mods:
		speed *= (1.0 + mods["speed_bonus"])
	# Sync active/passive skill slots from MatchState
	var state := MatchState.get_state(int(str(name)))
	if not state.is_empty():
		active_skills = state.get("active_skills", active_skills)
		passive_skills = state.get("passive_skills", passive_skills)


# ---------------------------------------------------------------------------
# Circle damage
# ---------------------------------------------------------------------------
func _on_circle_updated(center: Vector2, radius: float, damage_per_sec: float) -> void:
	if not multiplayer.is_server():
		return
	if global_position.distance_to(center) > radius:
		_circle_damage_accum += damage_per_sec * get_process_delta_time()
		if _circle_damage_accum >= 1.0:
			hp -= floor(_circle_damage_accum)
			_circle_damage_accum -= floor(_circle_damage_accum)
	else:
		_circle_damage_accum = 0.0


# ---------------------------------------------------------------------------
# Chat
# ---------------------------------------------------------------------------
@rpc("any_peer", "call_local", "reliable")
func sendMessage(text: String) -> void:
	if multiplayer.is_server():
		var messageBoxScene := preload("res://scenes/ui/chat/message_box.tscn")
		var messageBox := messageBoxScene.instantiate()
		%PlayerMessages.add_child(messageBox, true)
		messageBox.text = str(text)


# ---------------------------------------------------------------------------
# Misc
# ---------------------------------------------------------------------------
func visibilityFilter(id: int) -> bool:
	return id != int(str(name))


func _on_disconnected(id: int) -> void:
	if str(id) == name:
		die()
