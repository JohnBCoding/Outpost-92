extends Area2D

onready var audio = $"/root/AudioManager"
onready var tween_dir = $TweenDir
onready var tween_a = $TweenA

var direction = Vector2.UP
var skill_user = "Player"
var stats = {}
var current_cooldown = null

func _ready():
	skill_user.windslash_tween()
	rotation = direction.angle()
	audio.play_skill_effect("windslash_use")
	calculate_stats()
	
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
	stats["distance"] += skill_user.mod_stats.power
	stats["damage"] += skill_user.mod_stats.power
	
func _on_WindSlash_area_entered(area):
	if area.name != skill_user.name:
		audio.play_skill_effect("windslash_hit")
		area.take_damage(stats["damage"])
		stats["damage"] -= 1

func _completed(end_early = false):
	if !end_early:
		yield($TweenDir, "tween_all_completed")
	queue_free()

func _on_WindSlash_body_entered(_body):
	stats["damage"] -= 1
