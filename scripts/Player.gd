extends "res://scripts/Entity.gd"

onready var vis_map = get_parent().get_node("VisibilityMap")

var input_buffer = []
onready var States = get_parent().States
signal toggle_inventory(new_inventory)
signal swapped_skill()
signal item_selected(item)

var skill_type = null

func _ready():
	call_deferred("update_visuals")

func _process(_delta):
	# Handle input buffer
	if can_act && input_buffer && !tween_move.is_active() && !tween_effect.is_active():
		var key = input_buffer.pop_front()
		if key in config.inputs["movement"].keys():
			if get_parent().state == States.Main:
				move_entity(config.inputs["movement"][key])
				end_turn()
	pass
func _unhandled_input(event):
	if tween_move.is_active() || tween_effect.is_active():
		return

	for dir in config.inputs["movement"].keys():
		if event.is_action_pressed(dir):
			if !can_act:
				input_buffer.append(dir)
				if len(input_buffer) > 1:
					input_buffer.pop_front()
				return
			
			if get_parent().state == States.Targeting:
				var skill = create_skill(equipped_skills[skill_type]["skill"], skill_type, config.inputs["movement"][dir])
				get_parent().change_state(States.Targeting)
			else:
				var bumped_wall = move_entity(config.inputs["movement"][dir])
				if bumped_wall:
					return
			end_turn()
	
	for skill in config.inputs["skills"]:
		if event.is_action_pressed(skill):
			var type = skill.replace("_skill", "")
			if equipped_skills[type]["skill"] && !equipped_skills[type]["current_cooldown"]:
				if can_act && (get_parent().state == States.Main || get_parent().state == States.Targeting):
					print(true)
					skill_type = type
					get_parent().change_state(States.Targeting)
				
	if event.is_action_pressed("inventory"):
		if get_parent().state == States.Main || get_parent().state == States.Inventory:
			get_parent().change_state(States.Inventory)
			emit_signal("toggle_inventory", inventory)	
	elif event.is_action_pressed("ui_cancel"):
		print(get_parent().state)
		if get_parent().state == States.Inventory:
			emit_signal("toggle_inventory", inventory)
		get_parent().change_state(States.Main, false)
		
func update_visuals():
	for x in range(grid_pos.x - current_stats["sight_range"], grid_pos.x + current_stats["sight_range"]):
		for y in range(grid_pos.y - current_stats["sight_range"], grid_pos.y + current_stats["sight_range"]):
			var line = vis_map.bres_line(grid_pos, Vector2(x, y))
			for point in line:
				vis_map.set_cellv(point, -1)
				if tile_map.get_cellv(point) in vis_map.blockers:
					break

# Signals
func _on_TweenMove_tween_all_completed():
	update_visuals()
	
func _on_TweenEffect_tween_all_completed():
	update_visuals()
	
func _on_Item_used_from_inventory(index):
	var item = inventory[index]
	if item.item_info["equippable"]:
		item.equipped = not item.equipped
		if item.equipped:
			if equipped[item.item_info["equippable"]["slot"]]:
				equipped[item.item_info["equippable"]["slot"]].equipped = false
			equipped[item.item_info["equippable"]["slot"]] = item
			equipped_skills[item.item_info["type"]]["skill"] = item.item_info["skill"]
		else:
			equipped[item.item_info["equippable"]["slot"]] = null
			equipped_skills[item.item_info["type"]]["skill"] = null
		calculate_stats()
		emit_signal("swapped_skill")
	end_turn()
	
func _on_Item_selected_from_inventory(index):
	var item = null
	if index != null:
		item = inventory[index]
	emit_signal("item_selected", item)






