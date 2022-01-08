class_name AStarClusters



static func A_Star(start: NavCluster, goal: NavCluster):
	var open_set := [start]
	
	var came_from := {}
	
	# g_score[n] is the current cheapest path from start to n
	var g_score := {start.id: 0}
	
	# f_score[n] = g_score[n] + h(n)
	# best guess at to the shortest path going through n
	var f_score := {start.id: start.distance_to_octile(goal)}
	
	while(open_set.size() > 0):
		# assume open_set is sorted by f_score
		var current: NavCluster = open_set[0]
		if(current == goal):
			return reconstruct_path(came_from, current)
		
		open_set.remove(0)
		for neighbor in current.neighbors:
			var tentative_g_score = g_score[current.id] + current.distance_to_octile(neighbor)
			if(tentative_g_score < g_score.get(neighbor.id, INF)):
				came_from[neighbor.id] = current
				g_score[neighbor.id] = tentative_g_score
				f_score[neighbor.id] = tentative_g_score + neighbor.distance_to_octile(goal)
				if(!open_set.has(neighbor)):
					if(open_set.size() == 0):
						open_set.append(neighbor)
					else:
						# insert neighbor into the open_set sorted by f_score ascending
						for i in range(open_set.size()+1):
							if(i >= open_set.size()):
								open_set.append(neighbor)
								break
							if(f_score[neighbor.id] < f_score[open_set[i].id]):
								open_set.insert(i, neighbor)
								break
	
	#never reached goal
	return null

static func reconstruct_path(came_from: Dictionary, current: NavCluster):
	var total_path := [current]
	while(came_from.has(current.id)):
		current = came_from[current.id]
		total_path.push_front(current)
	return total_path
