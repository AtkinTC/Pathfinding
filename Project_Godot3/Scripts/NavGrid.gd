class_name NavGrid

var nav_tilemap: TileMap

var neighbors_cached := {}

func assemble_from_tilemap(tilemap: TileMap):
	nav_tilemap = tilemap

func get_height():
	var rect := nav_tilemap.get_used_rect()
	return rect.position.y + rect.size.y

func get_width():
	var rect := nav_tilemap.get_used_rect()
	return rect.position.y + rect.size.y

func is_cell_traversable(coordv : Vector2):
	var tile_index = nav_tilemap.get_cell(coordv.x, coordv.y)
	if(tile_index is int && tile_index >= 0):
		return true
	return false

func get_cell_traversable_neighbors(coordv : Vector2) -> Array:
	if(neighbors_cached.has(coordv)):
		return neighbors_cached[coordv]
	
	var neighbors := []
	if(is_cell_traversable(coordv + Vector2.RIGHT)):
		neighbors.append(coordv + Vector2.RIGHT)
	if(is_cell_traversable(coordv + Vector2.LEFT)):
		neighbors.append(coordv + Vector2.LEFT)
	if(is_cell_traversable(coordv + Vector2.UP)):
		neighbors.append(coordv + Vector2.UP)
	if(is_cell_traversable(coordv + Vector2.DOWN)):
		neighbors.append(coordv + Vector2.DOWN)
	
	neighbors_cached[coordv] = neighbors
	return neighbors
