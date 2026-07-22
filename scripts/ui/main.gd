extends Control


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("132735")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var label := Label.new()
	label.text = "惊魂期末周\n工程初始化完成"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(label)
