class_name NavQuadTree
extends NavClusterGraph

class QuadCell extends NavCluster:
	var traversable: bool = false
	var leaf: bool = false
	var parent: QuadCell
	var children: Dictionary
	
	func _init(_id: String, _topleft: Vector2, _dim: Vector2).(_id, _topleft, _dim):
		pass
	
	func get_id_x():
		if(id == ""):
			return id
		return id.substr(0, id.length()/2)
		
	func get_id_y():
		if(id == ""):
			return id
		return id.substr(id.length()/2, -1)

var leaf_cells := {}
var clusters := {}
var base_cell: QuadCell

var traversable_map_tiles := []

func reset():
	leaf_cells = {}
	clusters = {}
	traversable_map_tiles = []
	base_cell = QuadCell.new("", Vector2.ZERO, Vector2.ZERO)

func get_cluster(_id: String):
	return leaf_cells.get(_id)

func get_clusters_dict():
	return clusters

func get_cluster_containing_coord(_coordv: Vector2):
	# check if the coord is contained in the tree
	if(_coordv.x < base_cell.topleft.x || _coordv.x >= base_cell.topleft.x + base_cell.dim.x):
		return null
	if(_coordv.y < base_cell.topleft.y|| _coordv.y >= base_cell.topleft.y + base_cell.dim.y):
		return null
	
	return get_child_containing_coord(_coordv, base_cell)

func get_child_containing_coord(coordv: Vector2, cell: QuadCell):
	if(cell.children == null || cell.children.size() == 0):
		if(cell.traversable == false):
			return null
		return cell
	
	var west : bool
	if(coordv.x < cell.topleft.x + cell.dim.x/2):
		west = true
	else:
		west = false
		
	var north : bool
	if(coordv.y < cell.topleft.y + cell.dim.y/2):
		north = true
	else:
		north = false
	
	var direction: int
	if(north):
		if(west):
			direction = Direction.NW
		else:
			direction = Direction.NE
	else:
		if(west):
			direction = Direction.SW
		else:
			direction = Direction.SE
	
	return get_child_containing_coord(coordv, cell.children[direction])

func build_from_tilemap(tilemap: TileMap, print_array = null):
	var start_time = OS.get_ticks_msec()
	
	traversable_map_tiles = tilemap.get_used_cells()
	var used_rect := tilemap.get_used_rect()
	
	# make a square with dimensions of a power of 2 that fits the map
	var max_dim: int = max(used_rect.size.x, used_rect.size.y)
	var is_pow_2 = (max_dim) & (max_dim - 1) == 0
	if(!is_pow_2):
		max_dim = pow(2, ceil(log(max_dim)/log(2)))
	
	base_cell = QuadCell.new("", used_rect.position, Vector2.ONE*max_dim)
	
	process_cell(base_cell)

	for id in leaf_cells.keys():
		var leaf: QuadCell = leaf_cells[id]
		if(leaf.traversable):
			for d in Direction:
				var neighbor = get_neighbor_of_greator_or_equal_size(leaf, Direction[d])
				var neighbors = find_neighbors_of_smaller_size(neighbor, Direction[d])
				for n in neighbors:
					if(n.traversable && !leaf.neighbors.has(n)):
						leaf.neighbors.append(n)
	
	var end_time = OS.get_ticks_msec()
	if(print_array is Array):
		print_array.append("NavQuadTree.build_from_tilemap()")
		print_array.append(str("\tstarting cells = ", tilemap.get_used_cells().size()))
		print_array.append(str("\ttotal clusters = ", clusters.size()))
		print_array.append(str("\ttotal elapsed time (ms) = ", end_time - start_time))
		print_array.append("")

func process_cell(cell: QuadCell):
	var traversable_found := false
	var non_traversable_found := false
	for x in range(cell.topleft.x, cell.topleft.x + cell.dim.x):
		for y in range(cell.topleft.y, cell.topleft.y + cell.dim.y):
			if(traversable_map_tiles.has(Vector2(x,y))):
				traversable_found = true
			else:
				non_traversable_found = true
			
			if(traversable_found && non_traversable_found):
				break
	#if it is a mixed cell
	if(traversable_found && non_traversable_found):
		#break cell into quads
		subdivide_cell(cell)
		
		for sub_cell in cell.children.values():
			process_cell(sub_cell)
	else:
		if(traversable_found):
			cell.traversable = true
			clusters[cell.id] = cell
		cell.leaf = true
		leaf_cells[cell.id] = cell

#create the four child cells of a given QuadCell
func subdivide_cell(cell: QuadCell):
	if(cell.dim.x > 1):
		var id_00 = cell.get_id_x() + "0" + cell.get_id_y() + "0"
		var subcell_00 = QuadCell.new(id_00, cell.topleft, cell.dim/2)
		subcell_00.parent = cell
		cell.children[Direction.NW] = subcell_00
		
		var id_01 = cell.get_id_x() + "0" + cell.get_id_y() + "1"
		var subcell_01 = QuadCell.new(id_01, cell.topleft + Vector2(0, cell.dim.y/2), cell.dim/2)
		subcell_01.parent = cell
		cell.children[Direction.SW] = subcell_01
		
		var id_10 = cell.get_id_x() + "1" + cell.get_id_y() + "0"
		var subcell_10 = QuadCell.new(id_10, cell.topleft + Vector2(cell.dim.x/2,0), cell.dim/2)
		subcell_10.parent = cell
		cell.children[Direction.NE] = subcell_10
		
		var id_11 = cell.get_id_x() + "1" + cell.get_id_y() + "1"
		var subcell_11 = QuadCell.new(id_11, cell.topleft + Vector2(cell.dim.x/2, cell.dim.y/2), cell.dim/2)
		subcell_11.parent = cell
		cell.children[Direction.SE] = subcell_11

func get_neighbor_of_greator_or_equal_size(cell: QuadCell, direction: int):
	if(cell.parent == null):
		return null
	
	#NORTH
	if (direction == Direction.N):
		if(cell.parent.children[Direction.SW] == cell):
			return cell.parent.children[Direction.NW]
		if(cell.parent.children[Direction.SE] == cell):
			return cell.parent.children[Direction.NE]
		
		var parent_neighbor: QuadCell = get_neighbor_of_greator_or_equal_size(cell.parent, direction)
		if(parent_neighbor == null || parent_neighbor.leaf):
			return parent_neighbor
		
		if(cell.parent.children[Direction.NW] == cell):
			return parent_neighbor.children[Direction.SW]
		if(cell.parent.children[Direction.NE] == cell):
			return parent_neighbor.children[Direction.SE]
	
	#SOUTH
	if (direction == Direction.S):
		if(cell.parent.children[Direction.NW] == cell):
			return cell.parent.children[Direction.SW]
		if(cell.parent.children[Direction.NE] == cell):
			return cell.parent.children[Direction.SE]
		
		var parent_neighbor: QuadCell = get_neighbor_of_greator_or_equal_size(cell.parent, direction)
		if(parent_neighbor == null || parent_neighbor.leaf):
			return parent_neighbor
		
		if(cell.parent.children[Direction.SW] == cell):
			return parent_neighbor.children[Direction.NW]
		if(cell.parent.children[Direction.SE] == cell):
			return parent_neighbor.children[Direction.NE]
	
	#EAST
	if (direction == Direction.E):
		if(cell.parent.children[Direction.NW] == cell):
			return cell.parent.children[Direction.NE]
		if(cell.parent.children[Direction.SW] == cell):
			return cell.parent.children[Direction.SE]
		
		var parent_neighbor: QuadCell = get_neighbor_of_greator_or_equal_size(cell.parent, direction)
		if(parent_neighbor == null || parent_neighbor.leaf):
			return parent_neighbor
		
		if(cell.parent.children[Direction.NE] == cell):
			return parent_neighbor.children[Direction.NW]
		if(cell.parent.children[Direction.SE] == cell):
			return parent_neighbor.children[Direction.SW]
	
	#WEST
	if (direction == Direction.W):
		if(cell.parent.children[Direction.NE] == cell):
			return cell.parent.children[Direction.NW]
		if(cell.parent.children[Direction.SE] == cell):
			return cell.parent.children[Direction.SW]
		
		var parent_neighbor: QuadCell = get_neighbor_of_greator_or_equal_size(cell.parent, direction)
		if(parent_neighbor == null || parent_neighbor.leaf):
			return parent_neighbor
		
		if(cell.parent.children[Direction.NW] == cell):
			return parent_neighbor.children[Direction.NE]
		if(cell.parent.children[Direction.SW] == cell):
			return parent_neighbor.children[Direction.SE]
	
	return null

# gets the child leaf nodes of the neighbor cell in the given direction
# working backwards from the given direction (N->S, E->W, etc) to find the edge leaf cells
func find_neighbors_of_smaller_size(neighbor: QuadCell, direction: int):
	if(neighbor == null):
		return []
	
	var candidates := [neighbor]
	var neighbors := []
	
	#NORTH
	if(direction == Direction.N):
		while(candidates.size() > 0):
			if(candidates[0].leaf):
				neighbors.append(candidates[0])
			else:
				candidates.append(candidates[0].children[Direction.SW])
				candidates.append(candidates[0].children[Direction.SE])
			candidates.remove(0)
		return neighbors
	
	#SOUTH
	if(direction == Direction.S):
		while(candidates.size() > 0):
			if(candidates[0].leaf):
				neighbors.append(candidates[0])
			else:
				candidates.append(candidates[0].children[Direction.NW])
				candidates.append(candidates[0].children[Direction.NE])
			candidates.remove(0)
		return neighbors
	
	#EAST
	if(direction == Direction.E):
		while(candidates.size() > 0):
			if(candidates[0].leaf):
				neighbors.append(candidates[0])
			else:
				candidates.append(candidates[0].children[Direction.NW])
				candidates.append(candidates[0].children[Direction.SW])
			candidates.remove(0)
		return neighbors
	
	#WEST
	if(direction == Direction.W):
		while(candidates.size() > 0):
			if(candidates[0].leaf):
				neighbors.append(candidates[0])
			else:
				candidates.append(candidates[0].children[Direction.NE])
				candidates.append(candidates[0].children[Direction.SE])
			candidates.remove(0)
		return neighbors
	
	return neighbors
