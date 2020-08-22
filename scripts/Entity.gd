extends Area2D

onready var config = $"/root/Config"
onready var audio = $"/root/AudioManager"

# Particle effects
const combatText = preload("res://scenes/CombatText.tscn")
const hitEffect = preload("res://scenes/HitEffect.tscn")

# Movement
onready var movement_ray = $MovementRay
onready var tween = $Tween
export var speed = 8
signal bumped_something(point, normal)
signal damage_taken(hp_values)

# Combat
var can_act = false
var stats = {
	hp = 2,
	max_hp = 2,
	attack = 1,
	defense = 0,
	power = 0,
}
var hit = false

func _ready():
	position = position.snapped(Vector2.ONE * config.tile_size)

func _process(_delta):
	if hit:
		modulate = Color(.4, .4, .4, 1)
		yield(get_tree().create_timer(.2), "timeout")
		modulate = Color(1, 1, 1)
		hit = false
		
func take_damage(damage):
	damage = damage - stats.defense
	create_hit_effect()
	combat_text(damage)
	
	if damage > 0:
		stats.hp -= damage
		
	emit_signal("damage_taken", [stats.hp, stats.max_hp])
	hit = true
	if stats.hp <= 0:
		queue_free()
		
func center(x, y):
	return Vector2((x + 0.5) * config.tile_size, (y + 0.5) * config.tile_size)

func move_entity(dir):
	movement_ray.cast_to = dir * config.tile_size
	movement_ray.force_raycast_update()
	if !movement_ray.is_colliding():
		audio.stream = audio.walk_effect
		audio.play()
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

# Particles and effects
func combat_text(damage, crit=false):
	var combat_text = combatText.instance()
	var scene = get_tree().current_scene
	combat_text.get_child(0).rect_global_position = Vector2(global_position.x - config.tile_size, global_position.y - (config.tile_size+2))
	scene.add_child(combat_text)
	combat_text.get_child(0).show_value(damage, Vector2(0, -config.tile_size), .5, (name=="Player"), crit)
	
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
