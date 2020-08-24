extends Area2D

onready var config = $"/root/Config"
onready var audio = $"/root/AudioManager"
onready var vis_map = get_parent().get_node("VisibilityMap")

var item_name = "Test Item"
var stackable = false
var count = 1

var disabled = false

func _ready():
	position = position.snapped(Vector2.ONE * config.tile_size)
	add_to_group("items")
	
func _process(_delta):
	var cell_pos = vis_map.world_to_map(position)
	if vis_map.get_cell(cell_pos.x, cell_pos.y) == 0:
		visible = false
	else:
		visible = true
		
func add_item_to_inventory(entity):
	entity.combat_text(item_name)
	
	# Check if item should be stacked
	for item in entity.inventory:
		if item.stackable && item.item_name == item_name:
			item.count += 1
			queue_free()
			return
	
	# Otherwise add it regularly
	entity.inventory.append(self)
	var main = get_tree().current_scene
	main.remove_child(self)
	
func _on_Item_area_entered(area):
	if area.name != "Player":
		disabled = true
		return
	elif area.name == "Player" && !disabled:
		yield(get_tree().create_timer(.15), "timeout")
		var area_tile = vis_map.world_to_map(area.position)
		var item_tile = vis_map.world_to_map(position)
		if area_tile == item_tile:
			audio.stream = audio.item_pickup_effect
			audio.play()
			add_item_to_inventory(area)

func _on_Item_area_exited(area):
	if area.name != "Player":
		disabled = false
