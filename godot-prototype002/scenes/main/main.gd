extends Node2D

# Enemy spawning constants
const ENEMY_WAVE_COUNT := 2
var enemy_types: Array = GameData.mobs.keys()
var spawned_enemies: Dictionary = {}  # { player_id: count }

# Extraction points
var extraction_point_scene: PackedScene = null

func _ready() -> void:
	if multiplayer.is_server():
		Multihelper.loadMap()
		_spawn_extraction_points()
		var map_center: Vector2 = $Map.get_map_center_world()
		var map_radius: float = $Map.get_map_radius_world()
		MatchManager.start_match(map_center, map_radius)

	createHUD()
	MatchManager.match_ended.connect(_on_match_ended)


func createHUD() -> void:
	var hudScene := preload("res://scenes/ui/playersList/generalHud.tscn")
	var hud := hudScene.instantiate()
	$HUD.add_child(hud)


# ---------------------------------------------------------------------------
# Extraction points
# ---------------------------------------------------------------------------
func _spawn_extraction_points() -> void:
	if not multiplayer.is_server():
		return
	if extraction_point_scene == null:
		if ResourceLoader.exists("res://scenes/match/ExtractionPoint.tscn"):
			extraction_point_scene = load("res://scenes/match/ExtractionPoint.tscn")
		else:
			push_warning("ExtractionPoint.tscn not found — create it in the editor.")
			return

	var walkable: Array[Vector2i] = $Map.walkable_tiles
	if walkable.is_empty():
		return

	# Place extraction points near the outer ring of the map (last 20% of tiles from center)
	var map_cx: int = Constants.MAP_SIZE.x / 2
	var map_cy: int = Constants.MAP_SIZE.y / 2
	var outer_tiles: Array = []
	for tile in walkable:
		var dist := Vector2(tile).distance_to(Vector2(map_cx, map_cy))
		if dist > Constants.MAP_SIZE.x * 0.3:
			outer_tiles.append(tile)

	outer_tiles.shuffle()
	var count := mini(Constants.EXTRACTION_COUNT, outer_tiles.size())
	for i in range(count):
		var ep := extraction_point_scene.instantiate()
		$ExtractionPoints.add_child(ep, true)
		ep.position = $Map.tile_map.map_to_local(outer_tiles[i])


# ---------------------------------------------------------------------------
# Enemy spawning
# ---------------------------------------------------------------------------
func trySpawnEnemies() -> void:
	var enemyScene := preload("res://scenes/enemy/enemy.tscn")
	var players := Multihelper.spawnedPlayers.keys()
	for player_id in players:
		var count := _get_player_enemy_count(player_id)
		if count >= Constants.MAX_ENEMIES_PER_PLAYER:
			continue
		var to_spawn := mini(Constants.MAX_ENEMIES_PER_PLAYER - count, ENEMY_WAVE_COUNT)
		var positions = $NavHelper.getNRandomNavigableTileInPlayerRadius(
			player_id, to_spawn,
			Constants.ENEMY_SPAWN_RADIUS_MIN,
			Constants.ENEMY_SPAWN_RADIUS_MAX
		)
		for pos in positions:
			var enemy := enemyScene.instantiate()
			$Enemies.add_child(enemy, true)
			enemy.position = pos
			enemy.spawner = self
			enemy.enemyId = enemy_types.pick_random()
			_increase_player_enemy_count(player_id)


func _get_player_enemy_count(pid: int) -> int:
	return int(spawned_enemies.get(pid, 0))


func _increase_player_enemy_count(pid: int) -> void:
	spawned_enemies[pid] = int(spawned_enemies.get(pid, 0)) + 1


func decreasePlayerEnemyCount(pid: int) -> void:
	spawned_enemies[pid] = maxi(0, int(spawned_enemies.get(pid, 1)) - 1)


func _on_enemy_spawn_timer_timeout() -> void:
	if multiplayer.is_server():
		trySpawnEnemies()


# ---------------------------------------------------------------------------
# Match end
# ---------------------------------------------------------------------------
func _on_match_ended() -> void:
	# Kill all remaining players (forced death = item loss)
	for player in $Players.get_children():
		if player.is_in_group("player"):
			player.die()
