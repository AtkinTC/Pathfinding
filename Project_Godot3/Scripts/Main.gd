extends Node2D

onready var tile_map: TileMap = get_node("TileMap")
onready var draw_node = get_node("DrawNode")

var tile_dim: Vector2

enum GRAPH_TYPE{RECTANGLES, QUADTREE, NONE}

var version: int = 2

var cluster_graphs := {}
var cluster_path := []
var inner_cluster_paths := {}
var current_graph = GRAPH_TYPE.RECTANGLES

var astar_cluster_v2s := {}

var astar_tilemap_v2: AStarTileMapV2

var start_coord: Vector2 = Vector2(-1,-1)
var end_coord: Vector2 = Vector2(-1,-1)

var start_cluster: NavCluster
var end_cluster: NavCluster

var computed_cells := []

func _ready() -> void:
	tile_dim = tile_map.get_cell_size()
	tile_map.show_behind_parent = true
	
	cluster_graphs[GRAPH_TYPE.RECTANGLES] = NavRectExpansion.new()
	cluster_graphs[GRAPH_TYPE.QUADTREE] = NavQuadTree.new()
	cluster_graphs[GRAPH_TYPE.NONE] = FakeNavClusterGraph.new()
	
	for type in cluster_graphs.keys():
		cluster_graphs[type].build_from_tilemap(tile_map)
		astar_cluster_v2s[type] = AStarClustersV2.new()
		astar_cluster_v2s[type].add_clusters(cluster_graphs[type].get_clusters_dict().values())
	
	astar_tilemap_v2 = AStarTileMapV2.new()
	astar_tilemap_v2.add_points_from_tile_map(tile_map)
	
	#for graph in cluster_graphs.values():
	#	graph.build_from_tilemap(tile_map)
	
func _process(delta: float) -> void:
	for i in range(100):
		calculate_path()

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
			version = 2
		else:
			version = (version % 2) + 1	
		calculate_path()
	
	if(event.is_action_pressed("ui_2")):
		if(current_graph != GRAPH_TYPE.QUADTREE):
			current_graph = GRAPH_TYPE.QUADTREE
			version = 2
		else:
			version = (version % 2) + 1	
		calculate_path()
	
	if(event.is_action_pressed("ui_3")):
		if(current_graph != GRAPH_TYPE.NONE):
			current_graph = GRAPH_TYPE.NONE
			version = 2
		else:
			version = (version % 2) + 1	
		calculate_path()

func set_start_coord(coordv: Vector2):
	print(str("start coord = ", coordv))
	start_coord = coordv
	
func set_end_coord(coordv: Vector2):
	print(str("end coord = ", coordv))
	end_coord = coordv

func calculate_path():
	start_cluster = null
	end_cluster = null
	cluster_path = []
	inner_cluster_paths = {}
	computed_cells = []
	if(start_coord != Vector2(-1,-1) && end_coord != Vector2(-1,-1) && start_coord != end_coord):
		start_cluster = cluster_graphs[current_graph].get_cluster_containing_coord(start_coord)
		end_cluster = cluster_graphs[current_graph].get_cluster_containing_coord(end_coord)
		
		if(start_cluster != null && end_cluster != null):
			if(version == 1):
				cluster_path = AStarClusters.run(start_cluster, end_cluster)
			elif(version == 2):
				cluster_path = astar_cluster_v2s[current_graph].run(start_cluster, end_cluster)
		
		if(cluster_path.size() == 1):
			var cluster = cluster_path[0]
			var path := []
			if(current_graph == GRAPH_TYPE.NONE):
				if(version == 1):
					# Normal A* without clusters
					path = AStarTileMap.run(start_coord, end_coord, tile_map, computed_cells)
				elif(version == 2):
					path = astar_tilemap_v2.run(start_coord, end_coord)
			else:
				# Simple navigation across rectangular clusters
				path = InnerClusterNavigation.run(start_coord, end_coord, Rect2(cluster.topleft, cluster.dim))
			inner_cluster_paths[cluster_path[0].id] = path
			
		elif(cluster_path.size() > 1):
			for i in range(cluster_path.size()):
				var cluster = cluster_path[i]
				
				var point_a: Vector2
				if(i == 0):
					point_a = start_coord
				else:
					point_a = inner_cluster_paths[cluster_path[i-1].id][-1]
				
				var point_b: Vector2
				if(i >= cluster_path.size()-2):
					point_b = end_coord
				else:
					var cluster_n: NavCluster = cluster_path[i+1]
					point_b = cluster_path[i+1].topleft + Vector2(floor(cluster_n.dim.x/2),floor(cluster_n.dim.y/2))
				
				var path := []
				if(current_graph == GRAPH_TYPE.NONE):
					if(version == 1):
						# Normal A* without clusters
						path = AStarTileMap.run(start_coord, end_coord, tile_map, computed_cells)
					elif(version == 2):
						path = astar_tilemap_v2.run(start_coord, end_coord)
				else:
					# Simple navigation across rectangular clusters
					path = InnerClusterNavigation.run(point_a, point_b, Rect2(cluster.topleft, cluster.dim))
				inner_cluster_paths[cluster_path[i].id] = path
		
	update()

func _draw() -> void:
	var highlight := Color.green
	highlight.a = 0.25
	
	var highlight2 := Color.yellow
	highlight2.a = 0.5
	
	var highlight3 := Color.red
	highlight3.a = 0.25
	
	var inner_paths_joined = []
	for cluster in cluster_path:
		var inner_path: Array = inner_cluster_paths[cluster.id]
		inner_paths_joined.append_array(inner_path)
	
	# highlight the individual map tiles that are touched by the route
	for cell in inner_paths_joined:
			draw_rect(Rect2(cell * tile_dim, tile_dim), highlight2, true)
	
	# highlight the computed cells (when available)
#	for cell in computed_cells:
#		if(!inner_paths_joined.has(cell)):
#			draw_rect(Rect2(cell * tile_dim, tile_dim), highlight3, true)
	
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
	
	if(current_graph != GRAPH_TYPE.NONE):
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
	if(start_coord != null):
		draw_rect(Rect2(start_coord * tile_dim, tile_dim), Color.white, true)
	if(end_coord != null):
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
	
	# draw path map-tile to map-tile
	for i in range(inner_paths_joined.size()-1):
		var center_a: Vector2 = inner_paths_joined[i]*tile_dim + tile_dim/2
		var center_b: Vector2 = inner_paths_joined[i+1]*tile_dim + tile_dim/2
		draw_line(center_a, center_b, Color.darkgreen, 3)

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
