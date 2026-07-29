class_name StatusRibbon
extends Control

const PAPER := Color("#F7F1E5")
const PAPER_SHADOW := Color("#2A312B20")
const INK := Color("#24342E")
const DARK_SURFACE := Color("#102024E8")
const DARK_INK := Color("#F4F2E9")
const MUTED := Color("#66766E")
const DARK_MUTED := Color("#A9B6B2")
const TRACK_LIGHT := Color("#D6CCB9")
const TRACK_DARK := Color("#294044")

const STATUS_ITEMS := [
	{"id": "study", "label": "学习", "color": "#3C806D"},
	{"id": "project", "label": "项目", "color": "#477FA8"},
	{"id": "energy", "label": "精力", "color": "#BD8B3E"},
	{"id": "stress", "label": "压力", "color": "#B84850"},
]


func configure(values: Dictionary, paper_mode: bool = true, item_width: float = 114.0, item_height: float = 46.0) -> void:
	for child in get_children():
		child.queue_free()
	var gap := 6.0
	custom_minimum_size = Vector2(item_width * STATUS_ITEMS.size() + gap * (STATUS_ITEMS.size() - 1), item_height)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in STATUS_ITEMS.size():
		var item: Dictionary = STATUS_ITEMS[index]
		var value := clampi(int(values.get(str(item.id), 0)), 0, 100)
		var accent := _display_color(str(item.id), value, Color(str(item.color)))
		var card := PanelContainer.new()
		card.name = "Status_%s" % str(item.id)
		card.position = Vector2(index * (item_width + gap), 0)
		card.size = Vector2(item_width, item_height)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_theme_stylebox_override("panel", _card_style(paper_mode, accent))
		add_child(card)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		card.add_child(box)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		box.add_child(row)
		var label := _label(str(item.label), 11 if item_width >= 108 else 10, MUTED if paper_mode else DARK_MUTED)
		row.add_child(label)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		var number := _label(str(value), 19 if item_width >= 108 else 16, accent)
		number.name = "StatusValue_%s" % str(item.id)
		row.add_child(number)
		var progress := ProgressBar.new()
		progress.name = "StatusMeter_%s" % str(item.id)
		progress.min_value = 0.0
		progress.max_value = 100.0
		progress.value = value
		progress.show_percentage = false
		progress.custom_minimum_size.y = 5
		progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progress.add_theme_stylebox_override("background", _track_style(TRACK_LIGHT if paper_mode else TRACK_DARK))
		progress.add_theme_stylebox_override("fill", _track_style(accent))
		box.add_child(progress)


func _card_style(paper_mode: bool, accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PAPER, 0.82) if paper_mode else DARK_SURFACE
	style.border_color = Color(accent, 0.48)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 4
	if paper_mode:
		style.shadow_color = PAPER_SHADOW
		style.shadow_size = 2
		style.shadow_offset = Vector2(1, 2)
	return style


func _track_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style


func _display_color(status_id: String, value: int, base_color: Color) -> Color:
	if status_id == "energy" and value <= 25:
		return Color("#B84850")
	if status_id == "stress" and value >= 70:
		return Color("#A82F39")
	if status_id in ["study", "project"] and value < 25:
		return Color("#A36C2B")
	return base_color


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result
