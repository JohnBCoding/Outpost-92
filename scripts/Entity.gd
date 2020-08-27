extends Area2D

onready var config = $"/root/Config"
onready var audio = $"/root/AudioManager"

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
			"cooldown": 3,
		}
	}
}
var active_skill = null
var equipped_skills = {
	"weapon": {
		"skill": null,
		"current_cooldown": 0
	},
	"armor":  {
		"skill": null,
		"current_cooldown": 0
	},
	"utility":  {
		"skill": null,
		"current_cooldown": 0
	},
}

# Movement
onready var movement_ray = $MovementRay
onready var tween = $Tween
export var speed = 8
signal bumped_something(point, normal)
signal damage_taken(hp_values)

# Combat
var can_act = false
var base_stats = {
	"hp": 2,
	"max_hp": 2,
	"attack": 1,
	"defense": 0,
	"power": 0,
}
var mod_stats = {
	"hp": 0,
	"max_hp": 0,
	"attack": 0,
	"defense": 0,
	"power": 0,
}

var sight_range = 4
var hit = false

# Inventory
var inventory = []
var equipped = {
	"Main Hand": null,
	"Off Hand": null,
	"Armor": null
}

func _ready():
	position = position.snapped(Vector2.ONE * config.tile_size)
	calculate_stats()
	
func _process(_delta):
	if hit:
		modulate = Color(.4, .4, .4, 1)
		yield(get_tree().create_timer(.2), "timeout")
		modulate = Color(1, 1, 1)
		hit = false

func end_turn():
	can_act = false
	if tween.is_active():
		yield($Tween, "tween_all_completed")
	if active_skill:
		yield(active_skill._completed(), "completed")
	yield(get_tree().create_timer(.01), "timeout")
	
	# Decrease cooldowns
	for skill in equipped_skills.keys():
		if equipped_skills[skill]["current_cooldown"] > 0:
			equipped_skills[skill]["current_cooldown"] -= 1
			
	get_parent().get_turn()

# Combat
func calculate_stats():
	if mod_stats["hp"] == 0:
		mod_stats["hp"] = base_stats["hp"]
		
	for b_stat in base_stats.keys():
		if b_stat != "hp":
			mod_stats[b_stat] = base_stats[b_stat]
	
	for slot in equipped.keys():
		if equipped[slot]:
			for e_stat in equipped[slot].item_info["stats"]:
				mod_stats[e_stat] += equipped[slot].item_info["stats"][e_stat]
				
func take_damage(damage):
	damage = damage - mod_stats.defense
	create_hit_effect()
	combat_text(int(damage))
	
	if damage > 0:
		mod_stats.hp -= damage
		
	emit_signal("damage_taken", [mod_stats.hp, mod_stats.max_hp])
	hit = true
	if mod_stats.hp <= 0:
		queue_free()

func move_entity(dir):
	movement_ray.cast_to = dir * config.tile_size
	movement_ray.force_raycast_update()
	if !movement_ray.is_colliding():
		audio.play_effect("walk")
		move_tween(dir)
	else:
		emit_signal("bumped_something", position, movement_ray)
		position += dir * config.tile_size
		bump_tween(-dir)

# Animations		
func move_tween(dir):
	tween.interpolate_property(self, "position", position, position + dir * config.tile_size,
	1.0/speed, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	
	tween.start()
	
func bump_tween(dir):
	tween.interpolate_property(self, "position", position, position + dir * config.tile_size,
	1.0/speed, Tween.TRANS_SINE, Tween.EASE_OUT_IN)
	
	tween.start()

# Skill animations
func windslash_tween():
	tween.interpolate_property(self, "scale", Vector2(0.5, 0.5), Vector2(1, 1), 
	1.0/speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	tween.start()

# Particles and effects
func combat_text(text, crit=false):
	var combat_text = combatText.instance()
	var scene = get_tree().current_scene
	var x_pos = (global_position.x - config.tile_size) - (len(str(text)) + 1 / 2 )
	combat_text.get_child(0).rect_global_position = Vector2(x_pos, global_position.y - (config.tile_size+2))
	scene.add_child(combat_text)
	combat_text.get_child(0).show_value(text, Vector2(0, -config.tile_size), .5, (name=="Player"), crit)
	
func create_hit_effect():
	var scene = get_tree().current_scene
	var hit_effect = hitEffect.instance()
	var particles = hit_effect.get_child(0)
	if name != "Player":
		particles.process_material.color = Color(1, 0, 0.302, 1)
	else:
		particles.process_material.color = Color(1, 1, 1, 1)
	scene.add_child(hit_effect)
	
	# Center its effect position
	hit_effect.global_position = Vector2(global_position.x + (config.tile_size/2), global_position.y + (config.tile_size/2))
	
# Skills
func create_skill(skill, type, dir):
	var new_skill = Skills[skill]["scene"].instance()
	var scene = get_tree().current_scene
	new_skill.position = Vector2(position.x + (config.tile_size/2), position.y + (config.tile_size/2))
	new_skill.direction = config.inputs["movement"][dir]
	new_skill.stats = Skills[skill]["stats"].duplicate()
	new_skill.skill_user = self
	scene.add_child(new_skill)
	active_skill = new_skill
	equipped_skills[type]["current_cooldown"] = new_skill.stats.cooldown
	
func center(x, y):
	return Vector2((x + 0.5) * config.tile_size, (y + 0.5) * config.tile_size)
