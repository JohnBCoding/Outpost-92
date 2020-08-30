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
	AI,
	Inventory,
	Targeting
}

### Turn system
class TurnSorter:
	static func sort_ascending(a, b):
		if a[0] < b[0]:
			return true
		return false
var turns = []
var current_turn = null
var prev_state = States.Main
var state = States.Main

func reset_turns():
	turns = []
	current_turn = null
	
	# Init turns
	for mob in mobs:
		turns.append([(randi() % 4)+1, mob])
	turns.append([0, player])
	turns.sort_custom(TurnSorter, "sort_ascending")

func check_for_turn():
	# Check if new turn is needed to be pulled
	var check_for_turn = true
	if player.can_act:
		check_for_turn = false
	for mob in mobs:
		if is_instance_valid(mob):
			if mob.can_act:
				check_for_turn = false
	
	if check_for_turn:
		get_turn()
		
func get_turn():
	turns.sort_custom(TurnSorter, "sort_ascending")
	current_turn = turns.pop_front()
	print(turns)
	if current_turn:
		if is_instance_valid(current_turn[1]):
			if current_turn[1].name == "Player":
				change_state(States.Main, false)
			current_turn[1].can_act = true
			if !current_turn[1].name == "Player":
				change_state(States.AI, false)
				current_turn[1].run_ai()
			turns.append([current_turn[0]+current_turn[1].current_stats["turn_speed"], current_turn[1]])
		else:
			turns.erase(current_turn[1])
	else:
		player.can_act = true
	
	# Refresh astar with new mob locations.
	for mob in mobs:
		if !is_instance_valid(mob):
			mobs.erase(mob)

	tile_map.generate_astar(mobs)

### General
func _init():
	# Load data
	var file = File.new()
	if file.open("res://data/items.json", File.READ) != OK:
		return
	
	item_data = JSON.parse(file.get_as_text()).result

func _ready():
	audio.volume_db = -5
	audio.start_music()
	goto_new_level()

	ui_status.init_ui(player)

func _process(_delta):
	if !is_instance_valid(player):
		return
	
	# Readjust UI based on player position
	if player.global_position.y < config.tile_size*3:
		ui_status.set_global_position(Vector2(2, 116))
		ui_inventory.set_global_position(Vector2(2, 66))
	elif player.global_position.y > ((config.MAP_HEIGHT*config.tile_size) - config.tile_size*4):
		ui_status.set_global_position(Vector2(2, 2))
		ui_inventory.set_global_position(Vector2(2, 13))
	
	if is_instance_valid(current_turn[1]):
		yield(current_turn[1]._completed(), "completed")
		check_for_turn()
	else:
		check_for_turn()
	
func change_state(new_state, toggle = true):
	if state == new_state:
		if toggle:
			state = prev_state
	else:
		prev_state = state
		state = new_state


#### Signals
func _on_Player_bumped_something(entity, bumped_pos):
	var bumped = get_collider(bumped_pos)
	
	# Determine what was collided with then handle from there.
	if typeof(bumped) == TYPE_INT:
		handle_bumped_tile(bumped, bumped_pos)
	elif bumped.is_in_group("mobs"):
		print(bumped.grid_pos)
	
		audio.play_effect("basic_attack")
		bumped.take_damage(player.current_stats.attack)
	
func handle_bumped_tile(tile, tile_pos):
	match tile:
		tile_map.TileType.WALL:
			audio.play_effect("bump")
		tile_map.TileType.STAIRS_INACTIVE:
			audio.play_effect("bump")
		tile_map.TileType.STAIRS_ACTIVE:
			audio.play_effect("bump")
			yield($Player/TweenEffect, "tween_all_completed")
			goto_new_level()
		tile_map.TileType.DOOR:
			tile_map.set_cellv(tile_pos, 1)
			audio.play_effect("door_open")
		tile_map.TileType.BARREL:
			tile_map.set_cellv(tile_pos, 1)
			audio.play_effect("destroyable")
		tile_map.TileType.TRASH:
			tile_map.set_cellv(tile_pos, 1)
			audio.play_effect("destroyable")
		tile_map.TileType.CHEST_ACTIVE:
			tile_map.set_cellv(tile_pos, tile_map.TileType.CHEST_ACTIVE+1)
			audio.play_effect("chest_open")
			var test_items = ["Coin", "Steel Axe", "Riot Shield", "Tattered Clothing"]
			tile_map.create_item(test_items[randi() % len(test_items)], 0, 0, false)

### Game start && Level
func goto_new_level():
	tile_map.reset_map()
	visibility_map.reset_map()
	
	var map_data = null
	while true:
		map_data = tile_map.create_map(1)
		if map_data[0]:
			break
			
	var rooms = map_data[1]
	var starting_position = map_data[2]
	
	create_player(starting_position)
	create_mobs(rooms)
	reset_turns()
	
	# Generate astar pathfinding.
	tile_map.generate_astar(mobs)
	
	# Start
	get_turn()
	
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
		player.base_stats.turn_speed = 100
		
		# Add signal connections for the player
		player.connect("bumped_something", self, "_on_Player_bumped_something")
		player.connect("damage_taken", ui_status, "_on_Player_damage_taken")
		player.connect("swapped_skill", ui_status, "_on_Player_swapped_skill")
		player.connect("item_selected", ui_status, "_on_Player_item_selected")
		player.connect("toggle_inventory", ui_inventory, "_on_Player_toggle_inventory")
		ui_inventory.connect("item_used", player, "_on_Item_used_from_inventory")
		ui_inventory.connect("item_selected", player, "_on_Item_selected_from_inventory")
		
		# Add to tree
		var main = get_tree().current_scene
		main.add_child(player)
		
	player.grid_pos = starting_position
	player.global_position = player.grid_pos*config.tile_size
	var test_items = ["Steel Axe", "Riot Shield", "Tattered Clothing"]
	tile_map.create_item(test_items[randi() % len(test_items)], 0, 0, false)
	player.update_visuals()

func reset_mobs():
	for mob in mobs:
		if is_instance_valid(mob):
			mob.queue_free()

func create_mobs(rooms):
	reset_mobs()
	mobs = []
	randomize()
	for room in rooms:
		var x = randi() % int(room.size.x-1) + (room.position.x+1)
		var y = randi() % int(room.size.y-1) + (room.position.y+1)
		var new_pos = Vector2(x, y)
		if tile_map.get_cellv(new_pos) == tile_map.TileType.FLOOR && (new_pos) != player.grid_pos:
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
			mob.grid_pos = new_pos
			mob.global_position = mob.grid_pos*config.tile_size
			mobs.append(mob)

func get_collider(grid_pos):
	for mob in mobs:
		if is_instance_valid(mob):
			if mob.grid_pos == grid_pos:
				return mob
				
	return tile_map.get_cellv(grid_pos)
