class_name NavCluster
	
var id: String
var neighbors: Array
var topleft: Vector2
var dim: Vector2
var empty := true

func _init(_id: String, _topleft: Vector2, _dim: Vector2, _neighbors: Array = []):
	id = _id
	topleft = _topleft
	dim = _dim
	neighbors = _neighbors

func distance_to(cluster: NavCluster):
	var center_a := self.topleft + self.dim/2
	var center_b := cluster.topleft + cluster.dim/2
	return center_a.distance_to(center_b)

func distance_to_cardinal(cluster: NavCluster):
	var center_a := self.topleft + self.dim/2
	var center_b := cluster.topleft + cluster.dim/2
	return abs(center_a.x-center_b.x) + abs(center_a.y-center_b.y)

func distance_to_octile(cluster: NavCluster):
	var center_a := self.topleft + self.dim/2
	var center_b := cluster.topleft + cluster.dim/2
	
	var delta_x = abs(center_a.x-center_b.x)
	var delta_y = abs(center_a.y-center_b.y)
	return 1.414 * min(delta_x, delta_y) + abs(delta_x-delta_y)
