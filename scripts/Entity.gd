extends Area2D

onready var config = $"/root/Config"
onready var audio = $"/root/AudioManager"
onready var tile_map = get_parent().get_node("TileMap")

var grid_pos = null

# Particle effects
const combatText = preload("res://scenes/CombatText.tscn")
const hitEffect = preload("res://scenes/HitEffect.tscn")

# Skills
const Skills = {
	"windslash": {
		"scene": preload("res://scenes/skills/WindSlash.tscn"),
		"icon": preload("res://resources/sprites/ui/icons/windslash_icon.png"),
		"stats": {
			"damage": 2,
			"distance": 1,
			"cooldown": 5,
		}
	},
	"overheat": {
		"scene": preload("res://scenes/skills/OverHeat.tscn"),
		"icon": preload("res://resources/sprites/ui/icons/windslash_icon.png"),
		"stats": {
			"damage": 5,
			"distance": 1,
			"cooldown": 10,
			"delayed_action": 1
		}
	}
}

var active_skill = null
var equipped_skills = {
	"weapon": {
		"skill": null,
		"current_cooldown": 0,
		"delayed_action_cooldown": null
	},
	"armor":  {
		"skill": null,
		"current_cooldown": 0,
		"delayed_action_cooldown": null
	},
	"utility":  {
		"skill": null,
		"current_cooldown": 0,
		"delayed_action_cooldown": null
	},
}

# Movement
onready var tween_move = $TweenMove
onready var tween_effect = $TweenEffect
var base_tween_speed = 8

# Signal setup
signal bumped_something(entity, bumped_pos)
signal damage_taken(hp_values)

# Combat
var can_act = false
var base_stats = {
	"hp": 0,
	"max_hp": 0,
	"attack": 0,
	"defense": 0,
	"power": 0,
	"turn_speed": 0,
	"sight_range": 5
}
var mod_stats = {
	"hp": 0,
	"max_hp": 0,
	"attack": 0,
	"defense": 0,
	"power": 0,
	"turn_speed": 0,
	"sight_range": 0
}
var current_stats = {
	"hp": 0,
	"max_hp": 0,
	"attack": 0,
	"defense": 0,
	"power": 0,
	"turn_speed": 0,
	"sight_range": 0
}

var status = []

var hit = false

# Inventory
var inventory = []
var equipped = {
	"Main Hand": null,
	"Off Hand": null,
	"Armor": null
}

func _ready():
	calculate_stats(true)

# Turn handlers
func end_turn():
	
	if tween_move.is_active():
		yield($TweenMove, "tween_all_completed")
	elif tween_effect.is_active():
		yield($TweenEffect, "tween_all_completed")
	if is_instance_valid(active_skill):
		yield(active_skill._completed(), "completed")
		active_skill = null
	can_act = false
	
	# Decrease cooldowns
	for skill in equipped_skills.keys():
		if equipped_skills[skill]["current_cooldown"] > 0:
			equipped_skills[skill]["current_cooldown"] -= 1
	
func _completed():
	if is_instance_valid(active_skill):
		yield(active_skill._completed(), "completed")
		active_skill = null

	if tween_move.is_active():
		yield($TweenMove, "tween_all_completed")
	elif tween_effect.is_active():
		yield($TweenEffect, "tween_all_completed")
	else:
		yield(get_tree().create_timer(.001), "timeout")
	
# Combat
func calculate_stats(game_start = false):
	for m_stat in mod_stats.keys():
		mod_stats[m_stat] = 0
		
	for slot in equipped.keys():
		if equipped[slot]:
			for e_stat in equipped[slot].item_info["stats"]:
				mod_stats[e_stat] += equipped[slot].item_info["stats"][e_stat]
	
	for c_stat in current_stats.keys():
		if c_stat != "hp" or game_start:
			current_stats[c_stat] = base_stats[c_stat] + mod_stats[c_stat]
					
func take_damage(damage):
	damage = damage - current_stats.defense
	print(damage)
	create_hit_effect()
	combat_text(int(damage))
	
	if damage > 0:
		current_stats.hp -= damage
		
	emit_signal("damage_taken", [current_stats.hp, current_stats.max_hp])
	hit = true
	if current_stats.hp <= 0:
		if is_instance_valid(active_skill):
			active_skill.queue_free()
		queue_free()

func move_entity(dir):
	if tile_map.is_walkable(grid_pos + dir):
		grid_pos += dir
		audio.play_effect("walk")
		move_tween(dir)
	else:
		emit_signal("bumped_something", self, grid_pos + dir)
		position += dir * config.tile_size
		bump_tween(-dir)
	
		# Bumping wall doesn't use turn	
		if tile_map.get_cellv(grid_pos + dir) == tile_map.TileType.WALL:
			return true
			
# Animations		
func move_tween(dir):
	if tween_move.is_active():
		yield($TweenMove, "tween_all_completed")
	tween_move.interpolate_property(self, "position", position, position + (dir * config.tile_size),
	1.0/base_tween_speed, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	
	tween_move.start()
	
func bump_tween(dir):
	tween_effect.interpolate_property(self, "position", position, position + dir * config.tile_size,
	1.0/base_tween_speed, Tween.TRANS_SINE, Tween.EASE_OUT_IN)
	
	tween_effect.start()

# Skill animations
func windslash_tween():
	tween_effect.interpolate_property(self, "scale", Vector2(0.5, 0.5), Vector2(1, 1), 
	1.0/base_tween_speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	tween_effect.start()
	
func overheat_tween():
	tween_effect.interpolate_property(self, "modulate:a", .2, 1, 
	2.0/base_tween_speed, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	tween_effect.start()

# Particles and effects
func combat_text(text, crit=false):
	var combat_text = combatText.instance()
	var scene = get_tree().current_scene
	var x_pos = (global_position.x - config.tile_size) - (len(str(text))) + 1
	if typeof(text) == TYPE_INT:
		x_pos -= 1
	combat_text.get_child(0).rect_global_position = Vector2(x_pos, global_position.y - (config.tile_size+2))
	scene.add_child(combat_text)
	combat_text.get_child(0).show_value(text, Vector2(0, -config.tile_size), .5, (name=="Player"), crit)
	
func create_hit_effect():
	var scene = get_tree().current_scene
	var hit_effect = hitEffect.instance()
	var particles = hit_effect.get_child(0)
	particles.process_material.color = Color(1, 1, 1, 1)
	if name != "Player":
		particles.process_material.color = Color(1, 0, 0.302, 1)
	
	scene.add_child(hit_effect)
	
	# Center its effect position
	hit_effect.global_position = Vector2(global_position.x + (config.tile_size/2), global_position.y + (config.tile_size/2))
	
# Skills
func create_skill(skill, type, dir):
	var new_skill = Skills[skill]["scene"].instance()
	var scene = get_tree().current_scene
	new_skill.position = Vector2((grid_pos.x*config.tile_size) + (config.tile_size/2), (grid_pos.y*config.tile_size) + (config.tile_size/2))
	new_skill.direction = dir
	new_skill.stats = Skills[skill]["stats"].duplicate()
	new_skill.skill_user = self
	scene.add_child(new_skill)
	active_skill = new_skill
	equipped_skills[type]["current_cooldown"] = new_skill.stats.cooldown
	
	return new_skill
	
func center(x, y):
	return Vector2((x + 0.5) * config.tile_size, (y + 0.5) * config.tile_size)

