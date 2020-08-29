extends "res://scripts/Entity.gd"

onready var tile_map = get_parent().get_node("TileMap")
onready var vis_map = get_parent().get_node("VisibilityMap")
onready var player = get_parent().get_node("Player")

var mob_info = {
	"goblin": {
		"sprite": preload("res://resources/sprites/mobs/goblin.png"),
		"ai": funcref(self, "chase_ai"),
		"stats": {
			"hp": 2,
			"max_hp": 2,
			"attack": 2,
			"defense": 0,
			"power": 0
		},
		"skills": {}
	},
	"mutated": {
		"sprite": preload("res://resources/sprites/mobs/mutated.png"),
		"ai": funcref(self, "mutated_ai"),
		"stats": {
			"hp": 3,
			"max_hp": 3,
			"attack": 0,
			"defense": 0,
			"power": 1
		},
		"skills": {
			"weapon": "overheat",
		}
	}
}
var ai = null

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
		
### AI functions
func path_find(target):
	var start_index = tile_map.calculate_point_index(position / config.tile_size)
	var end_index = tile_map.calculate_point_index(target.position / config.tile_size)
		
	# Use bres line towards target
	var target_map_pos = tile_map.world_to_map(target.position)
	var map_pos = tile_map.world_to_map(position)
	var line = vis_map.bres_line(map_pos, target_map_pos)
	var visible = true
	for point in line:
		if tile_map.get_cellv(point) in vis_map.blockers:
			visible = false
			break
			
	if visible:
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
				
func run_ai():
	if !can_act:
		return
		
	var distance = (position.distance_to(player.position))/config.tile_size
	var dir = (position - player.position) / config.tile_size

	ai.call_func(distance, dir)
	can_act = false
	get_parent().get_turn()

func chase_ai(distance, dir):
	if distance <= 1:
		player.take_damage(current_stats.attack)
		position += -dir * config.tile_size
		bump_tween(dir)
		audio.play_effect("basic_attack")
		
	elif distance <= sight_range:
		path_find(player)
		
				
func mutated_ai(distance, dir):
	if distance <= 1:
		if equipped_skills["weapon"]["delayed_action_cooldown"] == 0:
			var skills_created = []
			for dir in config.inputs["movement"]:
				skills_created.append(create_skill("overheat", "weapon", config.inputs["movement"][dir]))
			for skill in skills_created:
				yield(skill._completed(), "completed")
			queue_free()
		else:
			if equipped_skills["weapon"]["delayed_action_cooldown"] == null:
				equipped_skills["weapon"]["delayed_action_cooldown"] = 1
				combat_text("Heating Up")
				overheat_tween()
				yield($Tween, "tween_all_completed")
			else:
				overheat_tween()
				
				equipped_skills["weapon"]["delayed_action_cooldown"] -= 1
				yield($Tween, "tween_all_completed")
		
	elif distance <= 3:
		if equipped_skills["weapon"]["delayed_action_cooldown"] == 0:
			var skills_created = []
			for dir in config.inputs["movement"]:
				skills_created.append(create_skill("overheat", "weapon", config.inputs["movement"][dir]))
			for skill in skills_created:
				yield(skill._completed(), "completed")
		elif equipped_skills["weapon"]["delayed_action_cooldown"] != null:
			overheat_tween()
			equipped_skills["weapon"]["delayed_action_cooldown"] -= 1
			
		path_find(player)

		
		

