extends TileMap

onready var config = $"/root/Config"

func reset():
	for x in range(config.MAP_WIDTH):
		for y in range(config.MAP_HEIGHT):
			set_cell(x, y, -1)
	
func setup_bitmask(tile_map):
	reset()
	for x in range(config.MAP_WIDTH):
		for y in range(config.MAP_HEIGHT):
			if tile_map.get_cell(x, y) == 0:
				set_cell(x, y, get_bit(tile_map, x, y))
			
func get_bit(tile_map, x, y):
	# Determines the correct mask to display at each tile location depending on the adjacent tiles.
	# Yes it is a wall of if's, I don't care, it works..for now
	var mask = 0
	
	if tile_map.get_cell(x, y - 1) == tile_map.TileType.WALL || y - 1 <= 0:
		mask += 1
	if tile_map.get_cell(x, y + 1) == tile_map.TileType.WALL || y + 1 >= config.MAP_HEIGHT:
		mask += 2
	if tile_map.get_cell(x - 1, y) == tile_map.TileType.WALL || x - 1 <= 0:
		mask += 4
	if tile_map.get_cell(x + 1, y) == tile_map.TileType.WALL || x + 1 >= config.MAP_WIDTH:
		mask += 8
		
	match mask:
		0: 
			set_wall_part(tile_map, x, y+1)
			return 19
		1: 
			set_wall_part(tile_map, x, y+1)
			return 14
		2: return 12
		3: return 8
		4: 
			set_wall_part(tile_map, x, y+1)
			return 11
		5: 
			set_wall_part(tile_map, x, y+1)
			if tile_map.get_cell(x-1, y-1) != tile_map.TileType.WALL && x-1 > 0 && y-1 > 0:
				return 35
			return 5
		6: 
			if tile_map.get_cell(x-1, y+1) != tile_map.TileType.WALL && x-1 > 0 && y+1 < config.MAP_HEIGHT:
				return 34
			return 4
		7: 
			if tile_map.get_cell(x-1, y+1) != tile_map.TileType.WALL && x-1 > 0 && y+1 < config.MAP_HEIGHT:
				if tile_map.get_cell(x-1, y-1) != tile_map.TileType.WALL && x-1 > 0 && y-1 > 0:
					return 26
				return 22
			if tile_map.get_cell(x-1, y-1) != tile_map.TileType.WALL && x-1 > 0 && y-1 > 0:
				return 23
			return 0
		8: 
			set_wall_part(tile_map, x, y+1)
			return 13
		9: 
			set_wall_part(tile_map, x, y+1)
			if tile_map.get_cell(x+1, y-1) != tile_map.TileType.WALL && x+1 < config.MAP_WIDTH && y-1 > 0:
				return 37
			return 7
		10: 
			set_wall_part(tile_map, x, y+1)
			if tile_map.get_cell(x+1, y+1) != tile_map.TileType.WALL && x+1 < config.MAP_WIDTH && y+1 < config.MAP_HEIGHT:
				return 36
			return 6
		11: 
			if tile_map.get_cell(x+1, y+1) != tile_map.TileType.WALL && x+1 < config.MAP_WIDTH && y+1 < config.MAP_HEIGHT:
				if tile_map.get_cell(x+1, y-1) != tile_map.TileType.WALL && x+1 < config.MAP_WIDTH && y-1 > 0:
					return 27
				return 24
			if tile_map.get_cell(x+1, y-1) != tile_map.TileType.WALL && x+1 < config.MAP_WIDTH && y-1 > 0:
				return 25
			return 1
		12: 
			set_wall_part(tile_map, x, y+1)
			return 10
		13: 
			set_wall_part(tile_map, x, y+1)
			if tile_map.get_cell(x+1, y-1) != tile_map.TileType.WALL && x+1 < config.MAP_WIDTH && y-1 > 0:
				return 32
			if tile_map.get_cell(x-1, y-1) != tile_map.TileType.WALL && x-1 > 0 && y-1 > 0:
				return 33
			return 3
		14: 
			set_wall_part(tile_map, x, y+1)
			if tile_map.get_cell(x+1, y+1) != tile_map.TileType.WALL && x+1 < config.MAP_WIDTH && y+1 < config.MAP_HEIGHT:
				return 30
			if tile_map.get_cell(x-1, y+1) != tile_map.TileType.WALL && x-1 > 0 && y+1 < config.MAP_HEIGHT:
				return 31
			return 2
		15: 
			if tile_map.get_cell(x-1, y+1) != tile_map.TileType.WALL && x-1 > 0 && y+1 < config.MAP_HEIGHT:
				if tile_map.get_cell(x+1, y+1) != tile_map.TileType.WALL && x+1 < config.MAP_WIDTH && y+1 < config.MAP_HEIGHT:
					return 20
				if tile_map.get_cell(x-1, y-1) != tile_map.TileType.WALL && x-1 > 0 && y-1 > 0:
					return 28
				return 15
			if tile_map.get_cell(x+1, y+1) != tile_map.TileType.WALL && x+1 < config.MAP_WIDTH && y+1 < config.MAP_HEIGHT:
				if tile_map.get_cell(x+1, y-1) != tile_map.TileType.WALL && x+1 < config.MAP_WIDTH && y-1 > 0:
					return 29
				return 16
			if tile_map.get_cell(x-1, y-1) != tile_map.TileType.WALL && x-1 > 0 && y-1 > 0:
				if tile_map.get_cell(x+1, y-1) != tile_map.TileType.WALL && x+1 < config.MAP_WIDTH && y-1 > 0:
					return 21
				return 17
			if tile_map.get_cell(x+1, y-1) != tile_map.TileType.WALL && x+1 < config.MAP_WIDTH && y-1 > 0:
				return 18
				
	return -1
	
func set_wall_part(tile_map, x, y):
	# Sets the partial wall mask
	var tile_map_cell = tile_map.get_cell(x, y)
	if  tile_map_cell == tile_map.TileType.FLOOR:
		set_cell(x, y, 9)
	
