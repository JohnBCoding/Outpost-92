extends CenterContainer

onready var root = get_node("/root/World")

func _process(_delta):
	
	if root.state == root.States.Targeting:
		visible = true
		rect_position = Vector2(root.player.position.x + 4, root.player.position.y + 4)
	else:
		visible = false
	
