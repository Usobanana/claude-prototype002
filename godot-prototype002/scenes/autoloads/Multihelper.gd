extends Node

var playerScenePath: PackedScene = preload("res://scenes/character/player.tscn")
var isHost: bool = false
var mapSeed: int = randi()
var map: Node2D
var main: Node2D

signal player_connected(peer_id)
signal player_disconnected(peer_id)
signal server_disconnected
signal player_spawned(peer_id, player_info)
signal player_despawned
signal player_registered
signal data_loaded

const PORT: int = Constants.PORT
const DEFAULT_SERVER_IP: String = Constants.SERVER_IP

var spawnedPlayers: Dictionary = {}
var connectedPlayers: Array = []
var syncedPlayers: Array = []

var player_info: Dictionary = {"name": ""}

@onready var game: Node = get_node("/root/Game")

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func join_game(address: String = "") -> int:
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	multiplayer.multiplayer_peer = null
	var peer := WebSocketMultiplayerPeer.new()
	var error: int
	if Constants.USE_SSL:
		var cert := load(Constants.TRUSTED_CHAIN_PATH)
		var tls_options := TLSOptions.client(cert)
		error = peer.create_client("wss://" + address + ":" + str(PORT), tls_options)
	else:
		error = peer.create_client("ws://" + address + ":" + str(PORT))
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


func create_game() -> int:
	var peer := WebSocketMultiplayerPeer.new()
	var error: int
	if Constants.USE_SSL:
		var priv := load(Constants.PRIVATE_KEY_PATH)
		var cert := load(Constants.TRUSTED_CHAIN_PATH)
		var tls_options := TLSOptions.server(priv, cert)
		error = peer.create_server(PORT, "*", tls_options)
	else:
		error = peer.create_server(PORT, "*")
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	player_connected.emit(1, player_info)
	game.start_game()
	return OK


func remove_multiplayer_peer() -> void:
	multiplayer.multiplayer_peer = null


func _on_player_connected(id: int) -> void:
	print("player connected with id " + str(id) + " to " + str(multiplayer.get_unique_id()))


@rpc("call_local", "any_peer", "reliable")
func _register_character(new_player_info: Dictionary) -> void:
	var new_player_id: int = multiplayer.get_remote_sender_id()
	spawnedPlayers[new_player_id] = new_player_info
	player_spawned.emit(new_player_id, new_player_info)
	player_registered.emit()


@rpc("call_local", "any_peer", "reliable")
func _deregister_character(id: int) -> void:
	spawnedPlayers.erase(id)
	player_despawned.emit()


func _on_player_disconnected(id: int) -> void:
	connectedPlayers.erase(id)
	spawnedPlayers.erase(id)
	syncedPlayers.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok() -> void:
	game.start_game()
	var peer_id: int = multiplayer.get_unique_id()
	connectedPlayers.append(peer_id)
	player_connected.emit(peer_id)
	# Notify server this client has loaded the scene
	player_loaded.rpc_id(1)


@rpc("any_peer", "call_local", "reliable")
func player_loaded() -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	# Send current player roster to the newly loaded client.
	# Map data is only sent when transitioning to the field (see start_field flow).
	sendGameData.rpc_id(sender_id, spawnedPlayers)


@rpc("authority", "call_remote", "reliable")
func sendGameData(player_data: Dictionary) -> void:
	spawnedPlayers = player_data
	data_loaded.emit()
	set_process(true)


func _on_connected_fail() -> void:
	multiplayer.multiplayer_peer = null


func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	server_disconnected.emit()


# ---------------------------------------------------------------------------
# Map loading — only used when entering field mode
# ---------------------------------------------------------------------------

func loadMap() -> void:
	main = get_node("/root/Game/Level/Main")
	map = main.get_node("Map")
	map.generateMap()


# ---------------------------------------------------------------------------
# Player node resolution — works for Base and Field scenes
# ---------------------------------------------------------------------------

func _get_players_node() -> Node:
	var level: Node = game.get_node("Level")
	for child in level.get_children():
		var players: Node = child.get_node_or_null("Players")
		if players:
			return players
	return null


func requestSpawn(player_name: String, id: int, character_file: String, player_class: String = "warrior") -> void:
	player_info["name"] = player_name
	player_info["body"] = character_file
	player_info["class"] = player_class
	player_info["score"] = 0
	spawnedPlayers[id] = player_info
	_register_character.rpc(player_info)
	spawnPlayer.rpc_id(1, player_name, id, character_file, player_class)


@rpc("any_peer", "call_local", "reliable")
func spawnPlayer(player_name: String, id: int, character_file: String, player_class: String = "warrior") -> void:
	var new_player: Node = playerScenePath.instantiate()
	new_player.playerName = player_name
	new_player.characterFile = character_file
	new_player.player_class = player_class
	new_player.name = str(id)

	var players_node: Node = _get_players_node()
	if players_node == null:
		push_error("Multihelper.spawnPlayer: could not find Players node in Level")
		return
	players_node.add_child(new_player)

	# In field mode the map exists and provides spawn positions.
	# In base mode map is null so we use the origin; the base scene can reposition later.
	var spawn_pos := Vector2.ZERO
	if map != null and map.get("tile_map") != null and map.get("walkable_tiles") != null:
		spawn_pos = map.tile_map.map_to_local(map.walkable_tiles.pick_random())
	new_player.sendPos.rpc(spawn_pos)

	if multiplayer.is_server():
		MatchState.register_player(id, player_class)


func player_extracted(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	MatchState.mark_extracted(peer_id)
	_deregister_character.rpc(peer_id)
	var players_node: Node = _get_players_node()
	if players_node:
		var player_node: Node = players_node.get_node_or_null(str(peer_id))
		if player_node:
			player_node.queue_free()
	if peer_id in multiplayer.get_peers():
		show_extracted_screen.rpc_id(peer_id)


@rpc("authority", "call_remote", "reliable")
func show_extracted_screen() -> void:
	# TODO: show extraction success screen
	print("脱出成功！")


@rpc("any_peer", "call_remote", "reliable")
func showSpawnUI() -> void:
	var spawn_player_scene: PackedScene = preload("res://scenes/ui/spawn/spawnPlayer.tscn")
	var retry: Node = spawn_player_scene.instantiate()
	retry.retry = true
	get_node("/root/Game/Level/Main/HUD").add_child(retry)
