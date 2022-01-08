extends Node2D

onready var tile_map: TileMap = get_node("TileMap")
onready var draw_node = get_node("DrawNode")

var leaf_cells := {}
var used_map_tiles := []
var tile_dim: Vector2

var pos: Vector2
var dim: int

var quad_tree: NavQuadTree

var start_cell: NavQuadTree.QuadCell
var end_cell: NavQuadTree.QuadCell

var path: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tile_dim = tile_map.get_cell_size()
	tile_map.show_behind_parent = true
	
	quad_tree = NavQuadTree.new()
	quad_tree.build_from_tilemap(tile_map)
	
	dim = quad_tree.base_cell.dim.x
	pos = quad_tree.base_cell.topleft

func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_pressed("ui_accept")):
		var mouse_pos := get_global_mouse_position()
		var coord := tile_map.world_to_map(mouse_pos)
		set_start_cell_from_coord(coord)
	
	if(event.is_action_pressed("ui_cancel")):
		var mouse_pos := get_global_mouse_position()
		var coord := tile_map.world_to_map(mouse_pos)
		set_end_cell_from_coord(coord)

func set_start_cell_from_coord(coordv: Vector2):
	var cell: NavQuadTree.QuadCell = quad_tree.get_cluster_containing_coord(coordv)
	if(cell.traversable):
		start_cell = cell
		if(start_cell && end_cell && start_cell != end_cell):
			path = AStarClusters.A_Star(start_cell, end_cell)
		update()

func set_end_cell_from_coord(coordv: Vector2):
	var cell: NavQuadTree.QuadCell = quad_tree.get_cluster_containing_coord(coordv)
	if(cell.traversable):
		end_cell = cell
		if(start_cell && end_cell && start_cell != end_cell):
			path = AStarClusters.A_Star(start_cell, end_cell)
		update()

func _draw() -> void:
	draw_rect(Rect2(pos*tile_dim, Vector2.ONE*dim*tile_dim), Color(0,0,0,1), false, 1.2)
	
	for key in quad_tree.leaf_cells.keys():
		var cell : NavQuadTree.QuadCell = quad_tree.leaf_cells[key]
		
		var rect = Rect2(cell.topleft*tile_dim, Vector2.ONE*cell.dim*tile_dim)
		var color := Color.green
		if(!cell.traversable):
			color = Color.red
		
		var cell_center = (cell.topleft + Vector2.ONE*cell.dim/2) * tile_dim 
		for neighbor in cell.neighbors:
			var neighbor_center = (neighbor.topleft + Vector2.ONE*neighbor.dim/2) * tile_dim 
			draw_line(cell_center, neighbor_center ,Color.blue ,1.2)
		
		# highlight start and end cells
		draw_rect(rect, color, false, 1)
		if(cell == start_cell):
			color.a = 0.5
			draw_rect(rect, color, true)
		elif(cell == end_cell):
			color = Color.red
			color.a=0.5
			draw_rect(rect, color, true)
	
	if(path != null && path.size() >= 2):
		# draw path cell-center to cell-center
		for i in range(path.size()-1):
			var center_a = (path[i].topleft + path[i].dim/2) * tile_dim
			var center_b = (path[i+1].topleft + path[i+1].dim/2) * tile_dim
			draw_line(center_a, center_b, Color.darkblue, 4)
		
		# draw path cell_edge to cell-edge (closer representation of eventual final path)
		var last_point: Vector2 = (path[0].topleft + path[0].dim/2) * tile_dim
		for i in range(path.size()):
			if(i == path.size()-1):
				var center_a = (path[i].topleft + path[i].dim/2) * tile_dim
				draw_line(last_point, center_a, Color.darkmagenta, 4)
			else:
				var center_a = (path[i].topleft + path[i].dim/2) * tile_dim
				var center_b = (path[i+1].topleft + path[i+1].dim/2) * tile_dim
				var rect = Rect2(path[i].topleft*tile_dim, path[i].dim*tile_dim)
				var intersect = inner_line_to_rect_intersection(center_a, center_b, rect)
				draw_line(last_point, intersect, Color.darkmagenta, 4)
				last_point = intersect

# intersection between a line and a rect, where p0 of the line is inside the rect
func inner_line_to_rect_intersection(p0: Vector2, p1: Vector2, rect: Rect2):
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
