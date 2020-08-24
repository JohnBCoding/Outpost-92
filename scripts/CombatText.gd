extends Label

func show_value(value, travel, duration, player=false, crit=false):
	text = str(value)
	if typeof(value) == TYPE_INT:
		text = "-"+str(value)
	rect_pivot_offset = rect_size / 2
	
	if !player:
		add_color_override("font_color", Color(1, 0, 0.302, 1))
	$Tween.interpolate_property(self, "rect_position",
			rect_position, rect_position + travel,
			duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.interpolate_property(self, "modulate:a",
			1.0, 0.0, duration+1,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			
	$Tween.start()
	yield($Tween, "tween_all_completed")
	get_parent().queue_free()
