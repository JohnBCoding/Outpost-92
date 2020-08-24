extends TileMap

onready var config = $"/root/Config"
onready var astar = AStar.new()

onready var Item = preload("res://scenes/Item.tscn")

enum TileType {
	WALL,
	FLOOR,
	STAIRS_ACTIVE,
	STAIRS_INACTIVE,
	DOOR,
	BARREL,
	TRASH,
	CHEST_ACTIVE,
	CHEST_INACTIVE,
}

onready var walkable_tile_types = [
	TileType.FLOOR,
	TileType.STAIRS_INACTIVE,
	TileType.CHEST_INACTIVE,
]

### Generation
func reset_map():
	for x in range(config.MAP_WIDTH):
		for y in range(config.MAP_HEIGHT):
			set_cell(x, y, 0)

func create_map(_level):
	var rooms = []
	randomize()
	
	var room_count = 0
	while room_count < config.MAX_ROOM_TRY:	
		var x = randi() % (config.MAP_WIDTH-1) + 1
		var y = randi() % (config.MAP_HEIGHT-1) + 1
		var width = randi() % (config.MAX_ROOM_SIZE-1) + 2
		var height = randi() % (config.MAX_ROOM_SIZE-1) + 2
		var new_room = null
		
		if x + width < config.MAP_WIDTH && y+height < config.MAP_HEIGHT:
			new_room = Rect2(x, y, width, height)
			for room in rooms:
				if new_room.intersects(room, true):
					new_room = null
					room_count += 0.25
					break
			
		if new_room:
			room_count += 1

			if len(rooms) > 0:
				var new_pos = get_room_center(new_room)
				var prev_pos = get_room_center(rooms[len(rooms)-1])
				if randi() % 4 + 1 < 2:
					add_h_tunnel_to_map(prev_pos.x, new_pos.x, prev_pos.y)
					add_v_tunnel_to_map(prev_pos.y, new_pos.y, new_pos.x)
				else:
					add_v_tunnel_to_map(prev_pos.y, new_pos.y, prev_pos.x)
					add_h_tunnel_to_map(prev_pos.x, new_pos.x, new_pos.y)
			
			rooms.append(new_room)
			
	# Actually create rooms
	for room in rooms:
		add_room_to_map(room)
	
	# Add entrance and exit stairs.
	set_cell(rooms[0].position.x, rooms[0].position.y, 3)
	set_cell(rooms[-1].position.x, rooms[-1].position.y, 2)
	
	# Add objects
	add_objects(rooms)
	add_items(rooms)
	
	return [rooms, rooms[0].position]

func get_room_center(room):	
	return Vector2(room.position.x+int(room.size.x/2), room.position.y+int(room.size.y/2))
	
func add_room_to_map(room):
	# Carves out room setting all tiles inside it to floors
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			set_cell(x, y, 1)
			
func add_h_tunnel_to_map(x1, x2, y):
	for x in range(min(x1, x2), max(x1, x2)+1):
		set_cell(x, y, 1)

func add_v_tunnel_to_map(y1, y2, x):
	for y in range(min(y1, y2), max(y1, y2)+1):
		set_cell(x, y, 1)

func add_objects(rooms):
	# Handles adding objects to the room such as barrels, chests etc.
	randomize()
	var objects = [TileType.BARREL, TileType.TRASH, TileType.CHEST_ACTIVE]
	for room in rooms:
		for i in range(randi() % config.MAX_OBJECT_PER_ROOM):
			var x = randi() % int(room.size.x-1) + (room.position.x+1)
			var y = randi() % int(room.size.y-1) + (room.position.y+1)
			if get_cell(x, y) == TileType.FLOOR:
				set_cell(x, y, objects[(randi() % len(objects))])
				
func add_items(rooms):
	# Handles adding items to rooms such as coins, weapons etc
	randomize()
	var items = ["Coin"]
	var item_num = 0
	var max_items = randi() % config.MAX_ITEMS_PER_LEVEL
	while item_num < max_items:
		var room = rooms[(randi() % len(rooms))]
		var x = randi() % int(room.size.x) + (room.position.x)
		var y = randi() % int(room.size.y) + (room.position.y)
		if get_cell(x, y) == TileType.FLOOR:
			create_item("Coin", x, y)
			item_num += 1
				
func create_item(name, x, y):
	# Builds an item then palces it in the level.
	var item = Item.instance()
	var main = get_tree().current_scene
	item.item_name = name
	item.stackable = true
	main.add_child(item)
	item.global_position = Vector2(x, y)*config.tile_size
			
### Pathfinding
func generate_astar(mobs):
	astar = AStar.new()
	var points = add_walkable_cells()
	connect_cells(points, mobs)

func add_walkable_cells():
	var points = []
	for x in range(config.MAP_WIDTH):
		for y in range(config.MAP_HEIGHT):
			var point = Vector2(x, y)
			var tile_type = get_cell(x, y)
			if !tile_type in walkable_tile_types:
				continue

			points.append(point)
			var index = calculate_point_index(point)
			astar.add_point(index, Vector3(point.x, point.y, 0.0))
	
	return points
			
func connect_cells(points, mobs):
	for point in points:
		var point_index = calculate_point_index(point)
		var points_relative = PoolVector2Array([
			Vector2(point.x + 1, point.y),
			Vector2(point.x - 1, point.y),
			Vector2(point.x, point.y + 1),
			Vector2(point.x, point.y - 1)])
		for point_relative in points_relative:
			var point_relative_index = calculate_point_index(point_relative)

			if is_outside_map_bounds(point_relative):
				continue
			if not astar.has_point(point_relative_index):
				continue

			astar.connect_points(point_index, point_relative_index, false)
		
		# Check if mob is blocking a point, if so, disable it.
		for mob in mobs:
			if mob.position == (point * config.tile_size):
				astar.set_point_disabled(point_index, true)
				break
	
func calculate_point_index(point):
	return point.x + config.MAP_WIDTH * point.y

func is_outside_map_bounds(point):
	return point.x < 0 or point.y < 0 or point.x >= config.MAP_WIDTH or point.y >= config.MAP_HEIGHT
