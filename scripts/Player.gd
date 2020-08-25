extends "res://scripts/Entity.gd"

onready var tile_map = get_parent().get_node("TileMap")
onready var vis_map = get_parent().get_node("VisibilityMap")

var input_buffer = []
onready var States = get_parent().States
signal toggle_inventory(new_inventory, new_equipped)

func _ready():
	call_deferred("update_visuals")

func _process(_delta):
	# Handle input buffer
	if can_act && input_buffer && !tween.is_active():
		var key = input_buffer.pop_front()
		if key in config.inputs["movement"].keys():
			move_entity(config.inputs["movement"][key])
			end_turn()
		
func _unhandled_input(event):
	if tween.is_active():
		return

	for dir in config.inputs["movement"].keys():
		if event.is_action_pressed(dir):
			if !can_act:
				input_buffer.append(dir)
				if len(input_buffer) > 3:
					input_buffer.pop_front()
				return
			
			if get_parent().state == States.Targeting:
				var skill = Skills["windslash"].instance()
				var scene = get_tree().current_scene
				skill.position = Vector2(position.x + (config.tile_size/2), position.y + (config.tile_size/2))
				skill.direction = config.inputs["movement"][dir]
				scene.add_child(skill)
				active_skill = skill
				get_parent().change_state(States.Targeting)
			else:
				move_entity(config.inputs["movement"][dir])
			end_turn()
	
	if event.is_action_pressed("inventory"):
		if get_parent().state == States.Main or get_parent().state == States.Inventory:
			get_parent().change_state(States.Inventory)
			emit_signal("toggle_inventory", inventory, equipped)
	
	elif event.is_action_pressed("weapon_skill"):
		if can_act && (get_parent().state == States.Main or get_parent().state == States.Targeting):
			get_parent().change_state(States.Targeting)
			
	elif event.is_action_pressed("ui_cancel"):
		get_parent().change_state(States.Main)
		emit_signal("toggle_inventory", inventory, equipped)

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
