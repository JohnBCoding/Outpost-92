extends AudioStreamPlayer

onready var music_player = $Music
# load audio files
var music = {
	"main": preload("res://resources/audio/music/deepwater-ruins.ogg"),
	"boss": preload("res://resources/audio/music/night-chip.ogg"),
	"won": preload("res://resources/audio/music/night-chip.ogg"),
	"lost": preload("res://resources/audio/music/night-chip.ogg")
}
var effects = {
	"walk": preload("res://resources/audio/effects/walk.wav"),
	"bump": preload("res://resources/audio/effects/wall_bump.wav"),
	"chest_open": preload("res://resources/audio/effects/chest_open.wav"),
	"door_open": preload("res://resources/audio/effects/door_open.wav"),
	"destroyable": preload("res://resources/audio/effects/destroyable.wav"),
	"basic_attack": preload("res://resources/audio/effects/basic_attack.wav"),
	"item_pickup": preload("res://resources/audio/effects/item_pickup.wav"),
	"skills": {
		"windslash_use": preload("res://resources/audio/effects/skills/windslash_use.wav"),
		"windslash_hit": preload("res://resources/audio/effects/skills/windslash_hit.wav"),
		"overheat_use": preload("res://resources/audio/effects/skills/overheat_use.wav"),
		"overheat_hit": preload("res://resources/audio/effects/skills/overheat_hit.wav")
	}
	
}

func start_music():
	music_player.stream = music["main"]
	music_player.play()
	
func play_effect(effect):
	if playing:
		yield(self, "finished")
	stream = effects[effect]
	play()
	
func play_skill_effect(effect):
	if playing:
		stop()
	stream = effects["skills"][effect]
	play()
