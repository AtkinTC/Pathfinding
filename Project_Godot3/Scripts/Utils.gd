class_name Utils

# create a 2d array of the navigable tiles for improved performance
static func tilemap_to_array2d(tilemap: TileMap) -> Array:
	print("utils.tilemap_to_array2d()")
	var start_time = OS.get_ticks_msec()
	
	var used_rect := tilemap.get_used_rect()
	var col_0 := []
	col_0.resize((used_rect.position.y + used_rect.size.y) as int)
	for y in range(col_0.size()):
		col_0[y] = 0
		
	var grid_2d := []
	grid_2d.resize((used_rect.position.x + used_rect.size.x) as int)
	for x in range(grid_2d.size()):
		grid_2d[x] = col_0.duplicate()
	for cell in tilemap.get_used_cells():
		grid_2d[cell.x][cell.y] = 1
	
	var end_time = OS.get_ticks_msec()
	
	print(str("	tilemap_to_array2d duration (ms) = ", end_time - start_time))
	return grid_2d
