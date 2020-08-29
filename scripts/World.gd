extends Node

onready var config = $"/root/Config"
onready var audio = $"/root/AudioManager"
onready var tile_map = $TileMap
onready var visibility_map = $VisibilityMap
onready var Player = preload("res://scenes/Player.tscn")
onready var Mob = preload("res://scenes/Mob.tscn")

# Data files
var item_data = null

# UI
onready var ui_status = $UI/Status
onready var ui_inventory = $UI/Inventory

var player = null
var mobs = []

enum States {
	Main,
	Inventory,
	Targeting
}

# Turn system
class TurnSorter:
	static func sort_ascending(a, b):
		if a[0] < b[0]:
			return true
		return false
var turns = []
var current_turn = null
var prev_state = States.Main
var state = States.Main

func get_turn():
	var turn = turns.pop_front()
	if turn:
		if current_turn:
			if is_instance_valid(current_turn[1]):
				current_turn[1].can_act = false
				turns.append([current_turn[0]+10, current_turn[1]])
				turns.sort_custom(TurnSorter, "sort_ascending")
		
		current_turn = turn
		if is_instance_valid(turn[1]):
			if turn[1].name=="Player":
				yield(get_tree().create_timer(.125), "timeout")
			turn[1].can_act = true
			if !turn[1].name == "Player":
				turn[1].run_ai()
		else:
			turns.erase(turn[1])
			get_turn()
			return
	else:
		player.can_act = true
	
	# Refresh astar with new mob locations.
	for mob in mobs:
		if !is_instance_valid(mob):
			mobs.erase(mob)
	tile_map.generate_astar(mobs)

func _init():
	# Load data
	var file = File.new()
	if file.open("res://data/items.json", File.READ) != OK:
		return
	
	item_data = JSON.parse(file.get_as_text()).result

func _ready():
	audio.volume_db = -5
	goto_new_level()

	ui_status.init_ui(player)

func _process(_delta):
	if !player:
		return
	
	# Readjust UI based on player position
	if player.global_position.y < config.tile_size*3:
		ui_status.set_global_position(Vector2(2, 116))
		ui_inventory.set_global_position(Vector2(2, 66))
	elif player.global_position.y > ((config.MAP_HEIGHT*config.tile_size) - config.tile_size*4):
		ui_status.set_global_position(Vector2(2, 2))
		ui_inventory.set_global_position(Vector2(2, 13))

func change_state(new_state):
	if state == new_state:
		state = prev_state
	else:
		prev_state = state
		state = new_state
	
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
		audio.play_effect("basic_attack")
		collider.take_damage(player.current_stats.attack)
	
	
func handle_bumped_tile(tile_pos):
	var tile = tile_map.get_cellv(tile_pos)
	
	match tile:
		tile_map.TileType.WALL:
			audio.play_effect("bump")
		tile_map.TileType.STAIRS_INACTIVE:
			audio.play_effect("bump")
		tile_map.TileType.STAIRS_ACTIVE:
			audio.play_effect("bump")
			yield($Player/Tween, "tween_all_completed")
			goto_new_level()
		tile_map.TileType.DOOR:
			tile_map.set_cell(tile_pos[0], tile_pos[1], 1)
			audio.play_effect("door_open")
		tile_map.TileType.BARREL:
			tile_map.set_cell(tile_pos[0], tile_pos[1], 1)
			audio.play_effect("destroyable")
		tile_map.TileType.TRASH:
			tile_map.set_cell(tile_pos[0], tile_pos[1], 1)
			audio.play_effect("destroyable")
		tile_map.TileType.CHEST_ACTIVE:
			tile_map.set_cell(tile_pos[0], tile_pos[1], tile_map.TileType.CHEST_ACTIVE+1)
			audio.play_effect("chest_open")
			var test_items = ["Coin", "Steel Axe", "Riot Shield", "Tattered Clothing"]
			tile_map.create_item(test_items[randi() % len(test_items)], 0, 0, false)

func goto_new_level():
	tile_map.reset_map()
	visibility_map.reset_map()
	
	var map_data = null
	while true:
		map_data = tile_map.create_map(1)
		if map_data[0]:
			break
			
	var rooms = map_data[1]
	var starting_position = map_data[2]*config.tile_size
	
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
		player.base_stats.hp = 25
		player.base_stats.max_hp = 25
		player.base_stats.attack = 1
		player.base_stats.defense = 0
		player.base_stats.power = 0
		
		# Add signal connections for the player
		player.connect("bumped_something", self, "_on_Player_bumped_something")
		player.connect("damage_taken", ui_status, "_on_Player_damage_taken")
		player.connect("swapped_skill", ui_status, "_on_Player_swapped_skill")
		player.connect("item_selected", ui_status, "_on_Player_item_selected")
		player.connect("toggle_inventory", ui_inventory, "_on_Player_toggle_inventory")
		ui_inventory.connect("item_used", player, "_on_Item_used_from_inventory")
		ui_inventory.connect("item_selected", player, "_on_Item_selected_from_inventory")
		
		# Add to tree and set its starting position
		var main = get_tree().current_scene
		main.add_child(player)
		
	player.global_position = starting_position
	player.can_act = true
	var test_items = ["Steel Axe", "Riot Shield", "Tattered Clothing"]
	tile_map.create_item(test_items[randi() % len(test_items)], 0, 0, false)
	player.update_visuals()

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
			var mob_types = mob.mob_info.keys()
			var mob_type = mob_types[randi() % len(mob_types)]
			mob.get_node("Sprite").texture = mob.mob_info[mob_type]["sprite"]
			mob.base_stats = mob.mob_info[mob_type]["stats"]
			mob.ai = mob.mob_info[mob_type]["ai"]
			for skill in mob.mob_info[mob_type]["skills"]:
				mob.equipped_skills[skill]["skill"] = mob.mob_info[mob_type]["skills"][skill]
			var main = get_tree().current_scene
			main.add_child(mob)
			mob.global_position = new_pos*config.tile_size
			mobs.append(mob)
