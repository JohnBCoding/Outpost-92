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
onready var utility_panel = $Skills/Background/UtilityPanel
onready var Utility_label = $Skills/Background/UtilityPanel/UtilityLabel

onready var player = null

func init_ui(new_player):
	player = new_player
	
	# Init ui values
	hp.hp_text = [player.mod_stats.hp, player.mod_stats.max_hp]
	max_hp.text = str(player.mod_stats.max_hp)
	attack.text = str(player.mod_stats.attack)
	defense.text = str(player.mod_stats.defense)
	power.text = str(player.mod_stats.power)
	
	# Init skill sprites
	if player.equipped_skills["weapon"]["skill"]:
		weapon_sprite.texture = player.Skills[player.equipped_skills["weapon"]["skill"]]["icon"]
	
func _process(_delta):
	if player.equipped_skills["weapon"]["current_cooldown"] > 0:
		weapon_panel.modulate.a = .4
		weapon_label.text = str(player.equipped_skills["weapon"]["current_cooldown"])
	else:
		weapon_panel.modulate.a = 1
		weapon_label.text = "z"

# Signals
func _on_Player_damage_taken(value):
	hp.hp_text = value
	
func _on_Player_swapped_skill():
	# Update player stats
	attack.text = str(player.mod_stats.attack)
	defense.text = str(player.mod_stats.defense)
	power.text = str(player.mod_stats.power)
	
	# Update player skill icons
	if player.equipped_skills["weapon"]["skill"]:
		weapon_sprite.texture = player.Skills[player.equipped_skills["weapon"]["skill"]]["icon"]
	else:
		weapon_sprite.texture = null
