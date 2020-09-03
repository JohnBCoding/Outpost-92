extends ColorRect

onready var hp = $Background/heart/value
onready var max_hp = $Background/heart/max_value
onready var attack = $Background/attack/value
onready var defense = $Background/armor/value
onready var power = $Background/power/value

onready var weapon_panel = $Skills/Background/WeaponPanel
onready var weapon_label = $Skills/Background/WeaponPanel/WeaponLabel
onready var weapon_sprite = $Skills/Background/WeaponPanel/WeaponSprite
onready var armor_panel = $Skills/Background/ArmorPanel
onready var armor_label = $Skills/Background/ArmorPanel/ArmorLabel
onready var armor_sprite = $Skills/Background/ArmorPanel/ArmorSprite
onready var utility_panel = $Skills/Background/UtilityPanel
onready var utility_label = $Skills/Background/UtilityPanel/UtilityLabel
onready var utility_sprite = $Skills/Background/UtilityPanel/UtilitySprite

onready var tween = $Tween

onready var player = null

func init_ui(new_player):
	player = new_player
	
	# Init ui values
	default_status()
	
	# Init skill sprites
	if player.equipped_skills["weapon"]["skill"]:
		weapon_sprite.texture = player.Skills[player.equipped_skills["weapon"]["skill"]]["icon"]
	
func _process(_delta):
	if !is_instance_valid(player):
		return
		
	if player.equipped_skills["weapon"]["current_cooldown"] > 0:
		weapon_panel.modulate.a = .4
		weapon_label.text = str(player.equipped_skills["weapon"]["current_cooldown"])
	else:
		weapon_panel.modulate.a = 1
		weapon_label.text = "z"
	
	if player.equipped_skills["armor"]["current_cooldown"] > 0:
		armor_panel.modulate.a = .4
		armor_label.text = str(player.equipped_skills["armor"]["current_cooldown"])
	else:
		armor_panel.modulate.a = 1
		armor_label.text = "x"
	
	if player.equipped_skills["utility"]["current_cooldown"] > 0:
		utility_panel.modulate.a = .4
		utility_label.text = str(player.equipped_skills["utility"]["current_cooldown"])
	else:
		utility_panel.modulate.a = 1
		utility_label.text = "c"
		
func default_status():
	hp.text = str(player.current_stats["hp"])
	max_hp.text = str(player.current_stats["max_hp"])
	attack.text = str(player.current_stats["attack"])
	defense.text = str(player.current_stats["defense"])
	power.text = str(player.current_stats["power"])

func move_location_tween(destination):
	tween.interpolate_property(self, "rect_position", rect_position, destination,
	.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	
# Signals
func _on_Player_damage_taken(value):
	hp.hp_text = value
	
func _on_Player_swapped_skill():
	default_status()
	
	# Update player skill icons
	if player.equipped_skills["weapon"]["skill"]:
		weapon_sprite.texture = player.Skills[player.equipped_skills["weapon"]["skill"]]["icon"]
	else:
		weapon_sprite.texture = null
		
	if player.equipped_skills["armor"]["skill"]:
		armor_sprite.texture = player.Skills[player.equipped_skills["armor"]["skill"]]["icon"]
	else:
		armor_sprite.texture = null
	
	if player.equipped_skills["utility"]["skill"]:
		utility_sprite.texture = player.Skills[player.equipped_skills["utility"]["skill"]]["icon"]
	else:
		utility_sprite.texture = null
		
func _on_Player_item_selected(item):
	default_status()
	if item:
		if item.item_info.stats && !item.equipped:
			max_hp.text = str((player.current_stats["max_hp"] + item.item_info.stats["max_hp"]) - player.mod_stats["max_hp"])
			attack.text = str((player.current_stats["attack"] + item.item_info.stats["attack"]) - player.mod_stats["attack"])
			defense.text = str((player.current_stats["defense"] + item.item_info.stats["defense"]) - player.mod_stats["defense"])
			power.text = str((player.current_stats["power"] + item.item_info.stats["power"]) - player.mod_stats["power"])
