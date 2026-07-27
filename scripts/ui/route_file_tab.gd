extends Button
class_name RouteFileTab

signal route_selected(route_id: String)

const PAPER := Color("#E5DAC4")
const PAPER_LIGHT := Color("#F5EFE2")
const PAPER_DARK := Color("#CBBDA3")
const INK := Color("#2B342F")
const MUTED := Color("#687169")

var route_data: Dictionary = {}
var selected := false
var _hovered := false
var _title_label: Label
var _subtitle_label: Label
var _index_label: Label


func configure(config: Dictionary, group: ButtonGroup) -> void:
	route_data = config
	name = "Trait_%s" % str(route_data.get("id", "study"))
	toggle_mode = true
	button_group = group
	text = ""
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_meta("trait_id", str(route_data.get("id", "study")))
	set_meta("audio_cue", &"select")
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_build_labels()
	mouse_entered.connect(func():
		_hovered = true
		queue_redraw()
	)
	mouse_exited.connect(func():
		_hovered = false
		queue_redraw()
	)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	pressed.connect(func(): route_selected.emit(str(route_data.get("id", "study"))))
	toggled.connect(func(value: bool):
		selected = value
		_update_labels()
		queue_redraw()
	)
	_update_labels()
	queue_redraw()


func set_selected(value: bool) -> void:
	button_pressed = value
	selected = value
	_update_labels()
	queue_redraw()


func _draw() -> void:
	if route_data.is_empty():
		return
	var accent := Color(str(route_data.get("accent", "#9E2A2F")))
	var lift := -3.0 if selected else (-1.0 if _hovered or has_focus() else 0.0)
	var points := PackedVector2Array([
		Vector2(0, 19 + lift),
		Vector2(76, 19 + lift),
		Vector2(92, 2 + lift),
		Vector2(210, 2 + lift),
		Vector2(226, 19 + lift),
		Vector2(size.x, 19 + lift),
		Vector2(size.x, size.y),
		Vector2(0, size.y),
	])
	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(4, 5))
	draw_colored_polygon(shadow, Color("#4B3D2B28"))
	var fill := PAPER_LIGHT if selected else (PAPER.lightened(0.04) if _hovered or has_focus() else PAPER)
	draw_colored_polygon(points, fill)
	draw_polyline(PackedVector2Array([
		points[0], points[1], points[2], points[3], points[4], points[5], points[6], points[7], points[0],
	]), Color(accent, 0.82 if selected else 0.48), 2.0 if selected else 1.0, true)
	draw_rect(Rect2(0, 19 + lift, 7, size.y - 19 - lift), accent, true)
	draw_line(Vector2(22, size.y - 10), Vector2(size.x - 20, size.y - 10), Color(accent, 0.42), 1.0)
	if selected:
		draw_circle(Vector2(size.x - 27, 39), 11, accent)
		draw_line(Vector2(size.x - 32, 39), Vector2(size.x - 28, 43), PAPER_LIGHT, 2.0, true)
		draw_line(Vector2(size.x - 28, 43), Vector2(size.x - 21, 34), PAPER_LIGHT, 2.0, true)


func _build_labels() -> void:
	_index_label = _make_label(str(route_data.get("index", "01")), 12, MUTED)
	_index_label.position = Vector2(18, 29)
	_index_label.size = Vector2(38, 23)
	add_child(_index_label)

	_title_label = _make_label(str(route_data.get("name", "路线")), 21, INK)
	_title_label.position = Vector2(63, 23)
	_title_label.size = Vector2(170, 34)
	add_child(_title_label)

	_subtitle_label = _make_label(str(route_data.get("subtitle", "")), 13, MUTED)
	_subtitle_label.position = Vector2(63, 55)
	_subtitle_label.size = Vector2(size.x - 105, 25)
	add_child(_subtitle_label)


func _update_labels() -> void:
	if _title_label == null:
		return
	var accent := Color(str(route_data.get("accent", "#9E2A2F")))
	_title_label.add_theme_color_override("font_color", accent if selected else INK)
	_index_label.add_theme_color_override("font_color", accent if selected else MUTED)


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
