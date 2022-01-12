class_name AStarTileMap

# basic A* for a purely TileMap based navigation
# hastily put together and not optimized in any way
static func run(start: Vector2, goal: Vector2, tile_map: TileMap, computed_cells_array = null):
	if(start == goal):
		return [goal]
	
	# A Star
	var open_set := [start]
	var came_from := {}
	
	if(computed_cells_array == []):
		computed_cells_array.append(start)
	
	# g_score[n] is the current cheapest path from start to n
	var g_score := {start: 0}
	
	# f_score[n] = g_score[n] + h(n)
	# best guess at to the shortest path going through n
	var f_score := {start: distance_between_cardinal(start, goal)}
	
	while(open_set.size() > 0):
		# assume open_set is sorted by f_score
		var current: Vector2 = open_set[0]
		if(current == goal):
			return reconstruct_path(came_from, current)
		
		open_set.remove(0)
		var neighbors := [current+Vector2.UP, current+Vector2.DOWN, current+Vector2.LEFT, current+Vector2.RIGHT]
		for neighbor in neighbors:
			if(tile_map.get_cell(neighbor.x, neighbor.y) == -1):
				continue
			computed_cells_array.append(neighbor)
			var tentative_g_score = g_score[current] + distance_between_cardinal(current, neighbor)
			if(tentative_g_score < g_score.get(neighbor, INF)):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + distance_between_cardinal(neighbor, goal)
				if(!open_set.has(neighbor)):
					if(open_set.size() == 0):
						open_set.append(neighbor)
					else:
						# insert neighbor into the open_set sorted by f_score ascending
						for i in range(open_set.size()+1):
							if(i >= open_set.size()):
								open_set.append(neighbor)
								break
							if(f_score[neighbor] < f_score[open_set[i]]):
								open_set.insert(i, neighbor)
								break
	
	#never reached goal
	return []

static func reconstruct_path(came_from: Dictionary, current: Vector2):
	var total_path := [current]
	while(came_from.has(current)):
		current = came_from[current]
		total_path.push_front(current)
	return total_path

static func distance_between_cardinal(coord_a: Vector2, coord_b: Vector2):
	return abs(coord_a.x-coord_b.x) + abs(coord_a.y-coord_b.y)

static func distance_between_octile(coord_a: Vector2, coord_b: Vector2):
	var delta_x = abs(coord_a.x-coord_b.x)
	var delta_y = abs(coord_a.y-coord_b.y)
	return 1.414 * min(delta_x, delta_y) + abs(delta_x-delta_y)

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
