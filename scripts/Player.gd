extends "res://scripts/Entity.gd"

onready var vis_map = get_parent().get_node("VisibilityMap")

func _ready():
	call_deferred("update_visuals")
	
func _unhandled_input(event):
	if !can_act:
		return
	if tween.is_active():
		return
	for dir in config.inputs.keys():
		if event.is_action_pressed(dir):
			move_entity(config.inputs[dir])
			can_act = false

func update_visuals():
	yield(get_tree().create_timer(.15), "timeout")
	var cell_pos = vis_map.world_to_map(position)
	var player_center = center(cell_pos.x, cell_pos.y)
	var space_state = get_world_2d().direct_space_state
	for x in range(16):
		for y in range(16):
			if vis_map.get_cell(x, y) == 0:
				var x_dir = 1 if x < cell_pos.x else -1
				var y_dir = 1 if y < cell_pos.y else -1
				var point = center(x, y) + Vector2(x_dir, y_dir) * config.tile_size / 2
				
				var blocked = space_state.intersect_ray(player_center, point, [self], collision_layer)
				if !blocked || (blocked.position - point).length() < 1:
					vis_map.set_cell(x, y, -1)
					

func _on_Tween_tween_all_completed():
	update_visuals()
