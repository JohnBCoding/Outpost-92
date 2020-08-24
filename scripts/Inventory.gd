extends ColorRect
onready var inventory_list= $Background/InventoryList

var equipped = {}
var prev_selection = 0

func _ready():
	visible = false

func load_inventory(new_inventory):
	for item in new_inventory:
		var text = item.item_name
		if item.stackable:
			text = text + " x " + str(item.count)
		inventory_list.add_item(text)
		
func _on_Player_toggle_inventory(new_inventory, new_equipped):
	visible = not visible
	equipped = new_equipped
	
	if !visible:
		if len(inventory_list.get_selected_items()) > 0:
			prev_selection = inventory_list.get_selected_items()[0]
			inventory_list.clear()
	else:
		load_inventory(new_inventory)
		inventory_list.grab_focus()
		inventory_list.select(prev_selection)
		inventory_list.ensure_current_is_visible()

