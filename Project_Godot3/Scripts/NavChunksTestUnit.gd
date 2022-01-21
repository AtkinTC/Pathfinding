extends Node
class_name NavChunksTestUnit

var tile_map: TileMap

var nav_graph: NavChunksGraph = NavChunksGraph.new()
var astar_nodes: AStar2D
var astar_tilemap: AStarTileMap

var path_node_ids := []
var path_tiles := []

func set_tile_map(_tile_map: TileMap):
	tile_map = _tile_map

func setup_astar(print_array = null):
	if !(tile_map is TileMap):
		return null
	astar_tilemap = AStarTileMap.new()
	astar_tilemap.build_points_from_tile_map(tile_map, print_array)

func build_graph(print_array = null):
	if !(nav_graph is NavChunksGraph && tile_map is TileMap):
		return null
		
	nav_graph.reset()
	nav_graph.chunk_size = Vector2(6, 6)
	nav_graph.build_from_tilemap(tile_map, print_array)
	
	astar_nodes = AStar2D.new()
	
	astar_nodes.clear()
	if(nav_graph.nodes_graph.get_nodes().size() > astar_nodes.get_point_capacity()):
		astar_nodes.reserve_space(nav_graph.nodes_graph.get_nodes().size())
	
	for id in nav_graph.nodes_graph.get_node_ids():
		var node: NavChunksGraph.InnerNode = nav_graph.nodes_graph.get_node(id)
		astar_nodes.add_point(node.id, node.pos)
	
	for id in nav_graph.nodes_graph.get_node_ids():
		for neighbor_id in nav_graph.nodes_graph.get_connections(id):
			if(astar_nodes.has_point(neighbor_id)):
				astar_nodes.connect_points(id, neighbor_id)

func clear_navigation():
	path_node_ids = []
	path_tiles = []

func run_navigation(_start_coord: Vector2, _end_coord: Vector2, print_array = null):
	clear_navigation()
	if(_start_coord == _end_coord):
		return false
		
	var start_chunk_id: Vector2 = nav_graph.get_chunk_id_containing_coord(_start_coord)
	var end_chunk_id: Vector2 = nav_graph.get_chunk_id_containing_coord(_end_coord)
	
	if(start_chunk_id == null || end_chunk_id == null):
		return false
	
	var start_node_id: int = nav_graph.get_chunk(start_chunk_id).get_closest_inner_node_id(_start_coord)
	var end_node_id: int = nav_graph.get_chunk(end_chunk_id).get_closest_inner_node_id(_end_coord)
	
	if(start_node_id == null || end_node_id == null):
		return false
	
	path_node_ids = astar_nodes.get_id_path(start_node_id, end_node_id)
	
	for i in range(path_node_ids.size()):
		var node_id = path_node_ids[i]
		var path := []
		
		var point_a: Vector2
		if(i == 0):
			point_a = _start_coord
		else:
			point_a = path_tiles[-1]

		var point_b: Vector2
		if(i >= path_node_ids.size()-2):
			point_b = _end_coord
		else:
			var next_node: NavChunksGraph.InnerNode = nav_graph.nodes_graph.get_node(path_node_ids[i+1])
			point_b = next_node.pos
		
		path = astar_tilemap.run(point_a, point_b)
		path_tiles.append_array(path)
	
	if(print_array is Array):
		print_array.append(str("# of nodes in path = ", path_node_ids.size()))
		print_array.append(str("# of tiles in path = ", path_tiles.size()))
	return true

func draw(node: Node, tile_dim: Vector2) -> void:
	var highlight := Color.green
	highlight.a = 0.25
	
	var highlight2 := Color.yellow
	highlight2.a = 0.33
	
	var highlight3 := Color.red
	highlight3.a = 0.25
	
	# highlight the individual map tiles that are touched by the route
	for cell in path_tiles:
		node.draw_rect(Rect2(cell * tile_dim, tile_dim), highlight2, true)
	
	for chunk_id in nav_graph.get_chunks_dict().keys():
		var chunk: NavChunksGraph.Chunk = nav_graph.get_chunks_dict()[chunk_id]
		node.draw_rect(Rect2(chunk.topleft*tile_dim, nav_graph.get_chunk_size()*tile_dim), Color.white, false)
	
	var drawn_node_ids = []
	
	for i_node in nav_graph.nodes_graph.get_nodes():
		#var i_node: NavChunksGraph.InnerNode = nav_graph.nodes_graph.get_node(id)
		var mid: Vector2 = (i_node.pos + Vector2(0.5, 0.5)) * tile_dim
		node.draw_circle(mid, tile_dim.x/3, Color(1,0,0,0.5))
		
		for n_id in nav_graph.nodes_graph.get_connections(i_node.id):
			if(!drawn_node_ids.has(n_id)):
				var n_node: NavChunksGraph.InnerNode = nav_graph.nodes_graph.get_node(n_id)
				var n_mid: Vector2 = (n_node.pos + Vector2(0.5, 0.5)) * tile_dim
				node.draw_line(mid, n_mid, Color(1,0,0,1), 1.1)
			
		drawn_node_ids.append(i_node.id)
	
	# draw path map-tile to map-tile
	for i in range(path_tiles.size()-1):
		var center_a: Vector2 = path_tiles[i]*tile_dim + tile_dim/2
		var center_b: Vector2 = path_tiles[i+1]*tile_dim + tile_dim/2
		node.draw_line(center_a, center_b, Color.darkgreen, 2)
