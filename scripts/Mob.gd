extends "res://scripts/Entity.gd"

onready var vis_map = get_parent().get_node("VisibilityMap")
onready var player = get_parent().get_node("Player")

var mob_info = {
	"goblin": {
		"sprite": preload("res://resources/sprites/mobs/goblin.png"),
		"ai": funcref(self, "chase_ai"),
		"stats": {
			"hp": 1,
			"max_hp": 1,
			"attack": 2,
			"defense": 0,
			"power": 0,
			"turn_speed": 100,
			"sight_range": 3
		},
		"skills": {}
	},
	"mutated": {
		"sprite": preload("res://resources/sprites/mobs/mutated.png"),
		"ai": funcref(self, "mutated_ai"),
		"stats": {
			"hp": 20,
			"max_hp": 20,
			"attack": 0,
			"defense": 0,
			"power": 1,
			"turn_speed": 75,
			"sight_range": 4
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
	
	var distance = grid_pos.distance_to(player.grid_pos)
	var dir = (grid_pos - player.grid_pos)
	
	yield(ai.call_func(distance, dir), "completed")
	can_act = false
	
func chase_ai(distance, dir):
	if distance <= 1:
		player.take_damage(current_stats.attack)
		position += -dir * config.tile_size
		bump_tween(dir)
		audio.play_effect("basic_attack")
		
	elif distance <= current_stats["sight_range"] || last_known_target:
		path_find(player)
		
	yield(get_tree().create_timer(.0001), "timeout")
	
func mutated_ai(distance, dir):
	var explode = false
	if !active_skill:
		if distance <= 1:
			if equipped_skills["weapon"]["delayed_action_cooldown"] == null:
					equipped_skills["weapon"]["delayed_action_cooldown"] = 2
					combat_text("Heating Up")
					overheat_tween()
			else:
				equipped_skills["weapon"]["delayed_action_cooldown"] -= 1
				if equipped_skills["weapon"]["delayed_action_cooldown"] <= 0:
					explode = true
				else:
					overheat_tween()
			
		elif distance <= current_stats["sight_range"] || last_known_target:
			if !path_find(player):
				if equipped_skills["weapon"]["delayed_action_cooldown"] != null:
					equipped_skills["weapon"]["delayed_action_cooldown"] -= 1
					if equipped_skills["weapon"]["delayed_action_cooldown"] <= 0:
						explode = true
					else:
						overheat_tween()
	
		if explode:
			equipped_skills["weapon"]["delayed_action_cooldown"] = null
			var skills_created = []
			for dir in config.inputs["movement"]:
				skills_created.append(create_skill("overheat", "weapon", config.inputs["movement"][dir]))
				
	yield(get_tree().create_timer(.0001), "timeout")
