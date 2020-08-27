extends TileMap

onready var config = $"/root/Config"
onready var tile_map = get_parent().get_node("TileMap")

var fov_dirs = [
	Vector2.UP,
	Vector2.DOWN,
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2(-1, -1),
	Vector2(1, -1),
	Vector2(-1, 1),
	Vector2(1, -1),
]

var blockers = null

func _ready():
	blockers = [tile_map.TileType.WALL, tile_map.TileType.DOOR]
	
func reset_map():
	for x in range(config.MAP_WIDTH):
		for y in range(config.MAP_HEIGHT):
			set_cell(x, y, 0)

func bres_line(start, target):
	var dx = target.x - start.x
	var dy = target.y - start.y
	
	var steep = abs(dy) > abs(dx)
	
	if steep:
		var temp = start.x
		start.x = start.y
		start.y = temp
		temp = target.x
		target.x = target.y
		target.y = temp
	
	var swapped = false
	if start.x > target.x:
		var temp = start.x
		start.x = target.x
		target.x = temp
		temp = start.y
		start.y = target.y
		target.y = temp
		swapped = true
	
	dx = target.x - start.x
	dy = target.y - start.y
	
	var err = int(dx / 2.0)
	var ystep = 1 if start.y < target.y else -1
	
	var y = start.y
	var points = []
	for x in range(start.x, target.x + 1):
		var coord = Vector2(y, x) if steep else Vector2(x, y)
		points.append(coord)
		err -= abs(dy)
		if err < 0:
			y += ystep
			err += dx
	if swapped:
		points.invert()
		
	return points
