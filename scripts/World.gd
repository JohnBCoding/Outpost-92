extends Node

onready var config = $"/root/Config"
onready var audio = $"/root/AudioManager"
onready var tile_map = $TileMap
onready var visibility_map = $VisibilityMap
onready var ui = $UIBorder
onready var Player = preload("res://scenes/Player.tscn")
onready var Mob = preload("res://scenes/Mob.tscn")

var player = null
var mobs = []

enum TileType {
	WALL,
	FLOOR,
	STAIRS_ACTIVE,
	STAIRS_INACTIVE,
	DOOR,
	BARREL,
	TRASH,
}

func _ready():
	audio.volume_db = -15
	goto_new_level()
	
	ui.init_ui(player.stats)

func _process(_delta):
	if !player:
		return
	
	if player.global_position.y < ((get_viewport().size.y/config.tile_size)/4)+8:
		ui.set_global_position(Vector2(2, 116))
	elif player.global_position.y > (get_viewport().size.y/config.tile_size):
		ui.set_global_position(Vector2(2, 2))
		
	if player.can_act == false:
		if !player.tween.is_active():
			for mob in mobs:
				if mob:
					mob.can_act = true
				else:
					mobs.erase(mob)
			player.can_act = true
			tile_map.generate_astar(mobs)

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
		TileType.WALL:
			audio.stream = audio.bump_effect
			audio.play()
		TileType.STAIRS_INACTIVE:
			audio.stream = audio.bump_effect
			audio.play()
		TileType.DOOR:
			tile_map.set_cell(tile_pos[0], tile_pos[1], 1)
			audio.stream = audio.door_open_effect
			audio.play()
		TileType.BARREL:
			tile_map.set_cell(tile_pos[0], tile_pos[1], 1)
			audio.stream = audio.destroyable_effect
			audio.play()
		TileType.TRASH:
			tile_map.set_cell(tile_pos[0], tile_pos[1], 1)
			audio.stream = audio.destroyable_effect
			audio.play()

func goto_new_level():
	tile_map.reset_map()
	visibility_map.reset_map()
	
	var map_data = tile_map.create_map(1)
	var rooms = map_data[0]
	var starting_position = map_data[1]*config.tile_size
	
	create_player(starting_position)
	create_mobs(rooms)
	
	# Generate astar pathfinding.
	tile_map.generate_astar(mobs)
	
func create_player(starting_position):
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
	player.connect("damage_taken", ui, "_on_Player_damage_taken")
	
	# Add to tree and set its starting position
	var main = get_tree().current_scene
	main.add_child(player)
	player.global_position = starting_position
	player.can_act = true
	
func create_mobs(rooms):
	randomize()
	for room in rooms:
		var x = randi() % int(room.size.x-1) + (room.position.x+1)
		var y = randi() % int(room.size.y-1) + (room.position.y+1)
		var new_pos = Vector2(x, y)
		if tile_map.get_cellv(new_pos) == TileType.FLOOR && (new_pos*config.tile_size) != player.global_position:
			var mob = Mob.instance()
			var main = get_tree().current_scene
			main.add_child(mob)
			mob.global_position = new_pos*config.tile_size
			mobs.append(mob)
