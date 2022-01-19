extends Node2D

onready var tile_map: TileMap = get_node("TileMap")

var tile_dim: Vector2

enum GRAPH_TYPE{RECTANGLES, QUADTREE, CHUNK, TILEMAP}

var cluster_graphs := {}
var cluster_path := []
var tiles_path := []
var current_graph = GRAPH_TYPE.RECTANGLES

var astar_cluster := {}

var astar_tilemap: AStarTileMap

var start_coord: Vector2 = Vector2(-1,-1)
var end_coord: Vector2 = Vector2(-1,-1)

var start_cluster: NavCluster
var end_cluster: NavCluster

onready var ui: UI = get_node("UI")

func _ready() -> void:
	tile_dim = tile_map.get_cell_size()
	tile_map.show_behind_parent = true
	
	switch_mode(GRAPH_TYPE.RECTANGLES)
	
	astar_tilemap = AStarTileMap.new()
	astar_tilemap.add_points_from_tile_map(tile_map)

func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_pressed("ui_select")):
		var mouse_pos := get_global_mouse_position()
		var coord := tile_map.world_to_map(mouse_pos)
		set_start_coord(coord)
		trigger_path_calculation()
	
	if(event.is_action_pressed("ui_cancel")):
		var mouse_pos := get_global_mouse_position()
		var coord := tile_map.world_to_map(mouse_pos)
		set_end_coord(coord)
		trigger_path_calculation()
	
	if(event.is_action_pressed("ui_accept")):
		batch_path_calculation_test(100)
	
	if(event.is_action_pressed("ui_1")):
		if(current_graph != GRAPH_TYPE.RECTANGLES):
			switch_mode(GRAPH_TYPE.RECTANGLES)
		trigger_path_calculation()
	
	if(event.is_action_pressed("ui_2")):
		if(current_graph != GRAPH_TYPE.QUADTREE):
			switch_mode(GRAPH_TYPE.QUADTREE)
		trigger_path_calculation()
	
	if(event.is_action_pressed("ui_3")):
		if(current_graph != GRAPH_TYPE.TILEMAP):
			switch_mode(GRAPH_TYPE.TILEMAP)
		trigger_path_calculation()

func batch_path_calculation_test(runs: int):
	var start_time = OS.get_ticks_msec()
	
	var pathfinding_was_run := true
	for _i in range(runs):
		pathfinding_was_run = calculate_path()
		if(!pathfinding_was_run):
			break
		
	var end_time = OS.get_ticks_msec()
	if(pathfinding_was_run):
		ui.print_line(str("duration of ", runs, " calls (ms) = ", end_time - start_time))

func trigger_path_calculation():
	var print_array := []
	print_array.append(str("start = ", start_coord, ", end = ", end_coord))
	calculate_path(print_array)
	ui.print_lines(print_array)

func switch_mode(graph_type: int):
	if(graph_type in GRAPH_TYPE.values()):
		current_graph = graph_type
		if(graph_type == GRAPH_TYPE.RECTANGLES):
			cluster_graphs[GRAPH_TYPE.RECTANGLES] = NavRectExpansion.new()
			
		elif(graph_type == GRAPH_TYPE.QUADTREE):
			cluster_graphs[GRAPH_TYPE.QUADTREE] = NavQuadTree.new()
			
		elif(graph_type == GRAPH_TYPE.TILEMAP):
			cluster_graphs[GRAPH_TYPE.TILEMAP] = FakeNavClusterGraph.new()
		
		var print_array := []
		cluster_graphs[graph_type].build_from_tilemap(tile_map, print_array)
		ui.print_lines(print_array)
		astar_cluster[graph_type] = AStarClusters.new()
		astar_cluster[graph_type].add_clusters(cluster_graphs[graph_type].get_clusters_dict().values())

func set_start_coord(coordv: Vector2):
	start_coord = coordv
	
func set_end_coord(coordv: Vector2):
	end_coord = coordv

func calculate_path(print_array = null):
	start_cluster = null
	end_cluster = null
	cluster_path = []
	tiles_path = []
	update()
	if(start_coord != Vector2(-1,-1) && end_coord != Vector2(-1,-1) && start_coord != end_coord):
		start_cluster = cluster_graphs[current_graph].get_cluster_containing_coord(start_coord)
		end_cluster = cluster_graphs[current_graph].get_cluster_containing_coord(end_coord)
		
		if(start_cluster != null && end_cluster != null):
			cluster_path = astar_cluster[current_graph].run(start_cluster, end_cluster)
		
		for i in range(cluster_path.size()):
			var cluster = cluster_path[i]
			var path := []
			if(current_graph == GRAPH_TYPE.TILEMAP):
				path = astar_tilemap.run(start_coord, end_coord)
			else:
				var point_a: Vector2
				if(i == 0):
					point_a = start_coord
				else:
					point_a = tiles_path[-1]
				
				var point_b: Vector2
				if(i >= cluster_path.size()-2):
					point_b = end_coord
				else:
					var cluster_n: NavCluster = cluster_path[i+1]
					point_b = cluster_path[i+1].topleft + Vector2(floor(cluster_n.dim.x/2),floor(cluster_n.dim.y/2))
				
				path = InnerClusterNavigation.run(point_a, point_b, Rect2(cluster.topleft, cluster.dim))
			tiles_path.append_array(path)
		
		if(print_array is Array):
			print_array.append(str("# of clusters in path = ", cluster_path.size()))
			print_array.append(str("# of tiles in path = ", tiles_path.size()))
		return true
	else:
		return false

func _draw() -> void:
	var highlight := Color.green
	highlight.a = 0.25
	
	var highlight2 := Color.yellow
	highlight2.a = 0.5
	
	var highlight3 := Color.red
	highlight3.a = 0.25
	
	# highlight the individual map tiles that are touched by the route
	for cell in tiles_path:
			draw_rect(Rect2(cell * tile_dim, tile_dim), highlight2, true)
	
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
	
	if(current_graph != GRAPH_TYPE.TILEMAP):
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
				var intersect = Utils.inner_line_to_rect_intersection(center_a, center_b, rect)
				draw_line(last_point, intersect, Color.darkmagenta, 3)
				last_point = intersect
	
	# draw path map-tile to map-tile
	for i in range(tiles_path.size()-1):
		var center_a: Vector2 = tiles_path[i]*tile_dim + tile_dim/2
		var center_b: Vector2 = tiles_path[i+1]*tile_dim + tile_dim/2
		draw_line(center_a, center_b, Color.darkgreen, 3)

				
