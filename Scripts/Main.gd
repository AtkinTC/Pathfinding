extends Node2D

onready var tile_map: TileMap = get_node("TileMap")
onready var draw_node = get_node("DrawNode")

var tile_dim: Vector2

enum GRAPH_TYPE{RECTANGLES, QUADTREE, NONE}

var cluster_graphs := {}
var cluster_path := []
var current_graph = GRAPH_TYPE.RECTANGLES

var start_coord: Vector2
var end_coord: Vector2

var start_cluster: NavCluster
var end_cluster: NavCluster

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tile_dim = tile_map.get_cell_size()
	tile_map.show_behind_parent = true
	
	#rect_expansion = NavRectExpansion.new();
	
	cluster_graphs[GRAPH_TYPE.RECTANGLES] = NavRectExpansion.new()
	cluster_graphs[GRAPH_TYPE.QUADTREE] = NavQuadTree.new()
	cluster_graphs[GRAPH_TYPE.NONE] = FakeNavClusterGraph.new()
	
	for graph in cluster_graphs.values():
		graph.build_from_tilemap(tile_map)
	
	#dim = cluster_graph.base_cell.dim.x
	#pos = cluster_graph.base_cell.topleft

func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_pressed("ui_accept")):
		var mouse_pos := get_global_mouse_position()
		var coord := tile_map.world_to_map(mouse_pos)
		set_start_coord(coord)
		calculate_path()
	
	if(event.is_action_pressed("ui_cancel")):
		var mouse_pos := get_global_mouse_position()
		var coord := tile_map.world_to_map(mouse_pos)
		set_end_coord(coord)
		calculate_path()
	
	if(event.is_action_pressed("ui_1")):
		if(current_graph != GRAPH_TYPE.RECTANGLES):
			current_graph = GRAPH_TYPE.RECTANGLES
			calculate_path()
	
	if(event.is_action_pressed("ui_2")):
		if(current_graph != GRAPH_TYPE.QUADTREE):
			current_graph = GRAPH_TYPE.QUADTREE
			calculate_path()
	
	if(event.is_action_pressed("ui_3")):
		if(current_graph != GRAPH_TYPE.NONE):
			current_graph = GRAPH_TYPE.NONE
			calculate_path()

func set_start_coord(coordv: Vector2):
	start_coord = coordv
	
func set_end_coord(coordv: Vector2):
	end_coord = coordv

func calculate_path():
	start_cluster = null
	end_cluster = null
	cluster_path = []
	if(start_coord != null && end_coord != null && start_coord != end_coord):
		start_cluster = cluster_graphs[current_graph].get_cluster_containing_coord(start_coord)
		end_cluster = cluster_graphs[current_graph].get_cluster_containing_coord(end_coord)
		
		if(start_cluster != null && end_cluster != null):
			cluster_path = AStarClusters.run(start_cluster, end_cluster)
	update()

func _draw() -> void:
	#draw_rect(Rect2(pos*tile_dim, Vector2.ONE*dim*tile_dim), Color(0,0,0,1), false, 1.2)
	
	var highlight := Color.green
	highlight.a = 0.25
	
	for key in cluster_graphs[current_graph].get_clusters_dict().keys():
		# draw all clusters
		var cluster : NavCluster = cluster_graphs[current_graph].get_cluster(key)
		var rect = Rect2(cluster.topleft*tile_dim, Vector2.ONE*cluster.dim*tile_dim)
		draw_rect(rect, Color.green, false, 1)
		
		# draw cluster neighbor connections
		var cluster_center = (cluster.topleft + Vector2.ONE*cluster.dim/2) * tile_dim 
		for neighbor in cluster.neighbors:
			var neighbor_center = (neighbor.topleft + Vector2.ONE*neighbor.dim/2) * tile_dim 
			draw_line(cluster_center, neighbor_center ,Color.blue ,1.2)
	
	if(cluster_path != null && cluster_path.size() >= 2):
		# highlight path clusters
		for i in range(cluster_path.size()):
			draw_rect(Rect2(cluster_path[i].topleft*tile_dim, Vector2.ONE*cluster_path[i].dim*tile_dim), highlight, true)
	else:
		# highlight start and end clusters if there is no path calculated yet
		if(start_cluster):
			var rect = Rect2(start_cluster.topleft*tile_dim, Vector2.ONE*start_cluster.dim*tile_dim)
			draw_rect(rect, highlight, true)
		if(end_cluster && end_cluster != start_cluster):
			var rect = Rect2(end_cluster.topleft*tile_dim, Vector2.ONE*end_cluster.dim*tile_dim)
			draw_rect(rect, highlight, true)
	
	# highlight the start and end cell coordinates
	if(start_coord):
		draw_rect(Rect2(start_coord * tile_dim, tile_dim), Color.white, true)
	if(end_coord):
		draw_rect(Rect2(end_coord * tile_dim, tile_dim), Color.black, true)
	
	if(cluster_path != null && cluster_path.size() >= 2):
		# draw path cell-center to cell-center
		for i in range(cluster_path.size()-1):
			var center_a = (cluster_path[i].topleft + cluster_path[i].dim/2) * tile_dim
			var center_b = (cluster_path[i+1].topleft + cluster_path[i+1].dim/2) * tile_dim
			draw_line(center_a, center_b, Color.darkblue, 4)
		
		# draw path cell_edge to cell-edge (closer representation of eventual final path)
		var last_point: Vector2 = (cluster_path[0].topleft + cluster_path[0].dim/2) * tile_dim
		for i in range(cluster_path.size()):
			if(i == cluster_path.size()-1):
				var center_a = (cluster_path[i].topleft + cluster_path[i].dim/2) * tile_dim
				draw_line(last_point, center_a, Color.darkmagenta, 3)
			else:
				var center_a = (cluster_path[i].topleft + cluster_path[i].dim/2) * tile_dim
				var center_b = (cluster_path[i+1].topleft + cluster_path[i+1].dim/2) * tile_dim
				var rect = Rect2(cluster_path[i].topleft*tile_dim, cluster_path[i].dim*tile_dim)
				var intersect = inner_line_to_rect_intersection(center_a, center_b, rect)
				draw_line(last_point, intersect, Color.darkmagenta, 3)
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
