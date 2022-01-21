class_name Utils

enum GRAPH_TYPE{RECTANGLES, QUADTREE, CHUNK, TILEMAP}

# create a 2d array of the navigable tiles for improved performance
static func tilemap_to_array2d(tilemap: TileMap) -> Array:
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
	
	return grid_2d

# intersection between a line and a rect, where p0 of the line is inside the rect
static func inner_line_to_rect_intersection(p0: Vector2, p1: Vector2, rect: Rect2):
	var v := p1 - p0
	
	var e := Vector2.ZERO
	if(v.x > 0):
		e.x = rect.position.x + rect.size.x
	else:
		e.x = rect.position.x
	
	if(v.y > 0):
		e.y = rect.position.y + rect.size.y
	else:
		e.y = rect.position.y
	
	if(v.x == 0):
		return Vector2(p0.x, e.y)
	if(v.y == 0):
		return Vector2(e.x, p0.y)
	
	var t = (e - p0)/v
	
	if(t.x <= t.y):
		return Vector2(e.x, p0.y + t.x*v.y)
	else:
		return Vector2(p0.x + t.y*v.x, e.y)

static func coord_to_id(coordv: Vector2) -> int:
	# Cantor Pairing function
	return ((coordv.x + coordv.y) * (coordv.x + coordv.y + 1)/2 + coordv.y) as int

static func id_to_coord(id: int) -> Vector2:
	# Inverted Cantor Pairing function
	var w = floor((sqrt(8*id+1) - 1)/2)
	var t = (pow(w,2) + w)/2
	var y = id - t
	var x = w - y
	return Vector2(x,y)
