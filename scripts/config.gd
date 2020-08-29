extends Node

const tile_size = 8
const inputs = {
	"movement": {
		"right": Vector2.RIGHT,
		"left": Vector2.LEFT,
		"up": Vector2.UP,
		"down": Vector2.DOWN
	},
	"skills": ["weapon_skill", "armor_skill", "utility_skill"]
}

# Map
const MAP_WIDTH = 16
const MAP_HEIGHT = 16
const MAX_ROOM_TRY = 25
const MIN_ROOMS = 8
const MAX_ROOM_SIZE = 6
const MAX_MOB_PER_ROOM = 4
const MAX_OBJECT_PER_ROOM = 4
const MAX_ITEMS_PER_LEVEL = 4
const DOOR_SPAWN_RATE = 4



