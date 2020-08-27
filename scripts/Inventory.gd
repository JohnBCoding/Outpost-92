extends ColorRect
onready var inventory_list= $Background/InventoryList

var prev_selection = 0
var prev_inventory = null
signal item_used(index)

func _ready():
	visible = false

func load_inventory(new_inventory):
	inventory_list.clear()
	var index = 0
	for item in new_inventory:
		set_bg = Color(0, 0, 0, 0)
		var text = item.item_name
		if item.item_info["stackable"]:
			text = text + " x " + str(item.count)
		if item.equipped:
			text = text + "????"
			
		inventory_list.add_item(text)
		index += 1
	inventory_list.select(prev_selection)
		
func _on_Player_toggle_inventory(new_inventory):
	visible = not visible
	prev_inventory = new_inventory
	
	if !visible:
		if len(inventory_list.get_selected_items()) > 0:
			prev_selection = inventory_list.get_selected_items()[0]
	else:
		load_inventory(new_inventory)
		inventory_list.grab_focus()
		inventory_list.ensure_current_is_visible()

func _on_InventoryList_item_activated(index):
	emit_signal("item_used", index)
	prev_selection = index
	load_inventory(prev_inventory)
