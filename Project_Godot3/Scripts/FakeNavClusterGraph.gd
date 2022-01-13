extends NavClusterGraph
class_name FakeNavClusterGraph

var single_giant_cluster: NavCluster

func get_cluster_containing_coord(_coordv: Vector2):
	return single_giant_cluster

func get_cluster(_id: String):
	if(_id == single_giant_cluster.id):
		return single_giant_cluster
	return null

func get_clusters_dict():
	return {"":single_giant_cluster}

func build_from_tilemap(tilemap: TileMap, print_array = null):
	var rect := tilemap.get_used_rect()
	single_giant_cluster = NavCluster.new("", rect.position, rect.size)
