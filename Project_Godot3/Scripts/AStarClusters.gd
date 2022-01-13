class_name AStarClusters
extends AStar2D

func add_clusters(clusters: Array):
	self.clear()
	
	if(clusters.size() > self.get_point_capacity()):
		reserve_space(clusters.size())
	
	for cluster in clusters:
		add_point(coord_to_id(cluster.topleft), cluster.topleft + cluster.dim/2)
	
	for cluster in clusters:
		for neighbor in cluster.neighbors:
			var neighbor_id = coord_to_id(neighbor.topleft)
			if(has_point(neighbor_id)):
				connect_points(coord_to_id(cluster.topleft), neighbor_id)

func run(start: NavCluster, goal: NavCluster):
	var path := [start]
	var ids := get_id_path(coord_to_id(start.topleft), coord_to_id(goal.topleft))
	
	for i in range(1, ids.size()):
		var topleft = id_to_coord(ids[i])
		for neighbor in path[i-1].neighbors:
			if(neighbor.topleft == topleft):
				path.append(neighbor)
				break
				
	return path

static func coord_to_id(coordv: Vector2):
	# Cantor Pairing function
	return (coordv.x + coordv.y) * (coordv.x + coordv.y + 1)/2 + coordv.y

static func id_to_coord(id: int):
	# Inverted Cantor Pairing function
	var w = floor((sqrt(8*id+1) - 1)/2)
	var t = (pow(w,2) + w)/2
	var y = id - t
	var x = w - y
	return Vector2(x,y)
