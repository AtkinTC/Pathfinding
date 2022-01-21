extends Node2D

onready var tile_map: TileMap = get_node("TileMap")
onready var tile_map_path: String = tile_map.filename

var tile_dim: Vector2

var nav_test_units := {}

var current_graph = Utils.GRAPH_TYPE.RECTANGLES

var start_coord: Vector2 = Vector2(-1,-1)
var end_coord: Vector2 = Vector2(-1,-1)

onready var ui: UI = get_node("UI")

func _ready() -> void:
	tile_dim = tile_map.get_cell_size()
	tile_map.show_behind_parent = true
	build_graph()

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
		if(current_graph != Utils.GRAPH_TYPE.RECTANGLES):
			switch_mode(Utils.GRAPH_TYPE.RECTANGLES)
		trigger_path_calculation()
	
	if(event.is_action_pressed("ui_2")):
		if(current_graph != Utils.GRAPH_TYPE.QUADTREE):
			switch_mode(Utils.GRAPH_TYPE.QUADTREE)
		trigger_path_calculation()
	
	if(event.is_action_pressed("ui_3")):
		if(current_graph != Utils.GRAPH_TYPE.TILEMAP):
			switch_mode(Utils.GRAPH_TYPE.TILEMAP)
		trigger_path_calculation()
	
	if(event.is_action_pressed("ui_4")):
		if(current_graph != Utils.GRAPH_TYPE.CHUNK):
			switch_mode(Utils.GRAPH_TYPE.CHUNK)
		trigger_path_calculation()

func set_map(map_key: String):
	var new_tile_map_path = Utils.MAPS.get(map_key)
	if(new_tile_map_path == null):
		return false
	if(new_tile_map_path == tile_map_path):
		return false
	
	var new_tile_map = load(new_tile_map_path).instance()
	if(new_tile_map is TileMap):
		remove_child(tile_map)
		tile_map = new_tile_map
		add_child(tile_map)
		move_child(tile_map, 0)
		tile_dim = tile_map.get_cell_size()
		tile_map.show_behind_parent = true
		
		nav_test_units = {}
		set_start_coord(-Vector2.ONE)
		set_end_coord(-Vector2.ONE)
		build_graph()

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
	calculate_path(print_array)
	ui.print_lines(print_array)

func switch_mode(graph_type: int):
	if(graph_type != current_graph && graph_type in Utils.GRAPH_TYPE.values()):
		current_graph = graph_type
		
		if(nav_test_units.get(current_graph) == null):
			build_graph()
		else:
			update()
			trigger_path_calculation()
		
func build_graph():
	if(current_graph == Utils.GRAPH_TYPE.RECTANGLES):
			nav_test_units[current_graph] = NavTestUnit.new()
			nav_test_units[current_graph].set_nav_graph(NavRectExpansion.new())
			
	elif(current_graph == Utils.GRAPH_TYPE.QUADTREE):
		nav_test_units[current_graph] = NavTestUnit.new()
		nav_test_units[current_graph].set_nav_graph(NavQuadTree.new())
		
	elif(current_graph == Utils.GRAPH_TYPE.TILEMAP):
		nav_test_units[current_graph] = NavTestUnit.new()
		nav_test_units[current_graph].set_nav_graph(FakeNavClusterGraph.new())
	
	elif(current_graph == Utils.GRAPH_TYPE.CHUNK):
		nav_test_units[current_graph] = NavChunksTestUnit.new()
	
	var print_array := []
	print_array.append("")
	nav_test_units[current_graph].set_tile_map(tile_map)
	nav_test_units[current_graph].setup_astar(print_array)
	nav_test_units[current_graph].build_graph(print_array)
	ui.print_lines(print_array)
	trigger_path_calculation()
	update()

func set_start_coord(coordv: Vector2):
	start_coord = coordv
	
func set_end_coord(coordv: Vector2):
	end_coord = coordv

func calculate_path(print_array = null):
	update()
	if(start_coord != Vector2(-1,-1) && end_coord != Vector2(-1,-1) && start_coord != end_coord):
		if(print_array is Array):
			print_array.append(str("start = ", start_coord, ", end = ", end_coord))
		nav_test_units[current_graph].run_navigation(start_coord, end_coord, print_array)
		return true
	else:
		nav_test_units[current_graph].clear_navigation()
		return false

func _draw() -> void:
	nav_test_units[current_graph].draw(self, tile_dim)
	
	# highlight the start and end cell coordinates
	if(start_coord != null):
		draw_rect(Rect2(start_coord * tile_dim, tile_dim), Color.white, true)
	if(end_coord != null):
		draw_rect(Rect2(end_coord * tile_dim, tile_dim), Color.black, true)

func _on_Rebuild_pressed() -> void:
	pass # Replace with function body.

func _on_GraphTypeSelection_item_selected(index: int) -> void:
	pass # Replace with function body.

func _on_UI_graph_type_selection(graph_type: int) -> void:
	switch_mode(graph_type)

func _on_UI_trigger_rebuild() -> void:
	build_graph()

func _on_UI_trigger_navigation_batch(batch_size: int) -> void:
	batch_path_calculation_test(batch_size)

func _on_UI_trigger_clear_navigation() -> void:
	set_start_coord(-Vector2.ONE)
	set_end_coord(-Vector2.ONE)
	calculate_path()
	
func _on_UI_map_selection(map_key: String) -> void:
	set_map(map_key)
