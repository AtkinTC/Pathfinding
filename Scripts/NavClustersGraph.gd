class_name NavClustersGraph

var clusters_dict := {}

func get_cluster_containing_coord(coordv: Vector2):
	return null

func get_cluster(id: String):
	return clusters_dict.get(id)

func add_cluster(cluster: NavCluster):
	clusters_dict[cluster.id] = cluster

func set_clusters_dict(_clusters_dict: Dictionary):
	clusters_dict = _clusters_dict
