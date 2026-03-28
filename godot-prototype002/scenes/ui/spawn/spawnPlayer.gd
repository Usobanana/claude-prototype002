extends Control

var retry = false
var charactersFolder = "res://assets/characters/bodies/"

# クラスリスト（インデックス = 選択番号）
const CLASS_LIST = ["warrior", "knight", "mage", "archer", "cleric"]
const CLASS_NAMES_JP = ["戦士", "騎士", "魔術師", "射手", "僧侶"]
var selectedClassIndex = 0


func _ready():
	if retry:
		%RetryWindow.visible = true
	setActiveCharacter()


func _on_button_pressed():
	if %nameInput.text != "":
		var player_class := CLASS_LIST[selectedClassIndex]
		var character_file := str(selectedClassIndex) + ".png"
		Multihelper.requestSpawn(%nameInput.text, multiplayer.get_unique_id(), character_file, player_class)
		queue_free()


func _on_prev_character_button_pressed():
	selectedClassIndex = (selectedClassIndex - 1 + CLASS_LIST.size()) % CLASS_LIST.size()
	setActiveCharacter()


func _on_next_character_button_pressed():
	selectedClassIndex = (selectedClassIndex + 1) % CLASS_LIST.size()
	setActiveCharacter()


func setActiveCharacter():
	var character_file := str(selectedClassIndex) + ".png"
	%selectedBody.texture = load(charactersFolder + character_file)
	# クラス名を表示（ノードがあれば）
	if has_node("%className"):
		%className.text = CLASS_NAMES_JP[selectedClassIndex]
