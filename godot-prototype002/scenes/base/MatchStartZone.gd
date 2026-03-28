extends Area2D
# Zone that the host can interact with to start a field match.
# Only the server (host) can trigger the match start.

var _player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player_inside and Input.is_action_just_pressed("interact") and multiplayer.is_server():
		var base: Node = get_tree().get_first_node_in_group("base_scene")
		if base:
			base.request_start_match()


func _on_body_entered(body: Node) -> void:
	if str(body.name) == str(multiplayer.get_unique_id()):
		_player_inside = true
		# TODO: show "F: マッチ開始 (ホストのみ)" prompt


func _on_body_exited(body: Node) -> void:
	if str(body.name) == str(multiplayer.get_unique_id()):
		_player_inside = false
