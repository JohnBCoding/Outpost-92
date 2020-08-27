extends "res://scripts/Entity.gd"

onready var tile_map = get_parent().get_node("TileMap")
onready var vis_map = get_parent().get_node("VisibilityMap")
onready var player = get_parent().get_node("Player")

# AI
var last_known_target = null

func _ready():
	add_to_group("mobs")
	
func _process(_delta):
	var cell_pos = vis_map.world_to_map(position)
	if vis_map.get_cell(cell_pos.x, cell_pos.y) == 0:
		visible = false
	else:
		visible = true
		
func run_ai():
	if !can_act:
		return
		
	var distance = (position.distance_to(player.position))/config.tile_size
	var dir = (position - player.position) / config.tile_size

	chase_ai(distance, dir)
	can_act = false
	get_parent().get_turn()
	
func chase_ai(distance, dir):
	if distance <= 1:
		player.take_damage(mod_stats.attack)
		position += -dir * config.tile_size
		bump_tween(dir)
		audio.play_effect("basic_attack")
		
	elif distance <= sight_range:
		# Get path indexs
		var start_index = tile_map.calculate_point_index(position / config.tile_size)
		var end_index = tile_map.calculate_point_index(player.position / config.tile_size)
		
		# Use bres line towards player
		var player_map_pos = tile_map.world_to_map(player.position)
		var map_pos = tile_map.world_to_map(position)
		var line = vis_map.bres_line(map_pos, player_map_pos)
		var visible = true
		for point in line:
			if tile_map.get_cellv(point) in vis_map.blockers:
				visible = false
				break
				
		# Do pathfinding if player is seen
		if visible:
			if last_known_target == null:
				combat_text("!")
			last_known_target = player.position
			
			var path = tile_map.astar.get_point_path(start_index, end_index)
			if len(path) > 1:
				var new_dir = Vector2(path[1].x - path[0].x,  path[1].y - path[0].y)
				tile_map.astar.set_point_disabled(tile_map.calculate_point_index(path[1]), true)
				move_entity(new_dir)
		elif last_known_target:
			end_index = tile_map.calculate_point_index(last_known_target / config.tile_size)
			var path = tile_map.astar.get_point_path(start_index, end_index)
			if len(path) > 1:
				var new_dir = Vector2(path[1].x - path[0].x,  path[1].y - path[0].y)
				tile_map.astar.set_point_disabled(tile_map.calculate_point_index(path[1]), true)
				move_entity(new_dir)
			else:
				# Reached the last know target location so stop searching
				last_known_target = null
				combat_text("?")
				

