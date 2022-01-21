extends Node
class_name NavTestUnit

var tile_map: TileMap

var nav_graph: NavClusterGraph
var astar_cluster: AStarClusters
var astar_tilemap: AStarTileMap

var path_clusters := []
var path_tiles := []

func set_tile_map(_tile_map: TileMap):
	tile_map = _tile_map

func set_nav_graph(_nav_graph: NavClusterGraph):
	nav_graph = _nav_graph

func setup_astar(print_array = null):
	if !(tile_map is TileMap):
		return null
	astar_tilemap = AStarTileMap.new()
	astar_tilemap.build_points_from_tile_map(tile_map, print_array)

func build_graph(print_array = null):
	if !(nav_graph is NavClusterGraph && tile_map is TileMap):
		return null
		
	nav_graph.reset()
	nav_graph.build_from_tilemap(tile_map, print_array)
	
	astar_cluster = AStarClusters.new()
	astar_cluster.add_clusters(nav_graph.get_clusters_dict().values())

func clear_navigation():
	path_clusters = []
	path_tiles = []

func run_navigation(_start_coord: Vector2, _end_coord: Vector2, print_array = null):
	clear_navigation()
	if(_start_coord != _end_coord):
		var start_cluster = nav_graph.get_cluster_containing_coord(_start_coord)
		var end_cluster = nav_graph.get_cluster_containing_coord(_end_coord)
		
		if(start_cluster != null && end_cluster != null):
			path_clusters = astar_cluster.run(start_cluster, end_cluster)
		
		for i in range(path_clusters.size()):
			var cluster: NavCluster = path_clusters[i]
			var path := []
			
			var point_a: Vector2
			if(i == 0):
				point_a = _start_coord
			else:
				point_a = path_tiles[-1]

			var point_b: Vector2
			if(i >= path_clusters.size()-2):
				point_b = _end_coord
			else:
				var cluster_n: NavCluster = path_clusters[i+1]
				point_b = path_clusters[i+1].topleft + Vector2(floor(cluster_n.dim.x/2),floor(cluster_n.dim.y/2))
			
			if(cluster.empty):
				path = InnerClusterNavigation.run(point_a, point_b, Rect2(cluster.topleft, cluster.dim))
			else:
				var minv = cluster.topleft
				var maxv = minv + cluster.dim - Vector2.ONE
				
				point_a.x = max(minv.x, point_a.x)
				point_a.x = min(maxv.x, point_a.x)
				point_a.y = max(minv.y, point_a.y)
				point_a.y = min(maxv.y, point_a.y)
				
				point_b.x = max(minv.x, point_b.x)
				point_b.x = min(maxv.x, point_b.x)
				point_b.y = max(minv.y, point_b.y)
				point_b.y = min(maxv.y, point_b.y)
				
				path = astar_tilemap.run(point_a, point_b)
			path_tiles.append_array(path)
		
		if(print_array is Array):
			print_array.append(str("# of clusters in path = ", path_clusters.size()))
			print_array.append(str("# of tiles in path = ", path_tiles.size()))
		return true
	else:
		return false

func get_path_clusters() -> Array:
	return path_clusters

func get_path_tiles() -> Array:
	return path_tiles

func draw(node: Node, tile_dim: Vector2) -> void:
	var highlight := Color.green
	highlight.a = 0.25
	
	var highlight2 := Color.yellow
	highlight2.a = 0.5
	
	var highlight3 := Color.red
	highlight3.a = 0.25
	
	# highlight the individual map tiles that are touched by the route
	for cell in path_tiles:
		node.draw_rect(Rect2(cell * tile_dim, tile_dim), highlight2, true)
	
	for key in nav_graph.get_clusters_dict().keys():
		# draw all clusters
		var cluster: NavCluster = nav_graph.get_cluster(key)
		var rect = Rect2(cluster.topleft*tile_dim, Vector2.ONE*cluster.dim*tile_dim)
		node.draw_rect(rect, Color.green, false, 1)
		
		# draw cluster neighbor connections
		var cluster_center = (cluster.topleft + Vector2.ONE*cluster.dim/2) * tile_dim 
		for neighbor in cluster.neighbors:
			var neighbor_center = (neighbor.topleft + Vector2.ONE*neighbor.dim/2) * tile_dim 
			node.draw_line(cluster_center, neighbor_center ,Color.blue ,1.2)
	
	if(path_clusters.size() >= 2):
		# highlight path clusters
		for i in range(path_clusters.size()):
			node.draw_rect(Rect2(path_clusters[i].topleft*tile_dim, Vector2.ONE*path_clusters[i].dim*tile_dim), highlight, true)
	
	if(path_clusters.size() >= 2):
		# draw path cell-center to cell-center
		for i in range(path_clusters.size()-1):
			var center_a = (path_clusters[i].topleft + path_clusters[i].dim/2) * tile_dim
			var center_b = (path_clusters[i+1].topleft + path_clusters[i+1].dim/2) * tile_dim
			node.draw_line(center_a, center_b, Color.darkblue, 4)
		
		# draw path cell_edge to cell-edge (closer representation of eventual final path)
		var last_point: Vector2 = (path_clusters[0].topleft + path_clusters[0].dim/2) * tile_dim
		for i in range(path_clusters.size()):
			if(i == path_clusters.size()-1):
				var center_a = (path_clusters[i].topleft + path_clusters[i].dim/2) * tile_dim
				node.draw_line(last_point, center_a, Color.darkmagenta, 3)
			else:
				var center_a = (path_clusters[i].topleft + path_clusters[i].dim/2) * tile_dim
				var center_b = (path_clusters[i+1].topleft + path_clusters[i+1].dim/2) * tile_dim
				var rect = Rect2(path_clusters[i].topleft*tile_dim, path_clusters[i].dim*tile_dim)
				var intersect = Utils.inner_line_to_rect_intersection(center_a, center_b, rect)
				node.draw_line(last_point, intersect, Color.darkmagenta, 3)
				last_point = intersect
	
	# draw path map-tile to map-tile
	for i in range(path_tiles.size()-1):
		var center_a: Vector2 = path_tiles[i]*tile_dim + tile_dim/2
		var center_b: Vector2 = path_tiles[i+1]*tile_dim + tile_dim/2
		node.draw_line(center_a, center_b, Color.darkgreen, 3)
