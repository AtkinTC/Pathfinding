class_name Graph

var ids = []
var nodes = []
var connections = {}

func insert_node(node_id: int, node):
	if(ids.has(node_id)):
		return false
	
	var insert_index = nodes.bsearch(node_id, false)
	ids.insert(insert_index, node_id)
	nodes.insert(insert_index, node)
	
func connect_nodes(node_id_a: int, node_id_b: int, distance: float = 1.0):
	if(!ids.has(node_id_a) || !ids.find(node_id_b)):
		return false
	
	var connections_a: Dictionary = connections.get(node_id_a, {})
	connections_a[node_id_b] = distance
	connections[node_id_a] = connections_a
	
	var connections_b: Dictionary = connections.get(node_id_b, {})
	connections_b[node_id_a] = distance
	connections[node_id_b] = connections_b

func has_node(node_id: int):
	return ids.has(node_id)

func get_node(node_id: int):
	var index = ids.find(node_id)
	if(index == -1):
		return null
	return nodes[index]
	
func get_node_ids() -> Array:
	return ids

func get_nodes() -> Array:
	return nodes

func get_connections(node_id: int) -> Dictionary:
	if(!ids.has(node_id)):
		return {}
	return connections.get(node_id, {})

func has_connection(node_id_a: int, node_id_b: int) -> bool:
	if(!ids.has(node_id_a) || !ids.has(node_id_b)):
		return false
	return (connections.get(node_id_a, {}).has(node_id_b) || connections.get(node_id_b, {}).has(node_id_a))
	
