extends ColorRect

onready var hp = $Background/heart/value
onready var max_hp = $Background/heart/max_value
onready var attack = $Background/attack/value
onready var defense = $Background/armor/value
onready var power = $Background/power/value

func init_ui(stats):
	# Init ui values
	hp.hp_text = [stats.hp, stats.max_hp]
	max_hp.text = str(stats.max_hp)
	attack.text = str(stats.attack)
	defense.text = str(stats.defense)
	power.text = str(stats.power)
	
func _on_Player_damage_taken(value):
	hp.hp_text = value
