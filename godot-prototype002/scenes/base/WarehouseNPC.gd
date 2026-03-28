extends Area2D
# Warehouse NPC interaction zone.
# When the local player enters and presses F (interact), opens the warehouse UI.

signal open_ui()

var _player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player_inside and Input.is_action_just_pressed("interact"):
		open_ui.emit()


func _on_body_entered(body: Node) -> void:
	if str(body.name) == str(multiplayer.get_unique_id()):
		_player_inside = true
		# TODO: show "F: 倉庫を開く" interact prompt


func _on_body_exited(body: Node) -> void:
	if str(body.name) == str(multiplayer.get_unique_id()):
		_player_inside = false
