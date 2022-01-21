class_name NavChunksGraph

class Chunk:
	var id: Vector2
	var topleft: Vector2
	var dim: Vector2
	
	var inner_nodes := {}
	
	var closest_node_map := {}
	
	func _init(_id: Vector2, _topleft: Vector2, _dim: Vector2):
		id = _id
		topleft = _topleft
		dim = _dim
	
	func add_node(inner_node: InnerNode):
		inner_nodes[inner_node.id] = inner_node
	
	func get_closest_inner_node_id(coordv: Vector2):
		if(inner_nodes.size() == 0):
			return null
		elif(inner_nodes.size() == 1):
			return inner_nodes.keys()[0]
		else:
			return closest_node_map.get(coordv)

class InnerNode:
	var id: int
	var chunk_id: Vector2
	var pos: Vector2
	
	func _init(_id: int, _chunk_id: Vector2, _pos: Vector2):
		id = _id
		chunk_id = _chunk_id
		pos = _pos

var chunks := {}

var nodes_graph := Graph.new()

var chunk_size := Vector2(4,4)

func reset():
	chunks = {}
	nodes_graph = Graph.new()

func get_chunk_size() -> Vector2:
	return chunk_size

func get_chunk(id: Vector2):
	return chunks.get(id)

func get_chunks_dict() -> Dictionary:
	return chunks

func get_nodes_graph() -> Graph:
	return nodes_graph

func get_chunk_id_containing_coord(coordv: Vector2):
	var chunk_coord = Vector2(floor(coordv.x/chunk_size.x), floor(coordv.y/chunk_size.y))
	if(chunks.has(chunk_coord)):
		return chunk_coord
	return null

func build_from_tilemap(tilemap: TileMap, print_array = null):
	chunks = {}
	
	var grid_2d := Utils.tilemap_to_array2d(tilemap)
	var tilemap_rect := tilemap.get_used_rect()
	
	var tile_map_size := tilemap_rect.position + tilemap_rect.size
	
	var chunked_grid_size := Vector2(ceil(tile_map_size.x/chunk_size.x), ceil(tile_map_size.y/chunk_size.y))
	
	for x in range(chunked_grid_size.x):
		for y in range(chunked_grid_size.y):
			
			var topleft = Vector2(x,y)*chunk_size
			var traversable := false
			for inner_x in range(topleft.x, min(topleft.x + chunk_size.x, tilemap_rect.size.x)):
				for inner_y in range(topleft.y, min(topleft.y + chunk_size.y, tilemap_rect.size.y)):
					if(grid_2d[topleft.x][topleft.y] > 0):
						traversable = true
						break
			
			var chunk := Chunk.new(Vector2(x,y), topleft, chunk_size)
			chunks[Vector2(x,y)] = chunk
	
	for x in range(chunked_grid_size.x):
		for y in range(chunked_grid_size.y):
			var chunk: Chunk = chunks[Vector2(x,y)]
			
			var nw = Vector2(x,y) * chunk_size
			var se = nw + chunk_size - Vector2.ONE
			
			#EAST
			var east_chunk = chunks.get(Vector2(x+1,y), null)
			if(east_chunk != null):
				var last_y = -1
				for inner_y in range(chunk_size.y+1):
					if(se.x+1 >= grid_2d.size()):
						break
					if(inner_y == chunk_size.y || nw.y+inner_y >= grid_2d[0].size()
						|| grid_2d[se.x][nw.y+inner_y] == 0 || grid_2d[se.x+1][nw.y+inner_y] == 0):
						#connecting span [last_y, inner_y]
						var span_length = inner_y - last_y - 1
						if(span_length > 0):
							var mid_y: int = last_y + ceil(span_length/2)+1
							
							var inner_node_pos := Vector2(chunk_size.x-1, mid_y)
							var inner_node_id := Utils.coord_to_id(chunk.id * chunk_size + inner_node_pos)
							var inner_node := InnerNode.new(inner_node_id, chunk.id, chunk.id * chunk_size + inner_node_pos)
							chunk.add_node(inner_node)
							nodes_graph.insert_node(inner_node.id, inner_node)
							
							var east_node_pos := Vector2(0, mid_y)
							var east_node_id := Utils.coord_to_id(east_chunk.id * chunk_size + east_node_pos)
							var east_node := InnerNode.new(east_node_id, east_chunk.id, east_chunk.id * chunk_size + east_node_pos)
							east_chunk.add_node(east_node)
							nodes_graph.insert_node(east_node.id, east_node)
							
							nodes_graph.connect_nodes(inner_node.id, east_node.id, 1)
							
						last_y = inner_y
			
			#SOUTH
			var south_chunk = chunks.get(Vector2(x,y+1), null)
			if(south_chunk != null):
				var last_x = -1
				for inner_x in range(chunk_size.x+1):
					if(se.y+1 >= grid_2d[0].size()):
						break
					if(inner_x == chunk_size.x || nw.x+inner_x >= grid_2d.size()
						|| grid_2d[nw.x+inner_x][se.y] == 0 || grid_2d[nw.x+inner_x][se.y+1] == 0):
						#connecting span [last_x, inner_x]
						var span_length = inner_x - last_x - 1
						if(span_length > 0):
							var mid_x: int = last_x + ceil(span_length/2)+1
							
							var inner_node_pos := Vector2(mid_x, chunk_size.y-1)
							var inner_node_id := Utils.coord_to_id(chunk.id * chunk_size + inner_node_pos)
							var inner_node := InnerNode.new(inner_node_id, chunk.id, chunk.id * chunk_size + inner_node_pos)
							chunk.add_node(inner_node)
							nodes_graph.insert_node(inner_node.id, inner_node)
							
							
							var south_node_pos := Vector2(mid_x, 0)
							var south_node_id := Utils.coord_to_id(south_chunk.id * chunk_size + south_node_pos)
							var south_node := InnerNode.new(south_node_id, south_chunk.id, south_chunk.id * chunk_size + south_node_pos)
							south_chunk.add_node(south_node)
							nodes_graph.insert_node(south_node.id, south_node)
							
							nodes_graph.connect_nodes(inner_node.id, south_node.id, 1)
						last_x = inner_x
	
	# find node connections inside each chunk		
	for x in range(chunked_grid_size.x):
		for y in range(chunked_grid_size.y):
			var chunk: Chunk = chunks[Vector2(x,y)]
			var nw = Vector2(x,y) * chunk_size
			var se = nw + chunk_size - Vector2.ONE
			
			if(chunk.inner_nodes.size() > 1):
				
				#build map of closest nodes within the chunk
				var closest_node := {}
				var closest_node_distance := {}
				
				for node_id in chunk.inner_nodes.keys():
					var node: InnerNode = chunk.inner_nodes[node_id]
					var start_cell: Vector2 = node.pos
					var open_cell := [start_cell]
					var cell_d := {start_cell: 0}
					
					closest_node[start_cell] = node_id
					closest_node_distance[start_cell] = 0
					
					while(!open_cell.empty()):
						var cell = open_cell.pop_front()
						for neighbor in [cell+Vector2.RIGHT, cell+Vector2.DOWN, cell+Vector2.LEFT, cell+Vector2.UP]:
							if(neighbor.x < nw.x || neighbor.y < nw.y || neighbor.x > se.x || neighbor.y > se.y):
								continue
							if(neighbor.x < 0 || neighbor.y < 0 || neighbor.x >= grid_2d.size() || neighbor.y >= grid_2d[0].size()):
								continue
							if(grid_2d[neighbor.x][neighbor.y] == 0):
								continue
							if(!cell_d.has(neighbor) || cell_d[neighbor] > cell_d[cell] + 1):
								open_cell.append(neighbor)
								cell_d[neighbor] = cell_d[cell] + 1
								
								if(closest_node_distance.get(neighbor) == null || closest_node_distance.get(neighbor) > cell_d[neighbor]):
									closest_node[neighbor] = node_id
									closest_node_distance[neighbor] = cell_d[neighbor]
					
					for other_node in chunk.inner_nodes.values():
						if(other_node == node || nodes_graph.has_connection(node.id, other_node.id)):
							continue
						var other_cell = other_node.pos
						if(cell_d.has(other_cell)):
							var distance = cell_d[other_cell]
							nodes_graph.connect_nodes(node.id, other_node.id, distance)
				
				chunk.closest_node_map = closest_node

