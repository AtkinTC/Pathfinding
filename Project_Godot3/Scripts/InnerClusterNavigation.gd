class_name InnerClusterNavigation

static func run(start: Vector2, goal: Vector2, bound_rect: Rect2):
	if(bound_rect.size == Vector2.ONE):
		return [bound_rect.position]
	
	var minv = bound_rect.position
	var maxv = bound_rect.position + bound_rect.size - Vector2.ONE
	
	start.x = max(minv.x, start.x)
	start.x = min(maxv.x, start.x)
	start.y = max(minv.y, start.y)
	start.y = min(maxv.y, start.y)
	
	goal.x = max(minv.x, goal.x)
	goal.x = min(maxv.x, goal.x)
	goal.y = max(minv.y, goal.y)
	goal.y = min(maxv.y, goal.y)
	
	if(start == goal):
		return [goal]
	
	var current := start
	var path := [start]
	while(current != goal):
		var d_x := goal.x - current.x
		var d_y := goal.y - current.y
		
		if(abs(d_x) >= abs(d_y)):
			current.x += sign(d_x)	
		else:
			current.y += sign(d_y)
		
		path.append(current)
	
	return path
	
static func distance_between_cardinal(coord_a: Vector2, coord_b: Vector2):
	return abs(coord_a.x-coord_b.x) + abs(coord_a.y-coord_b.y)
