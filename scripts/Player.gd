extends "res://scripts/Entity.gd"

onready var tile_map = get_parent().get_node("TileMap")
onready var vis_map = get_parent().get_node("VisibilityMap")

var input_buffer = []
onready var States = get_parent().States
signal toggle_inventory(new_inventory)
signal swapped_skill()
var skill_type = null

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
				create_skill("windslash", skill_type, dir)
				get_parent().change_state(States.Targeting)
			else:
				move_entity(config.inputs["movement"][dir])
			end_turn()
	
	if event.is_action_pressed("inventory"):
		if get_parent().state == States.Main or get_parent().state == States.Inventory:
			get_parent().change_state(States.Inventory)
			emit_signal("toggle_inventory", inventory)
	
	elif event.is_action_pressed("weapon_skill"):
		if equipped_skills["weapon"]["skill"] && !equipped_skills["weapon"]["current_cooldown"]:
			if can_act && (get_parent().state == States.Main or get_parent().state == States.Targeting):
				skill_type = "weapon"
				get_parent().change_state(States.Targeting)
			
	elif event.is_action_pressed("ui_cancel"):
		if get_parent().state == States.Inventory:
			emit_signal("toggle_inventory", inventory)
		get_parent().change_state(States.Main)
		
func update_visuals():
	var map_pos = tile_map.world_to_map(position)
	for x in range(map_pos.x - sight_range, map_pos.x + sight_range):
		for y in range(map_pos.y - sight_range, map_pos.y + sight_range):
			var line = vis_map.bres_line(map_pos, Vector2(x, y))
			for point in line:
				vis_map.set_cellv(point, -1)
				if tile_map.get_cellv(point) in vis_map.blockers:
					break

# Signals
func _on_Tween_tween_all_completed():
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
