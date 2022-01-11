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

# create a 2d array of the navigable tiles for improved performance
func tilemap_to_array2d(tilemap: TileMap) -> Array:
	var used_rect := tilemap.get_used_rect()
	var col_0 := []
	col_0.resize(used_rect.position.y + used_rect.size.y)
	for y in range(col_0.size()):
		col_0[y] = 0
		
	var grid_2d := []
	grid_2d.resize(used_rect.position.x + used_rect.size.x)
	for x in range(grid_2d.size()):
		grid_2d[x] = col_0.duplicate()
	for cell in tilemap.get_used_cells():
		grid_2d[cell.x][cell.y] = 1
		
	return grid_2d

func build_from_tilemap(tilemap: TileMap):
	var start_time = OS.get_ticks_msec()
	
	parent_cluster = {}
	clusters = {}
	
	var used_rect := tilemap.get_used_rect()
	var open_grid_cells: = tilemap.get_used_cells()
	
	# accessing 2d array is ~10x-20x faster than accessing the tiles directly from the tilemap
	var grid_2d := tilemap_to_array2d(tilemap)
	
	var sorted_grid_cells: PoolVector2Array = []
	var sorted_h_values: PoolRealArray = []
	var start_time_precalc = OS.get_ticks_msec()
	for cell in open_grid_cells:
		var result = expand_rect_from_coord_estimate_grid2d(cell, grid_2d)
		if(result == null || result.size.x == 0 || result.size.y == 0):
			break
		var h_val = result.size.x*result.size.y - abs(result.size.x-result.size.y)
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
	for i in range(sorted_grid_cells.size()):
		#finished when all cells have been used
		if(open_grid_cells.size() == 0):
			break
		var cell: Vector2 = sorted_grid_cells[i]
		if(open_grid_cells.has(cell)):
			var contained_cells := []
			#var result = expand_rect_from_coord_v2(cell, open_grid_cells, contained_cells)
			var result = expand_rect_from_coord_grid2d(cell, grid_2d, contained_cells)
			if(result == null || result.size.x == 0 || result.size.y == 0):
				break
			
			var id := str(cell)
			var cluster := NavCluster.new(id, result.position, result.size)
			clusters[id] = cluster
			for c_cell in contained_cells:
				parent_cluster[c_cell] = cluster
				open_grid_cells.erase(c_cell)
				grid_2d[c_cell.x][c_cell.y] = 0
			#if(i < sorted_h_values.size()):
			#	print(str(cell," : h_value = ", sorted_h_values[i], ", actual = ", result.size.x*result.size.y))
	var end_time_calc = OS.get_ticks_msec()
	
	var start_time_neighbors = OS.get_ticks_msec()
	for id in clusters.keys():
		var cluster: NavCluster = clusters[id]
		for d in Direction:
			var neighbors = find_neighbors(cluster, Direction[d])
			for n in neighbors:
				if(!cluster.neighbors.has(n)):
					cluster.neighbors.append(n)
	var end_time_neighbors = OS.get_ticks_msec()
	var end_time = OS.get_ticks_msec()
	
	print("NavRectExpansions.run()")
	print(str("starting cells = ", tilemap.get_used_cells().size()))
	print(str("total clusters = ", clusters.size()))
	print(str("total elapsed time (ms) = ", end_time - start_time))
	print(str("pre-calculation time (ms) = ", end_time_precalc - start_time_precalc))
	print(str("cluster calc time (ms) = ", end_time_calc - start_time_calc))
	print(str("neighbor calc time (ms) = ", end_time_neighbors - start_time_neighbors))

func expand_rect_from_coord_estimate_grid2d(cellv: Vector2, open_cells: Array):
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
	
	return Rect2(cellv.x-w, cellv.y-n, e+w+1, s+n+1)

func expand_rect_from_coord_estimate(cellv: Vector2, open_cells: Array):
	if(open_cells == null || open_cells.size() == 0):
		return null
	var n := 0
	var e := 0
	var s := 0
	var w := 0
	
	var expand_n := true
	var expand_e := true
	var expand_s := true
	var expand_w := true
	
	while(expand_n || expand_e || expand_s || expand_w):
		
		#NORTH
		if(expand_n):
			var y: int = cellv.y-n-1
			for x in range(cellv.x-w, cellv.x+e+1):
				if(!open_cells.has(Vector2(x,y))):
					expand_n = false
					break
			if(expand_n):
				n += 1
		
		#EAST
		if(expand_e):
			var x: int = cellv.x+e+1
			for y in range(cellv.y-n, cellv.y+s+1):
				if(!open_cells.has(Vector2(x,y))):
					expand_e = false
					break
			if(expand_e):
				e += 1
		
		#SOUTH
		if(expand_s):
			var y: int = cellv.y+s+1
			for x in range(cellv.x-w, cellv.x+e+1):
				if(!open_cells.has(Vector2(x,y))):
					expand_s = false
					break
			if(expand_s):
				s += 1
		
		#WEST
		if(expand_w):
			var x: int = cellv.x-w-1
			for y in range(cellv.y-n, cellv.y+s+1):
				if(!open_cells.has(Vector2(x,y))):
					expand_w = false
					break
			if(expand_w):
				w += 1
		
		# break early if rect is becoming to long along one axis
		# dual purpose: 
		#	1) improve speed by ending sooner
		#	2) lower ranking for stretched rects over square rects
		if(e+w+1 > (n+s+1)*2|| n+s+1 > (e+w+1)*2):
			break
	
	return Rect2(cellv.x-w, cellv.y-n, e+w+1, s+n+1)

func expand_rect_from_coord_grid2d(cellv: Vector2, open_cells: Array, contained_cells = null):
	if(open_cells == null || open_cells.size() == 0 || open_cells[cellv.x].size() == 0 || open_cells[cellv.x][cellv.y] == 0):
		return null
	var do_record_cells: bool = (contained_cells is Array)
	
	var n: int = 0
	var e: int = 0
	var s: int = 0
	var w: int = 0
	
	var expand_n := true
	var expand_e := true
	var expand_s := true
	var expand_w := true
	
	while(expand_n || expand_e || expand_s || expand_w):
		# block expansion of long 1d clusters
		if(e == 0 && w == 0):
			if(expand_n):
				# NE is blocked and E isn't
				var x = cellv.x+1
				var y= cellv.y-n-1
				if(x < open_cells.size()):
					var c_ne = open_cells[x][y] 
					var c_e = open_cells[x][y+1] 
					if((c_ne == 0 && c_e == 1) || (c_ne == 1 && c_e == 0)):
						expand_n = false
						#n -= 1
			if(expand_n):
				# NW is blocked and W isn't
				var x = cellv.x-1
				var y = cellv.y-n-1
				if(x < open_cells.size()):
					var c_nw = open_cells[x][y] 
					var c_w = open_cells[x][y+1] 
					if(c_nw == 0 && c_w == 1 || (c_nw == 1 && c_w == 0)):
						expand_n = false
						#n -= 1
			if(expand_s):
				# SE is blocked and E isn't
				var x = cellv.x+1
				var y = cellv.y+s+1
				if(x < open_cells.size()):
					var c_se = open_cells[x][y] 
					var c_e = open_cells[x][y-1] 
					if((c_se == 0 && c_e == 1) || (c_se == 1 && c_e == 0)):
						expand_s = false
						#s -= 1
			if(expand_s):
				# SW is blocked and W isn't
				var x = cellv.x-1
				var y = cellv.y+s+1
				if(x < open_cells.size()):
					var c_sw = open_cells[x][y] 
					var c_w = open_cells[x][y-1] 
					if(c_sw == 0 && c_w == 1 || (c_sw == 1 && c_w == 0)):
						expand_s = false
						#s -= 1
		
		if(n == 0 && s == 0):
			if(expand_e):
				# SE is blocked and S isn't
				var y = cellv.y+1
				var x = cellv.x+e+1
				if(y < open_cells.size()):
					var c_se = open_cells[x][y] 
					var c_s = open_cells[x-1][y] 
					if((c_se == 0 && c_s == 1) || (c_se == 1 && c_s == 0)):
						expand_e = false
						#e -= 1
			if(expand_e):
				# NE is blocked and N isn't
				var y = cellv.y-1
				var x = cellv.x+e+1
				if(y < open_cells.size()):
					var c_ne = open_cells[x][y] 
					var c_n = open_cells[x-1][y] 
					if(c_ne == 0 && c_n == 1 || (c_ne == 1 && c_n == 0)):
						expand_e = false
						#e -= 1
			if(expand_w):
				# SW is blocked and S isn't
				var y = cellv.y+1
				var x = cellv.x-w-1
				if(y < open_cells.size()):
					var c_sw = open_cells[x][y] 
					var c_s = open_cells[x+1][y] 
					if((c_sw == 0 && c_s == 1) || (c_sw == 1 && c_s == 0)):
						expand_w = false
						#w -= 1
			if(expand_w):
				# NW is blocked and N isn't
				var y = cellv.y-1
				var x = cellv.x-w-1
				if(y < open_cells.size()):
					var c_nw = open_cells[x][y] 
					var c_n = open_cells[x+1][y] 
					if(c_nw == 0 && c_n == 1 || (c_nw == 1 && c_n == 0)):
						expand_w = false
						#w -= 1
		
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

	if(do_record_cells):
		for x in range(cellv.x-w, cellv.x+e+1):
			for y in range(cellv.y-n, cellv.y+s+1):
				contained_cells.append(Vector2(x,y))
	
	return Rect2(cellv.x-w, cellv.y-n, e+w+1, s+n+1)

func expand_rect_from_coord(cellv: Vector2, open_cells: Array, contained_cells = null):
	if(open_cells == null || open_cells.size() == 0 || !open_cells.has(cellv)):
		return null
	var do_record_cells: bool = (contained_cells is Array)
	
	var n := 0
	var e := 0
	var s := 0
	var w := 0
	
	var expand_n := true
	var expand_e := true
	var expand_s := true
	var expand_w := true
	
	while(expand_n || expand_e || expand_s || expand_w):
		#NORTH
		if(expand_n):
			for x in range(cellv.x-w, cellv.x+e+1):
				if(!open_cells.has(Vector2(x, cellv.y-n-1))):
					expand_n = false
					break
			if(expand_n):
				n += 1
		
		#EAST
		if(expand_e):
			for y in range(cellv.y-n, cellv.y+s+1):
				if(!open_cells.has(Vector2(cellv.x+e+1, y))):
					expand_e = false
					break
			if(expand_e):
				e += 1
		
		#SOUTH
		if(expand_s):
			for x in range(cellv.x-w, cellv.x+e+1):
				if(!open_cells.has(Vector2(x, cellv.y+s+1))):
					expand_s = false
					break
			if(expand_s):
				s += 1
		
		#WEST
		if(expand_w):
			for y in range(cellv.y-n, cellv.y+s+1):
				if(!open_cells.has(Vector2(cellv.x-w-1, y))):
					expand_w = false
					break
			if(expand_w):
				w += 1
				
	if(do_record_cells):
		for x in range(cellv.x-w, cellv.x+e+1):
			for y in range(cellv.y-n, cellv.y+s+1):
				contained_cells.append(Vector2(x,y))
	
	return Rect2(cellv.x-w, cellv.y-n, e+w+1, s+n+1)

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
