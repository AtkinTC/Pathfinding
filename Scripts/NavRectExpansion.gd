class_name NavRectExpansion
extends NavClusterGraph

var clusters := {}
var parent_cluster := {}

func get_cluster(id: String):
	return clusters.get(id)

func get_clusters_dict():
	return clusters

func get_cluster_containing_coord(coordv: Vector2):
	return parent_cluster.get(coordv, null)

func build_from_tilemap(tilemap: TileMap):
	parent_cluster = {}
	clusters = {}
	
	var used_rect := tilemap.get_used_rect()
	var open_grid_cells = tilemap.get_used_cells()
	
	# extremely naive approach
	# progressing in reverse from bottom right just because it looks better on the current test map
	for x in range(used_rect.position.x + used_rect.size.x, used_rect.position.x, -1):
		for y in range(used_rect.position.y + used_rect.size.y, used_rect.position.y, -1):
			#finished when all cells have been used
			if(open_grid_cells.size() == 0):
				break
			if(open_grid_cells.has(Vector2(x, y))):
				var h = 1
				var w = 1
				var expand_x := true
				var expand_y := true
				var contained_cells = [Vector2(x,y)]
				while(expand_x || expand_y):
					if(expand_x):
						var new_col := []
						for y2 in range(h):
							if(!open_grid_cells.has(Vector2(x-w, y-y2))):
								expand_x = false
								break
							new_col.append(Vector2(x-w, y-y2))
						if(expand_x):
							contained_cells.append_array(new_col)
							w += 1
					if(expand_y):
						var new_row := []
						for x2 in range(w):
							if(!open_grid_cells.has(Vector2(x-x2, y-h))):
								expand_y = false
								break
							new_row.append(Vector2(x-x2, y-h))
						if(expand_y):
							h += 1
							contained_cells.append_array(new_row)
				var id := str(x,",",y)
				var cluster := NavCluster.new(id, Vector2(x-w+1,y-h+1), Vector2(w,h))
				clusters[id] = cluster
				for cell in contained_cells:
					parent_cluster[cell] = cluster
					open_grid_cells.erase(cell)
	
	for id in clusters.keys():
		var cluster: NavCluster = clusters[id]
		for d in Direction:
			var neighbors = find_neighbors(cluster, Direction[d])
			for n in neighbors:
				if(!cluster.neighbors.has(n)):
					cluster.neighbors.append(n)

func find_neighbors(cluster: NavCluster, direction: int):
	if(cluster == null):
		return []
	
	var neighbors := []
	
	#NORTH
	if(direction == Direction.N):
		var y = cluster.topleft.y - 1
		for x in range(cluster.topleft.x, cluster.topleft.x + cluster.dim.x):
			if(parent_cluster.has(Vector2(x, y))):
				var neighbor = parent_cluster[Vector2(x, y)]
				if(!neighbors.has(neighbor)):
					neighbors.append(neighbor)
		return neighbors
	
	#SOUTH
	if(direction == Direction.S):
		var y = cluster.topleft.y + cluster.dim.y
		for x in range(cluster.topleft.x, cluster.topleft.x + cluster.dim.x):
			if(parent_cluster.has(Vector2(x, y))):
				var neighbor = parent_cluster[Vector2(x, y)]
				if(!neighbors.has(neighbor)):
					neighbors.append(neighbor)
		return neighbors
	
	#WEST
	if(direction == Direction.W):
		var x = cluster.topleft.x - 1
		for y in range(cluster.topleft.y, cluster.topleft.y + cluster.dim.y):
			if(parent_cluster.has(Vector2(x, y))):
				var neighbor = parent_cluster[Vector2(x, y)]
				if(!neighbors.has(neighbor)):
					neighbors.append(neighbor)
		return neighbors
	
	#EAST
	if(direction == Direction.E):
		var x = cluster.topleft.x + cluster.dim.x
		for y in range(cluster.topleft.y, cluster.topleft.y + cluster.dim.y):
			if(parent_cluster.has(Vector2(x, y))):
				var neighbor = parent_cluster[Vector2(x, y)]
				if(!neighbors.has(neighbor)):
					neighbors.append(neighbor)
		return neighbors
	
	return neighbors
