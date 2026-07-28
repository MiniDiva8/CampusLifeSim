extends Control
class_name CampusMapView

const HotspotScript = preload("res://scripts/ui/campus_map_hotspot.gd")
const PAPER := Color("#EAE2D2")
const PAPER_LIGHT := Color("#F7F1E5")
const PAPER_DARK := Color("#D4C9B4")
const INK := Color("#24342E")
const MUTED := Color("#66766E")
const LAWN := Color("#A8B79B")
const LAWN_DARK := Color("#71866E")
const ROAD := Color("#D9CEB9")
const ROAD_EDGE := Color("#A99D87")
const SDU_RED := Color("#9E2A2F")
const GOLD := Color("#BD8B3E")

const HOTSPOT_LAYOUT := {
	"dorm": {"position": Vector2(58, 180), "size": Vector2(210, 154)},
	"library": {"position": Vector2(322, 118), "size": Vector2(228, 154)},
	"teaching": {"position": Vector2(352, 346), "size": Vector2(260, 174)},
	"lab": {"position": Vector2(690, 126), "size": Vector2(224, 158)},
	"canteen": {"position": Vector2(824, 374), "size": Vector2(215, 154)},
	"field": {"position": Vector2(60, 395), "size": Vector2(266, 160)},
}

const HOVER_NOTE_LAYOUT := {
	"dorm": Vector2(245, 176),
	"library": Vector2(548, 106),
	"teaching": Vector2(615, 414),
	"lab": Vector2(910, 132),
	"canteen": Vector2(955, 474),
	"field": Vector2(323, 470),
}

const NPC_LOCATION := {
	"roommate": "dorm",
	"teammate": "lab",
	"scholar": "library",
	"monitor": "canteen",
}

const NPC_OFFSET := {
	"roommate": Vector2(142, 7),
	"teammate": Vector2(136, 10),
	"scholar": Vector2(146, 6),
	"monitor": Vector2(128, 9),
}

var data: Dictionary = {}
var selected_location_id := ""
var _hotspots: Dictionary = {}
var _locations: Dictionary = {}
var _detail_rule: ColorRect
var _detail_name: Label
var _detail_subtitle: Label
var _detail_description: Label
var _travel_button: Button
var _route_caption: Label
var _hover_note: PanelContainer
var _hover_note_rule: ColorRect
var _hover_note_name: Label
var _hover_note_actions: Label
var _hovered_location_id := ""


func configure(view_data: Dictionary) -> void:
	data = view_data
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_header()
	_build_deadline_notes()
	_build_hotspots()
	_build_npc_markers()
	_build_hover_note()
	_build_detail_strip()
	_build_margin_actions()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER, true)
	draw_rect(Rect2(0, 0, size.x, 91), Color("#F4EDDF"), true)
	draw_line(Vector2(38, 90), Vector2(size.x - 38, 90), Color(INK, 0.28), 1.0, true)
	_draw_paper_texture()
	_draw_campus_ground()
	_draw_roads()
	_draw_trees()
	_draw_central_landmark()
	_draw_route()
	_draw_hover_connector()
	draw_line(Vector2(38, 598), Vector2(size.x - 38, 598), Color(INK, 0.22), 1.0, true)


func _draw_paper_texture() -> void:
	for index in 18:
		var y := 99.0 + index * 28.0
		draw_line(Vector2(0, y), Vector2(size.x, y + 11.0), Color("#FFFFFF", 0.035), 1.0)
	for index in 13:
		var x := 18.0 + index * 103.0
		draw_line(Vector2(x, 92), Vector2(x - 34.0, 598), Color(INK, 0.025), 1.0)


func _draw_campus_ground() -> void:
	var campus := PackedVector2Array([
		Vector2(26, 152), Vector2(190, 105), Vector2(427, 101), Vector2(596, 132),
		Vector2(764, 102), Vector2(1039, 118), Vector2(1219, 190), Vector2(1235, 481),
		Vector2(1070, 574), Vector2(802, 585), Vector2(628, 552), Vector2(431, 582),
		Vector2(191, 569), Vector2(36, 510),
	])
	draw_colored_polygon(campus, LAWN)
	draw_polyline(PackedVector2Array([
		campus[0], campus[1], campus[2], campus[3], campus[4], campus[5], campus[6],
		campus[7], campus[8], campus[9], campus[10], campus[11], campus[12], campus[13], campus[0],
	]), Color(LAWN_DARK, 0.6), 2.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 300), Vector2(127, 277), Vector2(210, 331), Vector2(123, 376), Vector2(0, 349)
	]), Color("#7C936F"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(1035, 129), Vector2(1280, 159), Vector2(1280, 289), Vector2(1155, 300), Vector2(1105, 235)
	]), Color("#91A685"))


func _draw_roads() -> void:
	var road_paths := [
		PackedVector2Array([Vector2(0, 355), Vector2(173, 350), Vector2(360, 307), Vector2(575, 309), Vector2(782, 335), Vector2(1015, 335), Vector2(1280, 305)]),
		PackedVector2Array([Vector2(574, 91), Vector2(579, 182), Vector2(575, 309), Vector2(603, 464), Vector2(653, 598)]),
		PackedVector2Array([Vector2(208, 91), Vector2(217, 171), Vector2(251, 275), Vector2(360, 307)]),
		PackedVector2Array([Vector2(1015, 335), Vector2(1054, 433), Vector2(1162, 510), Vector2(1280, 526)]),
	]
	for path in road_paths:
		draw_polyline(path, Color(ROAD_EDGE, 0.62), 22.0, true)
		draw_polyline(path, ROAD, 17.0, true)
		draw_polyline(path, Color(PAPER_LIGHT, 0.6), 1.2, true)
	for x in [365.0, 445.0, 525.0, 625.0, 725.0, 825.0, 925.0]:
		draw_line(Vector2(x, 305), Vector2(x + 24, 309), Color(ROAD_EDGE, 0.48), 1.0)


func _draw_trees() -> void:
	var tree_positions := [
		Vector2(45, 145), Vector2(88, 128), Vector2(282, 124), Vector2(291, 289),
		Vector2(650, 120), Vector2(958, 132), Vector2(1110, 175), Vector2(1196, 229),
		Vector2(1115, 389), Vector2(1128, 468), Vector2(768, 548), Vector2(690, 550),
		Vector2(335, 552), Vector2(42, 551), Vector2(315, 363), Vector2(1062, 317),
	]
	for position in tree_positions:
		draw_circle(position + Vector2(3, 5), 11, Color("#384A3A2C"))
		draw_circle(position, 10, Color("#5D7859"))
		draw_circle(position + Vector2(-5, -4), 6, Color("#809777"))
		draw_line(position + Vector2(0, 8), position + Vector2(0, 17), Color("#6F5B43"), 2.0)


func _draw_central_landmark() -> void:
	var center := Vector2(576, 309)
	draw_circle(center, 39, Color(PAPER_LIGHT, 0.82))
	draw_arc(center, 39, 0, TAU, 48, Color(ROAD_EDGE, 0.62), 2.0, true)
	draw_circle(center, 19, Color("#C8B37F"))
	draw_arc(center, 19, 0, TAU, 32, Color(GOLD, 0.72), 2.0, true)
	draw_line(center + Vector2(-10, 0), center + Vector2(10, 0), Color(PAPER_LIGHT, 0.8), 2.0)
	draw_line(center + Vector2(0, -10), center + Vector2(0, 10), Color(PAPER_LIGHT, 0.8), 2.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-27, 60), "中心广场", HORIZONTAL_ALIGNMENT_CENTER, 54, 12, Color(INK, 0.64))


func _draw_route() -> void:
	if selected_location_id.is_empty() or not HOTSPOT_LAYOUT.has(selected_location_id):
		return
	var destination := _hotspot_center(selected_location_id)
	var origin_id := str(data.get("current_location_id", ""))
	var origin := _hotspot_center(origin_id) if HOTSPOT_LAYOUT.has(origin_id) else Vector2(576, 309)
	if origin.distance_to(destination) < 4.0:
		origin = Vector2(576, 309)
	var bend := Vector2(origin.x * 0.46 + destination.x * 0.54, 309)
	var route := PackedVector2Array([origin, bend, destination])
	draw_polyline(route, Color(PAPER_LIGHT, 0.9), 8.0, true)
	draw_polyline(route, SDU_RED, 3.0, true)
	var total_steps := 12
	for index in range(1, total_steps):
		var t := float(index) / float(total_steps)
		var point := _quadratic_route_point(origin, bend, destination, t)
		draw_circle(point, 2.4, PAPER_LIGHT)
	draw_circle(origin, 6, PAPER_LIGHT)
	draw_arc(origin, 6, 0, TAU, 18, SDU_RED, 2.0)


func _build_header() -> void:
	var title := _make_label("惊魂期末周", 27, INK)
	title.position = Vector2(42, 17)
	title.size = Vector2(230, 36)
	add_child(title)
	var campus := _make_label("山东大学中心校区 · 校园行动手册", 13, MUTED)
	campus.position = Vector2(44, 52)
	campus.size = Vector2(300, 22)
	add_child(campus)

	var meta := _make_label("%s  /  %s  /  %s难度" % [
		str(data.get("player_name", "同学")),
		str(data.get("clock_text", "第 1 天 · 早晨")),
		str(data.get("difficulty_name", "中等")),
	], 14, INK)
	meta.position = Vector2(345, 20)
	meta.size = Vector2(370, 27)
	add_child(meta)

	var stats: Dictionary = data.get("stats", {})
	var stat_items := [
		["学习", int(stats.get("study", 0)), Color("#3C806D")],
		["项目", int(stats.get("project", 0)), Color("#477FA8")],
		["精力", int(stats.get("energy", 0)), GOLD],
		["压力", int(stats.get("stress", 0)), Color("#B84850")],
	]
	var x := 347.0
	for item in stat_items:
		var dot := ColorRect.new()
		dot.color = item[2]
		dot.position = Vector2(x, 56)
		dot.size = Vector2(6, 6)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dot)
		var stat := _make_label("%s %d" % [item[0], item[1]], 12, MUTED)
		stat.position = Vector2(x + 11, 48)
		stat.size = Vector2(76, 24)
		add_child(stat)
		x += 86.0

	var map_title := _make_label("今天去哪里？", 22, INK)
	map_title.position = Vector2(42, 105)
	map_title.size = Vector2(210, 32)
	add_child(map_title)
	var instruction := _make_label("点选建筑查看路线；确认后就从这里出发。", 12, MUTED)
	instruction.position = Vector2(44, 136)
	instruction.size = Vector2(380, 22)
	add_child(instruction)


func _build_deadline_notes() -> void:
	var tasks: Dictionary = data.get("tasks", {})
	var exam_note := _make_deadline_note(
		"核心课考试",
		"第 5 天上午",
		int(tasks.get("exam", 0)),
		Color("#E8D9AC")
	)
	exam_note.position = Vector2(1031, 103)
	exam_note.rotation_degrees = -1.6
	add_child(exam_note)
	var project_note := _make_deadline_note(
		"AI 项目展示",
		"第 7 天下午",
		int(tasks.get("presentation", 0)),
		Color("#D8E0C7")
	)
	project_note.position = Vector2(1126, 174)
	project_note.rotation_degrees = 1.2
	add_child(project_note)


func _make_deadline_note(title_text: String, deadline: String, value: int, color: Color) -> PanelContainer:
	var note := PanelContainer.new()
	note.custom_minimum_size = Vector2(134, 78)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.shadow_color = Color("#2A322C35")
	style.shadow_size = 5
	style.content_margin_left = 11
	style.content_margin_right = 11
	style.content_margin_top = 9
	style.content_margin_bottom = 8
	note.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	note.add_child(box)
	box.add_child(_make_label(title_text, 14, INK))
	box.add_child(_make_label("%s · %d%%" % [deadline, value], 11, MUTED))
	var progress := ProgressBar.new()
	progress.value = value
	progress.show_percentage = false
	progress.custom_minimum_size.y = 4
	var background := StyleBoxFlat.new()
	background.bg_color = Color(INK, 0.14)
	background.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = SDU_RED
	fill.set_corner_radius_all(2)
	progress.add_theme_stylebox_override("background", background)
	progress.add_theme_stylebox_override("fill", fill)
	box.add_child(progress)
	return note


func _build_hotspots() -> void:
	var current_id := str(data.get("current_location_id", ""))
	for location_value in data.get("locations", []):
		var location: Dictionary = location_value
		var id := str(location.get("id", ""))
		if not HOTSPOT_LAYOUT.has(id):
			continue
		_locations[id] = location
		var layout: Dictionary = HOTSPOT_LAYOUT[id]
		var hotspot = HotspotScript.new()
		hotspot.position = layout.position
		hotspot.size = layout.size
		hotspot.configure(location, id == current_id)
		hotspot.location_selected.connect(_select_location)
		hotspot.location_hovered.connect(_show_location_hover)
		add_child(hotspot)
		_hotspots[id] = hotspot


func _build_npc_markers() -> void:
	var relationships: Dictionary = data.get("relationships", {})
	for npc_value in data.get("npcs", []):
		var npc: Dictionary = npc_value
		var npc_id := str(npc.get("id", ""))
		var location_id := str(NPC_LOCATION.get(npc_id, ""))
		if not HOTSPOT_LAYOUT.has(location_id):
			continue
		var marker := Button.new()
		marker.name = "MapNPC_%s" % npc_id
		marker.text = "%s  %s" % [str(npc.get("avatar", "·")), str(npc.get("name", "同伴"))]
		marker.position = HOTSPOT_LAYOUT[location_id].position + NPC_OFFSET.get(npc_id, Vector2(110, 8))
		marker.size = Vector2(105, 28)
		marker.add_theme_font_size_override("font_size", 11)
		marker.add_theme_color_override("font_color", INK)
		marker.mouse_default_cursor_shape = Control.CURSOR_HELP
		marker.tooltip_text = "%s · 关系 %d\n%s" % [
			str(npc.get("role", "同伴")),
			int(relationships.get(npc_id, 40)),
			_relation_state(int(relationships.get(npc_id, 40))),
		]
		var accent := Color(str(npc.get("color", "#78877E")))
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(PAPER_LIGHT, 0.96 if state == "normal" else 1.0)
			style.border_color = Color(accent, 0.65 if state == "normal" else 0.95)
			style.set_border_width_all(1)
			style.set_corner_radius_all(14)
			style.shadow_color = Color("#28332C28")
			style.shadow_size = 3 if state == "normal" else 5
			marker.add_theme_stylebox_override(state, style)
		add_child(marker)


func _build_hover_note() -> void:
	_hover_note = PanelContainer.new()
	_hover_note.name = "MapHoverNote"
	_hover_note.position = Vector2(548, 106)
	_hover_note.size = Vector2(274, 88)
	_hover_note.visible = false
	_hover_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_note.z_index = 20
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PAPER_LIGHT, 0.98)
	style.border_color = Color(INK, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 9
	style.shadow_color = Color("#2A312B30")
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 4)
	_hover_note.add_theme_stylebox_override("panel", style)
	add_child(_hover_note)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_hover_note.add_child(row)
	_hover_note_rule = ColorRect.new()
	_hover_note_rule.custom_minimum_size = Vector2(4, 58)
	_hover_note_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_hover_note_rule)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 1)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var eyebrow := _make_label("鼠标所指 · 可以在这里", 10, MUTED)
	copy.add_child(eyebrow)
	_hover_note_name = _make_label("校园地点", 16, INK)
	_hover_note_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_hover_note_name)
	_hover_note_actions = _make_label("查看可进行的活动", 12, MUTED)
	_hover_note_actions.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_hover_note_actions)


func _show_location_hover(location_id: String, active: bool) -> void:
	if not active:
		if _hovered_location_id == location_id:
			_hovered_location_id = ""
			_hover_note.visible = false
			queue_redraw()
		return
	if not _locations.has(location_id):
		return
	_hovered_location_id = location_id
	var location: Dictionary = _locations[location_id]
	var accent := Color(str(location.get("color", "#627D6B")))
	_hover_note_rule.color = accent
	_hover_note_name.text = str(location.get("name", "校园地点"))
	var action_names: Array[String] = []
	for action_value in location.get("actions", []):
		var action: Dictionary = action_value
		action_names.append(str(action.get("label", "安排一个时段")))
	_hover_note_actions.text = "可做  %s" % "  /  ".join(action_names)
	_hover_note.position = HOVER_NOTE_LAYOUT.get(location_id, Vector2(548, 106))
	_hover_note.visible = true
	queue_redraw()


func _draw_hover_connector() -> void:
	if _hovered_location_id.is_empty() or not HOTSPOT_LAYOUT.has(_hovered_location_id) or _hover_note == null or not _hover_note.visible:
		return
	var start := _hotspot_center(_hovered_location_id)
	var note_rect := Rect2(_hover_note.position, _hover_note.size)
	var end := note_rect.get_center()
	if end.x > start.x:
		end.x = note_rect.position.x
	else:
		end.x = note_rect.end.x
	end.y = clampf(start.y, note_rect.position.y + 14.0, note_rect.end.y - 14.0)
	var bend := Vector2((start.x + end.x) * 0.5, start.y)
	draw_polyline(PackedVector2Array([start, bend, end]), Color(PAPER_LIGHT, 0.92), 5.0, true)
	draw_polyline(PackedVector2Array([start, bend, end]), Color(SDU_RED, 0.72), 1.5, true)
	draw_circle(start, 4.0, SDU_RED)


func _build_detail_strip() -> void:
	var strip := PanelContainer.new()
	strip.name = "MapLocationDetail"
	strip.position = Vector2(38, 610)
	strip.size = Vector2(1204, 94)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PAPER_LIGHT, 0.96)
	style.border_color = Color(INK, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 24
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 12
	strip.add_theme_stylebox_override("panel", style)
	add_child(strip)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	strip.add_child(row)
	_detail_rule = ColorRect.new()
	_detail_rule.color = Color(INK, 0.26)
	_detail_rule.custom_minimum_size = Vector2(4, 62)
	_detail_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_detail_rule)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	row.add_child(copy)
	_detail_name = _make_label("在地图上选一栋楼", 20, INK)
	copy.add_child(_detail_name)
	_detail_subtitle = _make_label("建筑不是菜单卡片，而是你下一段校园生活的入口。", 13, MUTED)
	copy.add_child(_detail_subtitle)
	_detail_description = _make_label("每次行动消耗 1 个时段；路线确认后会进入校园路途。", 12, Color(MUTED, 0.84))
	_detail_description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_detail_description)
	_travel_button = Button.new()
	_travel_button.name = "TravelSelected"
	_travel_button.text = "选择建筑"
	_travel_button.disabled = true
	_travel_button.custom_minimum_size = Vector2(146, 54)
	_travel_button.add_theme_font_size_override("font_size", 16)
	_travel_button.add_theme_color_override("font_color", PAPER_LIGHT)
	_travel_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_travel_button.set_meta("audio_cue", &"location_enter")
	_style_action_button(_travel_button)
	_travel_button.pressed.connect(_confirm_travel)
	row.add_child(_travel_button)

	_route_caption = _make_label("本页只负责选择去向；行动结果仍由原有事件系统结算。", 11, Color(MUTED, 0.72))
	_route_caption.position = Vector2(826, 578)
	_route_caption.size = Vector2(404, 22)
	_route_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_route_caption)


func _build_margin_actions() -> void:
	var advice := Button.new()
	advice.name = "MapAdviceButton"
	advice.text = "AI 学伴  ·  查看建议"
	advice.position = Vector2(1050, 539)
	advice.size = Vector2(184, 42)
	advice.add_theme_font_size_override("font_size", 13)
	advice.add_theme_color_override("font_color", INK)
	advice.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	advice.set_meta("audio_cue", &"choice")
	var advice_style := StyleBoxFlat.new()
	advice_style.bg_color = Color(PAPER_LIGHT, 0.78)
	advice_style.border_color = Color(INK, 0.32)
	advice_style.set_border_width_all(1)
	advice_style.set_corner_radius_all(21)
	advice.add_theme_stylebox_override("normal", advice_style)
	var advice_hover := advice_style.duplicate() as StyleBoxFlat
	advice_hover.bg_color = PAPER_LIGHT
	advice_hover.border_color = SDU_RED
	advice.add_theme_stylebox_override("hover", advice_hover)
	advice.add_theme_stylebox_override("pressed", advice_hover)
	advice.add_theme_stylebox_override("focus", advice_hover)
	var advice_action: Callable = data.get("advice_action", Callable())
	if advice_action.is_valid():
		advice.pressed.connect(advice_action)
	add_child(advice)

	var pause := Button.new()
	pause.name = "MapPauseButton"
	pause.text = "暂停  ESC"
	pause.position = Vector2(1146, 24)
	pause.size = Vector2(92, 38)
	pause.add_theme_font_size_override("font_size", 13)
	pause.add_theme_color_override("font_color", INK)
	pause.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		var pause_style := StyleBoxFlat.new()
		pause_style.bg_color = Color(PAPER_DARK, 0.2 if state == "normal" else 0.58)
		pause_style.set_corner_radius_all(18)
		pause.add_theme_stylebox_override(state, pause_style)
	var pause_action: Callable = data.get("pause_action", Callable())
	if pause_action.is_valid():
		pause.pressed.connect(pause_action)
	add_child(pause)


func _select_location(location_id: String) -> void:
	if not _locations.has(location_id):
		return
	selected_location_id = location_id
	for id in _hotspots:
		_hotspots[id].set_selected(str(id) == location_id)
	var location: Dictionary = _locations[location_id]
	var accent := Color(str(location.get("color", "#627D6B")))
	_detail_rule.color = accent
	_detail_name.text = str(location.get("name", "校园地点"))
	_detail_subtitle.text = str(location.get("subtitle", ""))
	_detail_description.text = str(location.get("description", ""))
	_travel_button.disabled = false
	_travel_button.text = "前往这里  →"
	_route_caption.text = "路线已标出  ·  消耗 1 个时段"
	queue_redraw()


func _confirm_travel() -> void:
	if selected_location_id.is_empty():
		return
	var travel_action: Callable = data.get("travel_action", Callable())
	if travel_action.is_valid():
		travel_action.call(selected_location_id)


func _style_action_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(SDU_RED, 0.42 if state == "disabled" else (0.86 if state == "normal" else 1.0))
		style.border_color = Color("#6F181D", 0.62)
		style.set_border_width_all(1)
		style.set_corner_radius_all(27)
		style.shadow_color = Color("#4D15192A")
		style.shadow_size = 4 if state == "normal" else 7
		button.add_theme_stylebox_override(state, style)


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _relation_state(value: int) -> String:
	if value >= 70:
		return "关键时刻愿意主动支援"
	if value >= 50:
		return "关系稳定，能够互相搭把手"
	if value >= 30:
		return "普通同学关系"
	return "最近有些疏远"


func _hotspot_center(location_id: String) -> Vector2:
	var layout: Dictionary = HOTSPOT_LAYOUT.get(location_id, {})
	if layout.is_empty():
		return Vector2(576, 309)
	return layout.position + layout.size * 0.5


func _quadratic_route_point(start: Vector2, bend: Vector2, finish: Vector2, t: float) -> Vector2:
	var first := start.lerp(bend, t)
	var second := bend.lerp(finish, t)
	return first.lerp(second, t)
