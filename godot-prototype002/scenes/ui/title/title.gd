extends Control
# Title screen — player enters name, then hosts or joins a game.

@onready var name_input: LineEdit = $VBox/NameInput
@onready var host_button: Button = $VBox/HostButton
@onready var join_button: Button = $VBox/JoinButton
@onready var ip_input: LineEdit = $VBox/IPInput
@onready var status_label: Label = $VBox/StatusLabel

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	# Restore saved name
	name_input.text = PlayerProfile.player_name


func _on_host_pressed() -> void:
	_save_name()
	status_label.text = "サーバー起動中..."
	var err: int = Multihelper.create_game()
	if err:
		status_label.text = "エラー: " + str(err)


func _on_join_pressed() -> void:
	_save_name()
	status_label.text = "接続中..."
	var address: String = ip_input.text
	var err: int = Multihelper.join_game(address)
	if err:
		status_label.text = "エラー: " + str(err)


func _save_name() -> void:
	var n: String = name_input.text.strip_edges()
	if n.is_empty():
		n = "Player"
	PlayerProfile.player_name = n
	PlayerProfile.save_profile()
