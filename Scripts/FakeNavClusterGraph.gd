extends NavClusterGraph
class_name FakeNavClusterGraph

var single_giant_cluster: NavCluster

func get_cluster_containing_coord(coordv: Vector2):
	return single_giant_cluster

func get_cluster(id: String):
	if(id == single_giant_cluster.id):
		return single_giant_cluster
	return null

func get_clusters_dict():
	return {"":single_giant_cluster}

func build_from_tilemap(tilemap: TileMap):
	var rect := tilemap.get_used_rect()
	single_giant_cluster = NavCluster.new("", rect.position, rect.size)
