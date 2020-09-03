extends TileMap

onready var config = $"/root/Config"
onready var astar = AStar.new()

onready var Item = preload("res://scenes/Item.tscn")

var tile_content = [[]]

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

var tile_objects = {
	TileType.CHEST_ACTIVE: 1,
	TileType.BARREL: 7, 
	TileType.TRASH: 10
}


### Generation
class RoomSorter:
	static func left_coord(a, b):
		if a.position.x < b.position.x:
			return true
		return false
		

func reset_map():
	for x in range(config.MAP_WIDTH):
		for y in range(config.MAP_HEIGHT):
			set_cell(x, y, 0)

func create_map(_level):
	var rooms = []
	randomize()
	
	var open_map = false
	
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
				if new_room.intersects(room, not open_map):
					new_room = null
					room_count += 0.25 # give a partial count for a fail
					break
			
		if new_room:
			room_count += 1
			rooms.append(new_room)
	
	# End early and fail if not enough rooms created.
	if len(rooms) < config.MIN_ROOMS:
		return [false, rooms, rooms[0].position]
		
	# Actually create rooms
	rooms.sort_custom(RoomSorter, "left_coord")
	for i in range(len(rooms)-1):
		add_room_to_map(rooms[i])
		add_room_to_map(rooms[i+1])
		
		# Add corridors
		var room = rooms[i]
		var next_room = rooms[i+1]
		var start_x = room.position.x + (randi() % int(abs(room.position.x - room.end.x)) + 1) - 1
		var start_y = room.position.y + (randi() % int(abs(room.position.y - room.end.y)) + 1) - 1
		var end_x = next_room.position.x + (randi() % int(abs(next_room.position.x - next_room.end.x)) + 1) - 1
		var end_y = next_room.position.y + (randi() % int(abs(next_room.position.y - next_room.end.y)) + 1) - 1
		create_corridor_step(start_x, start_y, end_x, end_y)
			
	# Add entrance and exit stairs.
	set_cell(rooms[0].position.x, rooms[0].position.y, 3)
	set_cell(rooms[-1].end.x, rooms[-1].end.y-1, 2)
	
	# Add objects
	add_objects(rooms)
	add_doors()
	add_items(rooms)
	
	return [true, rooms, rooms[0].position]

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

func create_corridor_step(x1, y1, x2, y2):
	var x = x1
	var y = y1
	
	while x != x2 || y != y2:
		if x < x2:
			x += 1
		elif x > x2:
			x -= 1
		elif  y < y2:
			y += 1
		elif y > y2:
			y -= 1

		set_cell(x, y, 1)

func add_objects(rooms):
	# Handles adding objects to the room such as barrels, chests etc.
	randomize()
	
	for room in rooms:
		for _i in range(randi() % config.MAX_OBJECT_PER_ROOM):
			var x = randi() % int(room.size.x-1) + (room.position.x+1)
			var y = randi() % int(room.size.y-1) + (room.position.y+1)
			if get_cell(x, y) == TileType.FLOOR:
				var num = randi() % (10) + 1
				for obj in tile_objects.keys():
					if num <= tile_objects[obj]:
						set_cell(x, y, obj)
						break
				

func add_doors():
	for x in range(16):
		for y in range(16):
			if get_cell(x, y) == TileType.FLOOR && check_door_possible(x, y):
				if randi() % 10 < config.DOOR_SPAWN_RATE:
					set_cell(x, y, 4)
				
func check_door_possible(x, y):
	if get_cell(x - 1, y) == TileType.WALL && get_cell(x + 1, y) == TileType.WALL:
		if get_cell(x, y - 1) != TileType.DOOR && get_cell(x, y + 1) != TileType.DOOR:
			return true
	elif get_cell(x, y - 1) == TileType.WALL && get_cell(x, y + 1) == TileType.WALL:
		if get_cell(x - 1, y) != TileType.DOOR && get_cell(x + 1, y) != TileType.DOOR:
			return true
		
	return false
	
func add_items(rooms):
	# Handles adding items to rooms such as coins, weapons etc
	randomize()
	var _items = ["Coin"]
	var item_num = 0
	var max_items = randi() % config.MAX_ITEMS_PER_LEVEL
	while item_num < max_items:
		var room = rooms[(randi() % len(rooms))]
		var x = randi() % int(room.size.x) + (room.position.x)
		var y = randi() % int(room.size.y) + (room.position.y)
		if get_cell(x, y) == TileType.FLOOR:
			create_item("Coin", x, y)
			item_num += 1
				
func create_item(name, x, y, add_to_map=true):
	# Builds an item then either places it in the level or in the players inventory.
	var item = Item.instance()
	var main = get_tree().current_scene
	item.item_name = name
	item.item_info = get_parent().item_data[name]
	
	if add_to_map:
		main.add_child(item)
		item.global_position = Vector2(x, y)*config.tile_size
	else:
		print(item)
		item.add_item_to_inventory(get_parent().player)
	
			
### Pathfinding
func is_walkable(pos_to_check):
	if !get_cellv(pos_to_check) in walkable_tile_types:
		return false
	for mob in get_parent().mobs:
		if is_instance_valid(mob):
			if mob.grid_pos == pos_to_check:
				return false
				
	return true
	
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
			if is_instance_valid(mob):
				if mob.grid_pos == point:
					astar.set_point_disabled(point_index, true)
					break
	
func calculate_point_index(point):
	return point.x + config.MAP_WIDTH * point.y

func is_outside_map_bounds(point):
	return point.x < 0 or point.y < 0 or point.x >= config.MAP_WIDTH or point.y >= config.MAP_HEIGHT
