class_name AdaptiveScenePrototypeView
extends Control

const INK := Color("#F4F2E9")
const MUTED := Color("#9BAAA7")
const BACKGROUND := Color("#071013")
const SURFACE := Color("#0E191C")
const SURFACE_RAISED := Color("#142326")
const BORDER := Color("#294247")
const TEAL := Color("#63DDB8")
const GOLD := Color("#F4C45E")
const CORAL := Color("#FF8580")
const BLUE := Color("#7CB9E8")


func configure(data: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_hud(data)
	var media_width := float(data.get("media_width", 650.0))
	var media_position := Vector2(24, 84)
	var media_size := Vector2(media_width, 612)
	var content_position := Vector2(42 + media_width, 84)
	var content_size := Vector2(1238 - content_position.x, 612)
	_build_photo_stage(data, media_position, media_size)
	_build_interaction_panel(data, content_position, content_size)


func _build_background() -> void:
	var base := ColorRect.new()
	base.color = BACKGROUND
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)

	var upper_glow := ColorRect.new()
	upper_glow.color = Color("#1531374A")
	upper_glow.position = Vector2(0, 0)
	upper_glow.size = Vector2(1280, 190)
	upper_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(upper_glow)

	var rule := ColorRect.new()
	rule.color = Color("#5DDDB82B")
	rule.position = Vector2(24, 74)
	rule.size = Vector2(1232, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)


func _build_hud(data: Dictionary) -> void:
	var hud := PanelContainer.new()
	hud.position = Vector2(24, 16)
	hud.size = Vector2(1232, 48)
	hud.add_theme_stylebox_override("panel", _style(Color("#0D191CD9"), 13, Color("#2D4C50"), 1, 12))
	add_child(hud)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	hud.add_child(row)

	var brand := VBoxContainer.new()
	brand.custom_minimum_size.x = 222
	brand.add_theme_constant_override("separation", -2)
	row.add_child(brand)
	brand.add_child(_label("惊魂期末周", 18, INK))
	brand.add_child(_label("FINAL WEEK · CAMPUS LIFE", 9, Color("#6FA59A")))

	row.add_child(_divider())
	row.add_child(_compact_pair("日期", str(data.get("time", "第 3 天 · 早晨")), TEAL, 178))
	row.add_child(_compact_pair("地点", str(data.get("scene_name", "校园场景")), BLUE, 180))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	row.add_child(_stat_chip("精力", int(data.get("energy", 68)), TEAL))
	row.add_child(_stat_chip("压力", int(data.get("stress", 42)), CORAL))
	row.add_child(_stat_chip("考试", int(data.get("exam", 51)), GOLD))


func _build_photo_stage(data: Dictionary, stage_position: Vector2, stage_size: Vector2) -> void:
	var stage := PanelContainer.new()
	stage.position = stage_position
	stage.size = stage_size
	stage.add_theme_stylebox_override("panel", _style(Color("#0B1518"), 18, Color("#36545A"), 1, 8))
	add_child(stage)

	var media := Control.new()
	media.clip_contents = true
	stage.add_child(media)

	var image_backdrop := ColorRect.new()
	image_backdrop.color = Color("#10191B")
	image_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	media.add_child(image_backdrop)

	var photo := OrientedPhotoRect.new()
	photo.name = "PrototypePhoto"
	photo.configure(
		load(str(data.get("image_path", ""))) as Texture2D,
		int(data.get("orientation", 1)),
		false
	)
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	media.add_child(photo)

	var index_label := _label("SCENE  %s" % str(data.get("scene_index", "01 / 03")), 10, TEAL)
	index_label.position = Vector2(18, 16)
	index_label.size = Vector2(170, 24)
	index_label.add_theme_color_override("font_shadow_color", Color("#000000CC"))
	index_label.add_theme_constant_override("shadow_offset_x", 1)
	index_label.add_theme_constant_override("shadow_offset_y", 1)
	media.add_child(index_label)

	var caption := PanelContainer.new()
	caption.position = Vector2(14, stage_size.y - 82)
	caption.size = Vector2(stage_size.x - 28, 66)
	caption.add_theme_stylebox_override("panel", _style(Color("#081113E8"), 12, Color("#517076AA"), 1, 14))
	media.add_child(caption)
	var caption_row := HBoxContainer.new()
	caption_row.add_theme_constant_override("separation", 10)
	caption.add_child(caption_row)
	var caption_copy := VBoxContainer.new()
	caption_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption_copy.add_theme_constant_override("separation", 0)
	caption_row.add_child(caption_copy)
	caption_copy.add_child(_label(str(data.get("scene_name", "校园场景")), 19, INK))
	caption_copy.add_child(_label(str(data.get("activity", "本时段活动")), 12, MUTED))
	caption_row.add_child(_badge(str(data.get("photo_shape", "原比例")), TEAL))


func _build_interaction_panel(data: Dictionary, panel_position: Vector2, panel_size: Vector2) -> void:
	var panel := PanelContainer.new()
	panel.position = panel_position
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _style(Color("#0E191CF7"), 18, BORDER, 1, 22))
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var eyebrow_row := HBoxContainer.new()
	content.add_child(eyebrow_row)
	eyebrow_row.add_child(_badge(str(data.get("section", "校园事件")), Color(str(data.get("accent", "#63DDB8")))))
	var eyebrow_spacer := Control.new()
	eyebrow_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eyebrow_row.add_child(eyebrow_spacer)
	eyebrow_row.add_child(_label("选择后推进 1 个时段", 11, Color("#7D908D")))

	var title := _label(str(data.get("title", "这个时段要怎么安排？")), int(data.get("title_size", 30)), INK)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.y = 42
	content.add_child(title)

	var body := _label(str(data.get("body", "")), 16, MUTED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = float(data.get("body_height", 66))
	content.add_child(body)

	var state_row := HBoxContainer.new()
	state_row.add_theme_constant_override("separation", 7)
	content.add_child(state_row)
	for state_value in data.get("state_tags", []):
		var state: Dictionary = state_value
		state_row.add_child(_badge(str(state.get("text", "状态")), Color(str(state.get("color", "#7CB9E8")))))

	var separator := HSeparator.new()
	separator.modulate = Color("#49606466")
	separator.custom_minimum_size.y = 5
	content.add_child(separator)

	var question := HBoxContainer.new()
	content.add_child(question)
	var question_label := _label(str(data.get("question", "你准备怎么做？")), 15, INK)
	question_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question.add_child(question_label)
	question.add_child(_label("%d 个选择" % data.get("choices", []).size(), 11, Color("#728681")))

	var choices := VBoxContainer.new()
	choices.add_theme_constant_override("separation", 9)
	choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(choices)
	var choice_index := 1
	for choice_value in data.get("choices", []):
		choices.add_child(_choice_card(choice_index, choice_value, Color(str(data.get("accent", "#63DDB8")))))
		choice_index += 1

	var footer := HBoxContainer.new()
	content.add_child(footer)
	footer.add_child(_label("●  自动存档开启", 10, Color("#5D8C80")))
	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)
	footer.add_child(_label("ESC  暂停", 10, Color("#61736F")))


func _choice_card(index: int, choice_value, accent: Color) -> PanelContainer:
	var choice: Dictionary = choice_value
	var card := PanelContainer.new()
	card.custom_minimum_size.y = 78
	card.add_theme_stylebox_override("panel", _style(Color("#152528"), 12, Color(accent, 0.52), 1, 12))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)
	card.add_child(row)

	var number := _label("%02d" % index, 13, accent)
	number.custom_minimum_size.x = 27
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(number)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	copy.add_child(_label(str(choice.get("title", "选择")), 16, INK))
	var detail := _label(str(choice.get("detail", "")), 11, MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(detail)

	var effect := _badge(str(choice.get("effect", "查看后果")), Color(str(choice.get("effect_color", "#7CB9E8"))))
	effect.custom_minimum_size.x = 104
	row.add_child(effect)
	return card


func _compact_pair(key: String, value: String, accent: Color, width: float) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = width
	box.add_theme_constant_override("separation", -1)
	box.add_child(_label(key, 9, Color("#657975")))
	box.add_child(_label(value, 14, accent))
	return box


func _stat_chip(title: String, value: int, accent: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(94, 34)
	chip.add_theme_stylebox_override("panel", _style(Color(accent, 0.08), 9, Color(accent, 0.42), 1, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	chip.add_child(row)
	var title_label := _label(title, 10, Color("#91A09D"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	row.add_child(_label(str(value), 14, accent))
	return chip


func _badge(text_value: String, accent: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", _style(Color(accent, 0.09), 8, Color(accent, 0.45), 1, 8))
	var text_label := _label(text_value, 10, accent.lightened(0.08))
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(text_label)
	return badge


func _divider() -> VSeparator:
	var divider := VSeparator.new()
	divider.modulate = Color("#45606488")
	divider.custom_minimum_size.x = 7
	return divider


func _label(text_value: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result


func _style(color: Color, radius: int, border_color: Color, border_width: int, margin: float) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.corner_radius_top_left = radius
	result.corner_radius_top_right = radius
	result.corner_radius_bottom_left = radius
	result.corner_radius_bottom_right = radius
	result.border_width_left = border_width
	result.border_width_right = border_width
	result.border_width_top = border_width
	result.border_width_bottom = border_width
	result.border_color = border_color
	result.content_margin_left = margin
	result.content_margin_right = margin
	result.content_margin_top = margin
	result.content_margin_bottom = margin
	return result
