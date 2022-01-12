class_name AStarTileMapV2
extends AStar2D

func add_points_from_tile_map(tile_map: TileMap):
	self.clear()
	
	var minv := tile_map.get_used_rect().position
	var maxv := minv + tile_map.get_used_rect().size
	
	reserve_space(tile_map.get_used_cells().size())
	
	for x in range(minv.x, maxv.x):
		for y in range(minv.y, maxv.y):
			if(tile_map.get_cell(x, y) >= 0):
				var coordv := Vector2(x,y)
				add_point(coord_to_id(coordv), coordv)
	
	for x in range(minv.x, maxv.x):
		for y in range(minv.y, maxv.y):
			if(tile_map.get_cell(x, y) >= 0):
				var coordv := Vector2(x,y)
				var id = coord_to_id(coordv)
				connect_points(id, coord_to_id(coordv + Vector2.UP))
				connect_points(id, coord_to_id(coordv + Vector2.DOWN))
				connect_points(id, coord_to_id(coordv + Vector2.LEFT))
				connect_points(id, coord_to_id(coordv + Vector2.RIGHT))

func run(start: Vector2, goal: Vector2):
	return get_point_path(coord_to_id(start), coord_to_id(goal))

static func coord_to_id(coordv: Vector2):
	# Cantor Pairing function
	return (coordv.x + coordv.y) * (coordv.x + coordv.y + 1)/2 + coordv.y

static func id_to_coord(id: int):
	# Inverted Cantor Pairing function
	var w = floor((sqrt(8*id+1) - 1)/2)
	var t = (pow(w,2) + w)/2
	var y = id - t
	var x = w - y
	return Vector2(x,y)
