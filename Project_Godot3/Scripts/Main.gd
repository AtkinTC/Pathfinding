extends Node2D

onready var tile_map: TileMap = get_node("TileMap")

var tile_dim: Vector2

enum GRAPH_TYPE{RECTANGLES, QUADTREE, CHUNK, TILEMAP}

var nav_test_units := {}

var current_graph = GRAPH_TYPE.RECTANGLES

var start_coord: Vector2 = Vector2(-1,-1)
var end_coord: Vector2 = Vector2(-1,-1)

onready var ui: UI = get_node("UI")

func _ready() -> void:
	tile_dim = tile_map.get_cell_size()
	tile_map.show_behind_parent = true
	
	switch_mode(GRAPH_TYPE.RECTANGLES)

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
	
	if(event.is_action_pressed("ui_4")):
		if(current_graph != GRAPH_TYPE.CHUNK):
			switch_mode(GRAPH_TYPE.CHUNK)
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
			nav_test_units[GRAPH_TYPE.RECTANGLES] = NavTestUnit.new()
			nav_test_units[GRAPH_TYPE.RECTANGLES].set_nav_graph(NavRectExpansion.new())
			
		elif(graph_type == GRAPH_TYPE.QUADTREE):
			nav_test_units[GRAPH_TYPE.QUADTREE] = NavTestUnit.new()
			nav_test_units[GRAPH_TYPE.QUADTREE].set_nav_graph(NavQuadTree.new())
			
		elif(graph_type == GRAPH_TYPE.TILEMAP):
			nav_test_units[GRAPH_TYPE.TILEMAP] = NavTestUnit.new()
			nav_test_units[GRAPH_TYPE.TILEMAP].set_nav_graph(FakeNavClusterGraph.new())
		
		elif(graph_type == GRAPH_TYPE.CHUNK):
			nav_test_units[GRAPH_TYPE.CHUNK] = NavChunksTestUnit.new()
		
		var print_array := []
		nav_test_units[graph_type].set_tile_map(tile_map)
		nav_test_units[graph_type].setup_astar(print_array)
		nav_test_units[graph_type].build_graph(print_array)
		ui.print_lines(print_array)

func set_start_coord(coordv: Vector2):
	start_coord = coordv
	
func set_end_coord(coordv: Vector2):
	end_coord = coordv

func calculate_path(print_array = null):
	update()
	if(start_coord != Vector2(-1,-1) && end_coord != Vector2(-1,-1) && start_coord != end_coord):
		nav_test_units[current_graph].run_navigation(start_coord, end_coord, print_array)
		return true
	else:
		return false

func _draw() -> void:
	nav_test_units[current_graph].draw(self, tile_dim)
	
	# highlight the start and end cell coordinates
	if(start_coord != null):
		draw_rect(Rect2(start_coord * tile_dim, tile_dim), Color.white, true)
	if(end_coord != null):
		draw_rect(Rect2(end_coord * tile_dim, tile_dim), Color.black, true)
