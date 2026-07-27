extends Button
class_name CampusMapHotspot

signal location_selected(location_id: String)
signal location_hovered(location_id: String, active: bool)

const PAPER := Color("#F1EBDD")
const INK := Color("#26352F")
const SDU_RED := Color("#9E2A2F")
const SHADOW := Color("#23312838")

var location_data: Dictionary = {}
var selected := false
var current := false
var _hovered := false
var _name_label: Label
var _state_label: Label


func configure(data: Dictionary, is_current: bool = false) -> void:
	location_data = data
	current = is_current
	name = "Location_%s" % str(location_data.get("id", "unknown"))
	text = ""
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "%s\n%s\n点击后在地图下方查看行程" % [
		str(location_data.get("name", "校园地点")),
		str(location_data.get("description", "")),
	]
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_build_labels()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	pressed.connect(_on_pressed)
	queue_redraw()


func set_selected(value: bool) -> void:
	selected = value
	if _state_label != null:
		_state_label.visible = selected or current
		_state_label.text = "已选" if selected else "此刻"
		_state_label.add_theme_color_override("font_color", PAPER if selected else INK)
	queue_redraw()


func _build_labels() -> void:
	_name_label = Label.new()
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.position = Vector2(4, size.y - 42)
	_name_label.size = Vector2(size.x - 8, 38)
	_name_label.text = _short_name(str(location_data.get("id", "")), str(location_data.get("name", "校园地点")))
	_name_label.add_theme_font_size_override("font_size", 17)
	_name_label.add_theme_color_override("font_color", INK)
	_name_label.add_theme_color_override("font_shadow_color", Color("#F6F0E4E6"))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_name_label)

	_state_label = Label.new()
	_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_state_label.position = Vector2(size.x - 51, 4)
	_state_label.size = Vector2(47, 23)
	_state_label.text = "此刻"
	_state_label.add_theme_font_size_override("font_size", 11)
	_state_label.add_theme_color_override("font_color", INK)
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_state_label.visible = current
	add_child(_state_label)


func _draw() -> void:
	if location_data.is_empty():
		return
	var accent := Color(str(location_data.get("color", "#627D6B")))
	var building_color := accent.lightened(0.37)
	if _hovered or has_focus():
		building_color = accent.lightened(0.27)
	if selected:
		building_color = accent.lightened(0.16)
	var id := str(location_data.get("id", ""))
	match id:
		"dorm":
			_draw_dorm(building_color, accent)
		"library":
			_draw_library(building_color, accent)
		"teaching":
			_draw_teaching(building_color, accent)
		"lab":
			_draw_lab(building_color, accent)
		"canteen":
			_draw_canteen(building_color, accent)
		"field":
			_draw_field(building_color, accent)
		_:
			draw_rect(Rect2(20, 18, size.x - 40, size.y - 72), building_color, true)
	if selected:
		draw_arc(Vector2(size.x * 0.5, size.y * 0.44), minf(size.x, size.y) * 0.39, 0.15, TAU - 0.15, 40, Color(SDU_RED, 0.82), 3.0, true)
		_draw_location_pin(Vector2(size.x * 0.5, 8), SDU_RED)
	if current and not selected:
		_draw_location_pin(Vector2(size.x * 0.5, 8), INK)
	var rule_color := SDU_RED if selected else Color(accent, 0.72 if _hovered else 0.36)
	draw_line(Vector2(18, size.y - 43), Vector2(size.x - 18, size.y - 43), rule_color, 2.0 if selected else 1.0, true)
	if _state_label != null and (selected or current):
		var chip_color := SDU_RED if selected else Color(PAPER, 0.92)
		draw_style_box(_rounded_box(chip_color, Color(SDU_RED, 0.45), 10), Rect2(_state_label.position, _state_label.size))


func _draw_dorm(fill: Color, accent: Color) -> void:
	for index in 3:
		var rect := Rect2(24 + index * 54, 28 + (index % 2) * 8, 42, 62)
		draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), SHADOW, true)
		draw_rect(rect, fill, true)
		draw_rect(rect, Color(accent, 0.82), false, 2.0)
		for floor in 3:
			draw_line(Vector2(rect.position.x + 8, rect.position.y + 16 + floor * 14), Vector2(rect.end.x - 8, rect.position.y + 16 + floor * 14), Color(accent, 0.5), 2.0)
	draw_line(Vector2(22, 94), Vector2(176, 94), Color(accent, 0.72), 4.0)


func _draw_library(fill: Color, accent: Color) -> void:
	var facade := Rect2(30, 37, size.x - 60, 55)
	draw_rect(Rect2(facade.position + Vector2(5, 6), facade.size), SHADOW, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(24, 38), Vector2(size.x * 0.5, 18), Vector2(size.x - 24, 38)
	]), fill)
	draw_polyline(PackedVector2Array([
		Vector2(24, 38), Vector2(size.x * 0.5, 18), Vector2(size.x - 24, 38)
	]), Color(accent, 0.88), 2.0)
	draw_rect(facade, fill, true)
	for column in 6:
		var x := facade.position.x + 13 + column * ((facade.size.x - 26) / 5.0)
		draw_line(Vector2(x, 45), Vector2(x, 87), Color(accent, 0.72), 3.0)
	for step in 3:
		draw_line(Vector2(24 - step * 4, 94 + step * 4), Vector2(size.x - 24 + step * 4, 94 + step * 4), Color(accent, 0.62), 2.0)


func _draw_teaching(fill: Color, accent: Color) -> void:
	var left := Rect2(14, 45, 72, 63)
	var center := Rect2(78, 25, 90, 83)
	var right := Rect2(160, 51, 82, 57)
	for rect in [left, center, right]:
		draw_rect(Rect2(rect.position + Vector2(5, 6), rect.size), SHADOW, true)
		draw_rect(rect, fill, true)
		draw_rect(rect, Color(accent, 0.78), false, 2.0)
	for x in [32, 54, 101, 123, 145, 181, 205, 227]:
		draw_line(Vector2(x, 58), Vector2(x, 96), Color(accent, 0.46), 2.0)
	draw_circle(Vector2(123, 43), 9, PAPER)
	draw_arc(Vector2(123, 43), 9, 0, TAU, 20, Color(accent, 0.8), 2.0)
	draw_line(Vector2(123, 43), Vector2(123, 37), Color(accent, 0.8), 1.5)
	draw_line(Vector2(123, 43), Vector2(128, 46), Color(accent, 0.8), 1.5)


func _draw_lab(fill: Color, accent: Color) -> void:
	var slab := PackedVector2Array([
		Vector2(30, 31), Vector2(size.x - 21, 22), Vector2(size.x - 39, 96), Vector2(20, 106)
	])
	var shadow := PackedVector2Array()
	for point in slab:
		shadow.append(point + Vector2(5, 6))
	draw_colored_polygon(shadow, SHADOW)
	draw_colored_polygon(slab, fill)
	draw_polyline(PackedVector2Array([slab[0], slab[1], slab[2], slab[3], slab[0]]), Color(accent, 0.86), 2.0)
	for row in 3:
		draw_line(Vector2(36, 48 + row * 17), Vector2(size.x - 45, 39 + row * 17), Color(accent, 0.48), 4.0)
	draw_circle(Vector2(size.x - 50, 27), 8, Color("#F5D46E"))
	draw_arc(Vector2(size.x - 50, 27), 8, 0, TAU, 20, Color(accent, 0.75), 2.0)


func _draw_canteen(fill: Color, accent: Color) -> void:
	var body := PackedVector2Array([
		Vector2(24, 49), Vector2(93, 25), Vector2(size.x - 21, 48),
		Vector2(size.x - 21, 100), Vector2(24, 100)
	])
	var shadow := PackedVector2Array()
	for point in body:
		shadow.append(point + Vector2(5, 6))
	draw_colored_polygon(shadow, SHADOW)
	draw_colored_polygon(body, fill)
	draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[4], body[0]]), Color(accent, 0.86), 2.0)
	draw_line(Vector2(93, 25), Vector2(93, 100), Color(accent, 0.42), 2.0)
	for x in [43, 67, 116, 140, 164]:
		draw_rect(Rect2(x, 61, 13, 23), Color(accent, 0.42), true)
	draw_rect(Rect2(size.x * 0.5 - 15, 73, 30, 27), Color(accent, 0.68), true)


func _draw_field(fill: Color, accent: Color) -> void:
	var center := Vector2(size.x * 0.5, 66)
	var radius := Vector2(size.x * 0.39, 46)
	draw_set_transform(center, 0.0, radius)
	draw_circle(Vector2.ZERO, 1.0, Color(fill, 0.92))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for inset in [0.0, 6.0, 12.0]:
		_draw_ellipse(center, radius - Vector2(inset * 1.6, inset), Color(accent, 0.72 - inset * 0.02), 2.0)
	draw_rect(Rect2(center.x - 38, center.y - 23, 76, 46), Color("#8EB987"), true)
	draw_rect(Rect2(center.x - 38, center.y - 23, 76, 46), Color(accent, 0.55), false, 1.5)
	draw_line(Vector2(center.x, center.y - 23), Vector2(center.x, center.y + 23), Color(PAPER, 0.8), 1.5)
	draw_circle(center, 7, Color(PAPER, 0.0), false, 1.5)


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for index in 49:
		var angle := TAU * float(index) / 48.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_polyline(points, color, width, true)


func _draw_location_pin(anchor: Vector2, color: Color) -> void:
	draw_circle(anchor + Vector2(0, 7), 7, PAPER)
	draw_arc(anchor + Vector2(0, 7), 7, 0, TAU, 18, color, 2.0, true)
	draw_colored_polygon(PackedVector2Array([
		anchor + Vector2(-4, 12), anchor + Vector2(4, 12), anchor + Vector2(0, 20)
	]), color)
	draw_circle(anchor + Vector2(0, 7), 2.5, color)


func _rounded_box(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	return box


func _short_name(id: String, fallback: String) -> String:
	match id:
		"dorm":
			return "学生公寓"
		"library":
			return "蒋震图书馆"
		"teaching":
			return "中心校区教学区"
		"lab":
			return "AI 学院机房"
		"canteen":
			return "齐园餐厅"
		"field":
			return "风雨操场"
		_:
			return fallback


func _on_mouse_entered() -> void:
	_hovered = true
	location_hovered.emit(str(location_data.get("id", "")), true)
	queue_redraw()


func _on_mouse_exited() -> void:
	_hovered = false
	location_hovered.emit(str(location_data.get("id", "")), false)
	queue_redraw()


func _on_focus_entered() -> void:
	location_hovered.emit(str(location_data.get("id", "")), true)
	queue_redraw()


func _on_focus_exited() -> void:
	location_hovered.emit(str(location_data.get("id", "")), false)
	queue_redraw()


func _on_pressed() -> void:
	location_selected.emit(str(location_data.get("id", "")))
