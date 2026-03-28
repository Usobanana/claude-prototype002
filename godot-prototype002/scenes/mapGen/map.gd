extends Node2D
# NOTE (Editor setup required):
#   - Set TileMap tile shape to TILE_SHAPE_ISOMETRIC in the TileSet resource
#   - Set TileMap tile layout to TILE_LAYOUT_DIAMOND_DOWN
#   - Set TileMap tile offset axis to TILE_OFFSET_AXIS_HORIZONTAL
#   - Enable y_sort_enabled on the TileMap node
#   - Update atlas coordinates below to match the isometric tileset
#
# TODO: Replace tilesheet_complete.png with isometric tile art.
#       Current atlas coords are placeholders kept from the original top-down tileset.

var grass_atlas_coords := [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(16,0), Vector2i(17,0)]
var water_atlas_coords := [Vector2i(18,0), Vector2i(19,0)]
var noise := FastNoiseLite.new()
var tileset_source := 1

var map_width: int = Constants.MAP_SIZE.x
var map_height: int = Constants.MAP_SIZE.y

var walkable_tiles: Array[Vector2i] = []

@onready var tile_map: TileMap = $TileMap


func generateMap() -> void:
	noise.seed = Multihelper.mapSeed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_octaves = 1.1
	noise.fractal_lacunarity = 2.0
	noise.frequency = 0.03
	walkable_tiles.clear()
	generate_terrain()


func generate_terrain() -> void:
	for y in range(map_height):
		for x in range(map_width):
			var noise_value := noise.get_noise_2d(x, y)
			if noise_value > 0.03:
				var tile_coord := grass_atlas_coords.pick_random()
				tile_map.set_cell(0, Vector2i(x, y), tileset_source, tile_coord, 0)
				walkable_tiles.append(Vector2i(x, y))
			else:
				var tile_coord := water_atlas_coords.pick_random()
				tile_map.set_cell(0, Vector2i(x, y), tileset_source, tile_coord, 0)


func get_map_center_world() -> Vector2:
	var center_tile := Vector2i(map_width / 2, map_height / 2)
	return tile_map.map_to_local(center_tile)


func get_map_radius_world() -> float:
	# Half the map width in world units — used as initial circle radius
	return (map_width / 2.0) * Constants.TILE_SIZE


func get_random_walkable_world_pos() -> Vector2:
	if walkable_tiles.is_empty():
		return Vector2.ZERO
	return tile_map.map_to_local(walkable_tiles.pick_random())
