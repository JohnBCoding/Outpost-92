extends Node

onready var config = $"/root/Config"
onready var audio = $"/root/AudioManager"
onready var tile_map = $TileMap
onready var visibility_map = $VisibilityMap
onready var Player = preload("res://scenes/Player.tscn")
onready var Mob = preload("res://scenes/Mob.tscn")

# UI
onready var ui_status = $UI/Status
onready var ui_inventory = $UI/Inventory

var player = null
var mobs = []

enum States {
	Main,
	Inventory
}

# Turn system
class TurnSorter:
	static func sort_ascending(a, b):
		if a[0] < b[0]:
			return true
		return false
var turns = []
var current_turn = null
var state = States.Main

func get_turn():
	var turn = turns.pop_front()
	if turn:
		if current_turn:
			if current_turn[1]:
				current_turn[1].can_act = false
				turns.append([current_turn[0]+10, current_turn[1]])
				turns.sort_custom(TurnSorter, "sort_ascending")
		
		current_turn = turn
		if turn[1]:
			if turn[1].name=="Player":
				yield(get_tree().create_timer(.125), "timeout")
			turn[1].can_act = true
			if !turn[1].name == "Player":
				turn[1].run_ai()
		else:
			turns.erase(turn[1])
			get_turn()
			return
		#print(turns)
	
	# Refresh astar with new mob locations.
	for mob in mobs:
		if !mob:
			mobs.erase(mob)
	tile_map.generate_astar(mobs)
	
	
func _ready():
	audio.volume_db = -5
	goto_new_level()

	ui_status.init_ui(player.stats)


func _process(_delta):
	if !player:
		return
	
	# Readjust UI based on player position
	if player.global_position.y < ((get_viewport().size.y/config.tile_size)/4)+8:
		ui_status.set_global_position(Vector2(2, 116))
		ui_inventory.set_global_position(Vector2(2, 66))
	elif player.global_position.y > (get_viewport().size.y/config.tile_size):
		ui_status.set_global_position(Vector2(2, 2))
		ui_inventory.set_global_position(Vector2(2, 13))

#### Signals
func _on_Player_bumped_something(entity_pos, ray):
	var collision_pos = ray.get_collision_normal()
	var collider = ray.get_collider()

	# Determine what was collided with then handle from there.
	if collider.name == "TileMap":
		var tile_pos = tile_map.world_to_map(entity_pos)
		tile_pos -= collision_pos
		handle_bumped_tile(tile_pos)
	elif collider.is_in_group("mobs"):
		audio.stream = audio.basic_attack_effect
		audio.play()
		collider.take_damage(player.stats.attack)
	
	
func handle_bumped_tile(tile_pos):
	var tile = tile_map.get_cellv(tile_pos)
	
	match tile:
		tile_map.TileType.WALL:
			audio.stream = audio.bump_effect
			audio.play()
		tile_map.TileType.STAIRS_INACTIVE:
			audio.stream = audio.bump_effect
			audio.play()
		tile_map.TileType.STAIRS_ACTIVE:
			audio.stream = audio.bump_effect
			audio.play()
			yield($Player/Tween, "tween_all_completed")
			goto_new_level()
		tile_map.TileType.DOOR:
			tile_map.set_cell(tile_pos[0], tile_pos[1], 1)
			audio.stream = audio.door_open_effect
			audio.play()
		tile_map.TileType.BARREL:
			tile_map.set_cell(tile_pos[0], tile_pos[1], 1)
			audio.stream = audio.destroyable_effect
			audio.play()
		tile_map.TileType.TRASH:
			tile_map.set_cell(tile_pos[0], tile_pos[1], 1)
			audio.stream = audio.destroyable_effect
			audio.play()
		tile_map.TileType.CHEST_ACTIVE:
			tile_map.set_cell(tile_pos[0], tile_pos[1], tile_map.TileType.CHEST_ACTIVE+1)
			audio.stream = audio.chest_open_effect
			audio.play()

func goto_new_level():
	tile_map.reset_map()
	visibility_map.reset_map()
	
	var map_data = tile_map.create_map(1)
	var rooms = map_data[0]
	var starting_position = map_data[1]*config.tile_size
	
	create_player(starting_position)
	create_mobs(rooms)
	reset_turns()
	
	# Generate astar pathfinding.
	tile_map.generate_astar(mobs)
	
func reset_turns():
	turns = []
	current_turn = null
	
	# Init turns
	for mob in mobs:
		turns.append([(randi() % 4)+1, mob])
	current_turn = [0, player]
	turns.sort_custom(TurnSorter, "sort_ascending")
	
func create_player(starting_position):
	if !player:
		# Create instance
		player = Player.instance()
		
		# Setup stats
		player.stats.hp = 25
		player.stats.max_hp = 25
		player.stats.attack = 1
		player.stats.defense = 0
		player.stats.power = 0
		
		# Add signal connections
		player.connect("bumped_something", self, "_on_Player_bumped_something")
		player.connect("damage_taken", ui_status, "_on_Player_damage_taken")
		player.connect("toggle_inventory", ui_inventory, "_on_Player_toggle_inventory")
		
		# Add to tree and set its starting position
		var main = get_tree().current_scene
		main.add_child(player)
		
	player.global_position = starting_position
	player.can_act = true

func reset_mobs():
	for mob in mobs:
		mob.queue_free()
		
func create_mobs(rooms):
	reset_mobs()
	mobs = []
	randomize()
	for room in rooms:
		var x = randi() % int(room.size.x-1) + (room.position.x+1)
		var y = randi() % int(room.size.y-1) + (room.position.y+1)
		var new_pos = Vector2(x, y)
		if tile_map.get_cellv(new_pos) == tile_map.TileType.FLOOR && (new_pos*config.tile_size) != player.global_position:
			var mob = Mob.instance()
			var main = get_tree().current_scene
			main.add_child(mob)
			mob.global_position = new_pos*config.tile_size
			mobs.append(mob)
			

