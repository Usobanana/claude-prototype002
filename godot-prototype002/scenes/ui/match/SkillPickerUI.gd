extends CanvasLayer
# Roguelite skill selection UI shown on level-up.
# Server sends 3 options; player picks one; choice is sent back to server.
# The game is NOT paused during the pick (time pressure in PvPvE).
#
# Editor setup (create SkillPickerUI.tscn):
#   CanvasLayer
#   └── PanelContainer (center of screen)
#       ├── VBoxContainer
#       │   ├── Label ("レベルアップ！スキルを選択")
#       │   └── HBoxContainer  ← $OptionsContainer
#       │       ├── Button (option 0)
#       │       ├── Button (option 1)
#       │       └── Button (option 2)

add_to_group("skill_picker_ui")

@onready var options_container: HBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer

var _current_options: Array = []


func show_options(options: Array) -> void:
	_current_options = options
	visible = true
	_rebuild_buttons()


func _rebuild_buttons() -> void:
	for child in options_container.get_children():
		child.queue_free()

	for i in range(_current_options.size()):
		var skill_id: String = _current_options[i]
		var skill_data: Dictionary = GameData.skills.get(skill_id, {})

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 120)
		btn.text = "%s\n\n%s" % [
			skill_data.get("name", skill_id),
			skill_data.get("description", ""),
		]
		var idx := i
		btn.pressed.connect(func(): _on_option_selected(idx))
		options_container.add_child(btn)


func _on_option_selected(idx: int) -> void:
	if idx >= _current_options.size():
		return
	var chosen_id: String = _current_options[idx]
	visible = false
	# Send choice to server
	_send_choice.rpc_id(1, chosen_id)


@rpc("any_peer", "reliable")
func _send_choice(skill_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	MatchState.apply_skill(sender_id, skill_id)
