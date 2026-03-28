extends Node2D
# Base scene — persistent multiplayer hub.
# Players auto-spawn here on connect and after returning from a field match.
# Supports: blacksmith crafting, warehouse, equipment selection, match queue.

func _ready() -> void:
	add_to_group("base_scene")
	# Connect NPC signals to UI
	$NPCs/Blacksmith.open_ui.connect($HUD/BlacksmithUI.open)
	$NPCs/Warehouse.open_ui.connect($HUD/WarehouseUI.open)
	$NPCs/EquipmentStation.open_ui.connect($HUD/EquipmentUI.open)
	call_deferred("_auto_spawn")
	Multihelper.player_spawned.connect(_on_player_spawned)


func _auto_spawn() -> void:
	var pid: int = multiplayer.get_unique_id()
	var name_str: String = PlayerProfile.player_name
	if name_str.is_empty():
		name_str = "Player" + str(pid)

	# Use selected character or first owned
	var char_data: Dictionary = {}
	if not PlayerProfile.selected_character_id.is_empty():
		char_data = PlayerProfile.get_character(PlayerProfile.selected_character_id)
	if char_data.is_empty() and not PlayerProfile.owned_characters.is_empty():
		char_data = PlayerProfile.owned_characters[0]

	var player_class: String = char_data.get("class", "warrior")
	var char_body: String = char_data.get("sprite_body", "0.png")
	Multihelper.requestSpawn(name_str, pid, char_body, player_class)


func _on_player_spawned(_peer_id: int, _player_info: Dictionary) -> void:
	pass  # Base-specific spawn handling if needed


# Called by MatchStartZone when the host presses interact
func request_start_match() -> void:
	if not multiplayer.is_server():
		return
	var game: Node = get_node("/root/Game")
	game.start_field()
