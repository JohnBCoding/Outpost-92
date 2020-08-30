extends "res://scripts/Entity.gd"

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
			"power": 0,
			"turn_speed": 100
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
			"power": 1,
			"turn_speed": 75
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
	if vis_map.get_cellv(grid_pos) == 0:
		visible = false
	else:
		visible = true
		
### AI functions
func path_find(target):
	var start_index = tile_map.calculate_point_index(grid_pos)
	var end_index = tile_map.calculate_point_index(target.grid_pos)
		
	# Use bres line towards target
	var line = vis_map.bres_line(grid_pos, target.grid_pos)
	var visible = true
	for point in line:
		if tile_map.get_cellv(point) in vis_map.blockers:
			visible = false
			break
			
	if visible:
		if !last_known_target:
			combat_text("!")
			last_known_target = end_index
			return true
			
		var path = tile_map.astar.get_point_path(start_index, end_index)
		if len(path) > 1:
			last_known_target = end_index
			var new_dir = Vector2(path[1].x - path[0].x,  path[1].y - path[0].y)
			tile_map.astar.set_point_disabled(tile_map.calculate_point_index(path[1]), true)
			move_entity(new_dir)
			
	elif last_known_target:
			end_index = last_known_target
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
	
	can_act = false
	var distance = grid_pos.distance_to(player.grid_pos)
	var dir = (grid_pos - player.grid_pos)
	
	ai.call_func(distance, dir)


func chase_ai(distance, dir):
	if distance <= 1:
		player.take_damage(current_stats.attack)
		position += -dir * config.tile_size
		bump_tween(dir)
		audio.play_effect("basic_attack")
		
	elif distance <= sight_range:
		path_find(player)
		
				
func mutated_ai(distance, dir):
	
	var explode = false
	if distance <= 1:
		if equipped_skills["weapon"]["delayed_action_cooldown"] == null:
				equipped_skills["weapon"]["delayed_action_cooldown"] = 2
				combat_text("Heating Up")
				print(grid_pos)
				overheat_tween()
		else:
			equipped_skills["weapon"]["delayed_action_cooldown"] -= 1
			if equipped_skills["weapon"]["delayed_action_cooldown"] <= 0:
				explode = true
			else:
				overheat_tween()
		
	elif distance <= 3:
		if path_find(player):
			return
			
		if equipped_skills["weapon"]["delayed_action_cooldown"] != null:
			equipped_skills["weapon"]["delayed_action_cooldown"] -= 1
			if equipped_skills["weapon"]["delayed_action_cooldown"] <= 0:
				explode = true
			else:
				overheat_tween()

	if explode:
		var skills_created = []
		for dir in config.inputs["movement"]:
			skills_created.append(create_skill("overheat", "weapon", config.inputs["movement"][dir]))
		for skill in skills_created:
			yield(skill._completed(), "completed")
		return

		
		

