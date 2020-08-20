extends TileMap

onready var config = $"/root/Config"

func reset_map():
	for x in range(config.MAP_WIDTH):
		for y in range(config.MAP_HEIGHT):
			set_cell(x, y, 0)
