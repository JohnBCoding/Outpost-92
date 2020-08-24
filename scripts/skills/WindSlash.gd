extends Area2D

onready var tween = $Tween

var direction = Vector2.UP
var skill_user = "Player"
var power = 1
var distance = 1 + power

func _ready():
	rotation = direction.angle()

	var movement = (distance * direction)*8
	var end_position = Vector2(position.x + movement.x, position.y + movement.y)
	tween.interpolate_property(self, "position", position, end_position,
	1.0/8, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.start()

func _on_WindSlash_area_entered(area):
	if area.name != skill_user:
		area.take_damage(power)

func _on_Tween_tween_all_completed():
	queue_free()
