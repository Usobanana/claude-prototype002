extends Area2D
# Extraction point logic.
# - Hidden until MatchManager reveals it (3 minutes into match).
# - Players enter the area and hold to channel extraction (5 seconds).
# - Multiple players can channel the same point simultaneously.
# - Taking damage cancels the channel.
# - Never closes.
#
# Editor setup:
#   - Add a CollisionShape2D child (circle or rect to define the extraction zone).
#   - Add a Sprite2D or AnimatedSprite2D for the visual indicator.
#   - Add a Label or Node2D for the UI prompt.

signal player_extracted(player_id: int)

var is_revealed: bool = false

# { player_id: ChannelingInteraction node }
var _channeling: Dictionary = {}


func _ready() -> void:
	visible = false
	monitoring = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	MatchManager.extraction_points_revealed.connect(_on_revealed)


func _on_revealed() -> void:
	is_revealed = true
	_reveal.rpc()


@rpc("authority", "call_local", "reliable")
func _reveal() -> void:
	is_revealed = true
	visible = true
	monitoring = true


func _on_body_entered(body: Node) -> void:
	if not multiplayer.is_server():
		return
	if not is_revealed:
		return
	if not body.is_in_group("player"):
		return

	var player_id := int(str(body.name))
	if player_id in _channeling:
		return
	if body.get("is_downed") == true:
		# Downed players can attempt extraction by crawling in — allow it
		pass

	var channel := ChannelingInteraction.new()
	channel.channel_time = Constants.EXTRACT_CHANNEL_TIME
	channel.interrupt_group = ""  # Damage-based interruption handled in player.gd
	body.add_child(channel)
	_channeling[player_id] = channel

	channel.channel_completed.connect(func(): _extraction_complete(player_id, body, channel))
	channel.channel_interrupted.connect(func(): _extraction_cancelled(player_id, channel))
	channel.channel_progress.connect(func(r): _rpc_progress.rpc_id(player_id, r))

	channel.start_channel(player_id)
	_rpc_start_extract.rpc_id(player_id)


func _on_body_exited(body: Node) -> void:
	if not multiplayer.is_server():
		return
	var player_id := int(str(body.name))
	_cancel_channel_for(player_id)


func interrupt_player(player_id: int) -> void:
	# Called by player.gd when that player takes damage while channeling
	if multiplayer.is_server():
		_cancel_channel_for(player_id)


func _cancel_channel_for(player_id: int) -> void:
	if player_id in _channeling:
		_channeling[player_id].cancel_channel()


func _extraction_complete(player_id: int, body: Node, channel: Node) -> void:
	_channeling.erase(player_id)
	channel.queue_free()
	player_extracted.emit(player_id)
	_rpc_extracted.rpc_id(player_id)
	# Notify Multihelper on server to remove the player from the match
	if multiplayer.is_server():
		Multihelper.player_extracted(player_id)


func _extraction_cancelled(player_id: int, channel: Node) -> void:
	_channeling.erase(player_id)
	channel.queue_free()
	_rpc_cancel_extract.rpc_id(player_id)


# ---------------------------------------------------------------------------
# Client-side RPCs (UI feedback only)
# ---------------------------------------------------------------------------
@rpc("authority", "call_local", "reliable")
func _rpc_start_extract() -> void:
	# TODO: show extraction progress bar on client
	pass


@rpc("authority", "call_local", "reliable")
func _rpc_extracted() -> void:
	# TODO: show "EXTRACTED" screen
	pass


@rpc("authority", "call_local", "reliable")
func _rpc_cancel_extract() -> void:
	# TODO: hide extraction progress bar
	pass


@rpc("authority", "call_local", "unreliable")
func _rpc_progress(_ratio: float) -> void:
	# TODO: update extraction progress bar
	pass
