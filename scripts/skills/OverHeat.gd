extends Area2D

onready var audio = $"/root/AudioManager"
onready var tween_dir = $TweenDir
onready var tween_a = $TweenA
onready var sprite = $Sprite
onready var particle = $Particles2D

var direction = Vector2.UP
var skill_user = "Player"
var stats = {}
var area_hit = []

func _ready():
	if skill_user.name != "Player":
		sprite.modulate = Color(1, 0, 0.302, 1)
		particle.process_material.color = Color(1, 0, 0.302, 1)
	
	rotation = direction.angle()
	audio.play_skill_effect("overheat_use")
	
	var movement = (stats["distance"] * direction)*8
	var end_position = Vector2(position.x + movement.x, position.y + movement.y)
	tween_dir.interpolate_property(self, "position", position, end_position,
	1.0/4, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween_dir.start()
	tween_a.interpolate_property(self, "modulate:a",
			1.0, 0.2, .1 * stats["distance"],
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween_a.start()
	
func calculate_stats():
	stats["distance"] += skill_user.current_stats.power
	stats["damage"] += skill_user.current_stats.power
	
func _completed(end_early = false):
	if !end_early:
		yield($TweenDir, "tween_all_completed")
	if is_instance_valid(skill_user):
		skill_user.active_skill = null
		skill_user.take_damage(stats["damage"] / 4)

	queue_free()
	

func _on_OverHeat_area_entered(area):
	if area:
		if area != skill_user && !(area in area_hit):
			audio.play_skill_effect("overheat_use")
			area.take_damage(stats["damage"])
			area_hit.append(area)
