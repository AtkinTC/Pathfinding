class_name NavRectExpansion
extends NavClusterGraph

var clusters := {}
var parent_cluster := {}

func reset():
	clusters = {}
	parent_cluster = {}

func get_cluster(_id: String):
	return clusters.get(_id)

func get_clusters_dict():
	return clusters

func get_cluster_containing_coord(_coordv: Vector2):
	return parent_cluster.get(_coordv, null)

func build_from_tilemap(tilemap: TileMap, print_array = null):
	var start_time = OS.get_ticks_msec()
	
	parent_cluster = {}
	clusters = {}
	
	# accessing 2d array is ~10x-20x faster than accessing the tiles directly from the tilemap
	var grid_2d := Utils.tilemap_to_array2d(tilemap)
	
	var sorted_grid_cells := []
	var sorted_h_values: PoolRealArray = []
	
	var start_time_precalc = OS.get_ticks_msec()
	for cell in tilemap.get_used_cells():
		var h_val = expand_rect_from_coord_estimate(cell, grid_2d)
		if(h_val == null):
			break
		for i in range(sorted_grid_cells.size()+1):
			if(i == sorted_grid_cells.size()):
				sorted_grid_cells.append(cell)
				sorted_h_values.append(h_val)
				break
			else:
				if(h_val > sorted_h_values[i]):
					sorted_grid_cells.insert(i, cell)
					sorted_h_values.insert(i, h_val)
					break
	var end_time_precalc = OS.get_ticks_msec()
	
	var start_time_calc = OS.get_ticks_msec()
	while(sorted_grid_cells.size() > 0):
		var cell: Vector2 = sorted_grid_cells[0]
		if(grid_2d[cell.x][cell.y] > 0):
			var result = expand_rect_from_coord(cell, grid_2d)
			if(result == null || result.size.x == 0 || result.size.y == 0):
				break
			
			var contained_cells := []
			for x in range(result.position.x, result.position.x + result.size.x):
				for y in range(result.position.y, result.position.y + result.size.y):
					contained_cells.append(Vector2(x,y))
			
			var id := str(cell)
			var cluster := NavCluster.new(id, result.position, result.size)
			clusters[id] = cluster
			for c_cell in contained_cells:
				parent_cluster[c_cell] = cluster
				sorted_grid_cells.erase(c_cell)
				grid_2d[c_cell.x][c_cell.y] = 0
	var end_time_calc = OS.get_ticks_msec()
	
	var start_time_neighbors = OS.get_ticks_msec()
	for id in clusters.keys():
		var cluster: NavCluster = clusters[id]
		cluster.neighbors = find_neighbors(cluster)
	var end_time_neighbors = OS.get_ticks_msec()
	var end_time = OS.get_ticks_msec()
	
	if(print_array is Array):
		print_array.append("#############")
		print_array.append("NavRectExpansions.build_from_tilemap()")
		print_array.append(str("\tstarting cells = ", tilemap.get_used_cells().size()))
		print_array.append(str("\ttotal clusters = ", clusters.size()))
		print_array.append(str("\ttotal elapsed time (ms) = ", end_time - start_time))
		print_array.append(str("\tpre-calculation time (ms) = ", end_time_precalc - start_time_precalc))
		print_array.append(str("\ttotal cluster calc time (ms) = ", end_time_calc - start_time_calc))
		print_array.append(str("\tneighbor calc time (ms) = ", end_time_neighbors - start_time_neighbors))
		print_array.append("#############")

# calculate a heuristic score for the cell
# a higher score indicates this cell has a higher priority for cluster creation
func expand_rect_from_coord_estimate(cellv: Vector2, open_cells: Array):
	if(open_cells == null || open_cells.size() == 0 || open_cells[cellv.x].size() == 0 || open_cells[cellv.x][cellv.y] == 0):
		return null
		
	var n: int = 0
	var e: int = 0
	var s: int = 0
	var w: int = 0
	
	var expand_n := true
	var expand_e := true
	var expand_s := true
	var expand_w := true
	
	while(expand_n || expand_e || expand_s || expand_w):
		# expand the rect by rows and columns in the 4 cardinal directions
		#NORTH
		if(expand_n):
			var y: int = cellv.y-n-1
			for x in range(cellv.x-w, cellv.x+e+1):
				if(y < 0 || open_cells[x][y] == 0):
					expand_n = false
					break
			if(expand_n):
				n += 1
				
		#EAST
		if(expand_e):
			var x: int = cellv.x+e+1
			for y in range(cellv.y-n, cellv.y+s+1):
				if(x >= open_cells.size() || open_cells[x][y] == 0):
					expand_e = false
					break
			if(expand_e):
				e += 1
		
		#SOUTH
		if(expand_s):
			var y: int = cellv.y+s+1
			for x in range(cellv.x-w, cellv.x+e+1):
				if(y >= open_cells[x].size() || open_cells[x][y] == 0):
					expand_s = false
					break
			if(expand_s):
				s += 1
		
		#WEST
		if(expand_w):
			var x: int = cellv.x-w-1
			for y in range(cellv.y-n, cellv.y+s+1):
				if(x < 0 ||open_cells[x][y] == 0):
					expand_w = false
					break
			if(expand_w):
				w += 1
		
		# break early if rect is becoming to long along one axis
		# dual purpose: 
		#	1) improve speed by ending sooner
		#	2) lower ranking for stretched rects over square rects
		if(e+w+1 > (n+s+1)*1.5|| n+s+1 > (e+w+1)*1.5):
			break
	
	var size_x = e+w+1
	var size_y = n+s+1
	return size_x*size_y - abs(size_x - size_y)

# creates a rectangle of available traversable space expanding outwards from the givin cell
func expand_rect_from_coord(cellv: Vector2, open_cells: Array):
	if(open_cells == null || open_cells.size() == 0 || open_cells[cellv.x].size() == 0 || open_cells[cellv.x][cellv.y] == 0):
		return null
	
	var n: int = 0
	var e: int = 0
	var s: int = 0
	var w: int = 0
	
	var expand_n := true
	var expand_e := true
	var expand_s := true
	var expand_w := true
	
	while(expand_n || expand_e || expand_s || expand_w):
		# expand the rectangle by rows and columns in the 4 cardinal directions
		#NORTH
		if(expand_n):
			var y: int = cellv.y-n-1
			for x in range(cellv.x-w, cellv.x+e+1):
				if(y < 0 || open_cells[x][y] == 0):
					expand_n = false
					break
			if(expand_n):
				n += 1
		
		#EAST
		if(expand_e):
			var x: int = cellv.x+e+1
			for y in range(cellv.y-n, cellv.y+s+1):
				if(x >= open_cells.size() || open_cells[x][y] == 0):
					expand_e = false
					break
			if(expand_e):
				e += 1
		
		#SOUTH
		if(expand_s):
			var y: int = cellv.y+s+1
			for x in range(cellv.x-w, cellv.x+e+1):
				if(y >= open_cells[x].size() || open_cells[x][y] == 0):
					expand_s = false
					break
			if(expand_s):
				s += 1
		
		#WEST
		if(expand_w):
			var x: int = cellv.x-w-1
			for y in range(cellv.y-n, cellv.y+s+1):
				if(x < 0 ||open_cells[x][y] == 0):
					expand_w = false
					break
			if(expand_w):
				w += 1
	return Rect2(cellv.x-w, cellv.y-n, e+w+1, s+n+1)

func find_neighbors(cluster: NavCluster):
	var neighbors := []
	for d in Direction:
		var neighbors_d = find_neighbors_direction(cluster, Direction[d])
		for n in neighbors_d:
			if(!neighbors.has(n)):
				neighbors.append(n)
	return neighbors

func find_neighbors_direction(cluster: NavCluster, direction: int):
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
