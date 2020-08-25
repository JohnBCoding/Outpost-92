extends Area2D

onready var audio = $"/root/AudioManager"
onready var tween_dir = $TweenDir
onready var tween_a = $TweenA

var direction = Vector2.UP
var skill_user = "Player"
var power = 1
var damage = 2 + power
var distance = 1 + power
var cooldown = 5

func _ready():
	rotation = direction.angle()
	audio.play_skill_effect("windslash_use")
	
	var movement = (distance * direction)*8
	var end_position = Vector2(position.x + movement.x, position.y + movement.y)
	tween_dir.interpolate_property(self, "position", position, end_position,
	1.0/4, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween_dir.start()
	tween_a.interpolate_property(self, "modulate:a",
			1.0, 0.2, .1 * distance,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween_a.start()

func _on_WindSlash_area_entered(area):
	if area.name != skill_user:
		audio.play_skill_effect("windslash_hit")
		area.take_damage(damage)

func _completed():
	yield($TweenDir, "tween_all_completed")
	queue_free()
