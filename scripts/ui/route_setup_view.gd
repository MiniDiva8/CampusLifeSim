extends Control
class_name RouteSetupView

const RouteFileTabScript = preload("res://scripts/ui/route_file_tab.gd")
const RouteRulesScript = preload("res://scripts/core/route_rules.gd")
const PAPER := Color("#E9E0CD")
const PAPER_LIGHT := Color("#F7F1E5")
const PAPER_DARK := Color("#D0C2A8")
const INK := Color("#29332E")
const MUTED := Color("#6C756E")
const SDU_RED := Color("#9E2A2F")
const GOLD := Color("#A87932")

var data: Dictionary = {}
var name_input: LineEdit
var trait_group := ButtonGroup.new()
var difficulty_group := ButtonGroup.new()
var selected_route_id := RouteRulesScript.DEFAULT_ROUTE
var selected_difficulty_id := DifficultyRules.DEFAULT_NEW_GAME
var _route_tabs: Dictionary = {}
var _route_title: Label
var _route_subtitle: Label
var _detail_values: Dictionary = {}
var _difficulty_detail: Label


func configure(view_data: Dictionary) -> void:
	data = view_data
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_header()
	_build_identity()
	_build_route_tabs()
	_build_route_details()
	_build_difficulty_scale()
	_build_confirm()
	_select_route(RouteRulesScript.DEFAULT_ROUTE)
	_select_difficulty(DifficultyRules.DEFAULT_NEW_GAME)
	queue_redraw()
	if not bool(data.get("reduced_motion", false)):
		modulate.a = 0.0
		position.y = 7.0
		var entrance := create_tween().set_parallel(true)
		entrance.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		entrance.tween_property(self, "position:y", 0.0, 0.24)
		entrance.tween_property(self, "modulate:a", 1.0, 0.20)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#C7B99F"), true)
	draw_rect(Rect2(24, 20, size.x - 48, size.y - 40), Color("#4B3C292A"), true)
	draw_rect(Rect2(31, 14, 609, 687), PAPER, true)
	draw_rect(Rect2(640, 14, 609, 687), PAPER_LIGHT, true)
	_draw_paper_texture()
	_draw_spine()
	_draw_map_watermark()
	_draw_section_rules()
	_draw_difficulty_track()


func _draw_paper_texture() -> void:
	for index in 23:
		var y := 28.0 + float(index) * 29.0
		draw_line(Vector2(32, y), Vector2(1248, y + 5.0), Color("#FFFFFF", 0.043), 1.0)
	for index in 13:
		var x := 50.0 + float(index) * 94.0
		draw_line(Vector2(x, 15), Vector2(x - 40.0, 700), Color(INK, 0.020), 1.0)
	draw_arc(Vector2(1168, 645), 105, 2.95, 4.65, 36, Color("#75654E18"), 2.0)


func _draw_spine() -> void:
	draw_rect(Rect2(632, 14, 16, 687), Color("#6A5B4620"), true)
	draw_line(Vector2(638, 18), Vector2(638, 697), Color("#FFFFFF6A"), 1.0)
	draw_line(Vector2(646, 18), Vector2(646, 697), Color("#74665044"), 1.0)


func _draw_map_watermark() -> void:
	var color := Color("#73836F17")
	var roads := [
		PackedVector2Array([Vector2(681, 113), Vector2(794, 153), Vector2(889, 132), Vector2(1028, 174), Vector2(1194, 151)]),
		PackedVector2Array([Vector2(854, 96), Vector2(879, 213), Vector2(846, 327), Vector2(913, 456), Vector2(888, 585)]),
		PackedVector2Array([Vector2(691, 386), Vector2(825, 350), Vector2(964, 377), Vector2(1103, 337), Vector2(1221, 365)]),
	]
	for road in roads:
		draw_polyline(road, color, 10.0, true)
		draw_polyline(road, Color("#FFFFFF18"), 2.0, true)
	for point in [Vector2(757, 180), Vector2(964, 153), Vector2(1116, 221), Vector2(766, 424), Vector2(1045, 429)]:
		draw_rect(Rect2(point, Vector2(82, 49)), Color("#71816D0F"), true)
		draw_rect(Rect2(point, Vector2(82, 49)), color, false, 1.0)


func _draw_section_rules() -> void:
	draw_line(Vector2(62, 94), Vector2(610, 94), Color(SDU_RED, 0.56), 2.0)
	draw_line(Vector2(672, 94), Vector2(1218, 94), Color(SDU_RED, 0.56), 2.0)
	draw_line(Vector2(67, 237), Vector2(601, 237), Color(INK, 0.22), 1.0)
	draw_line(Vector2(670, 191), Vector2(1210, 191), Color(INK, 0.22), 1.0)
	draw_rect(Rect2(1102, 41, 112, 34), Color.TRANSPARENT, false, 2.0, false)
	draw_string(ThemeDB.fallback_font, Vector2(1115, 64), "第 0 日 / 登记", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, SDU_RED)


func _draw_difficulty_track() -> void:
	draw_line(Vector2(112, 612), Vector2(509, 612), Color(INK, 0.30), 2.0)
	var positions := {"easy": 112.0, "medium": 310.0, "hard": 509.0}
	for difficulty_id in DifficultyRules.ORDER:
		var center := Vector2(float(positions[difficulty_id]), 612)
		var selected: bool = selected_difficulty_id == str(difficulty_id)
		var color := Color(str(DifficultyRules.get_config(difficulty_id).color))
		draw_circle(center, 10 if selected else 7, PAPER_LIGHT)
		draw_arc(center, 10 if selected else 7, 0, TAU, 24, color, 3.0 if selected else 2.0, true)
		if selected:
			draw_circle(center, 4, color)


func _build_header() -> void:
	var back := Button.new()
	back.name = "SetupBack"
	back.text = "←  返回档案封面"
	back.position = Vector2(58, 37)
	back.size = Vector2(185, 42)
	back.focus_mode = Control.FOCUS_ALL
	back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back.add_theme_font_size_override("font_size", 15)
	back.add_theme_color_override("font_color", INK)
	back.add_theme_color_override("font_hover_color", SDU_RED)
	for state in ["normal", "pressed", "disabled"]:
		back.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#FFFDF487")
	hover.border_color = Color(SDU_RED, 0.55)
	hover.border_width_bottom = 1
	back.add_theme_stylebox_override("hover", hover)
	back.add_theme_stylebox_override("focus", hover)
	back.set_meta("audio_cue", &"back")
	var back_action: Callable = data.get("back_action", Callable())
	if back_action.is_valid():
		back.pressed.connect(back_action)
	add_child(back)

	var archive_meta := _make_label("期末周路线登记  /  人工智能学院", 13, MUTED)
	archive_meta.position = Vector2(287, 43)
	archive_meta.size = Vector2(310, 28)
	archive_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(archive_meta)

	var right_meta := _make_label("ROUTE DOSSIER / 07 DAYS", 13, SDU_RED)
	right_meta.position = Vector2(675, 43)
	right_meta.size = Vector2(330, 28)
	add_child(right_meta)


func _build_identity() -> void:
	var question := _make_label("你准备以什么方式\n度过这七天？", 34, INK)
	question.position = Vector2(67, 112)
	question.size = Vector2(520, 84)
	add_child(question)

	var prompt := _make_label("记录人", 12, MUTED)
	prompt.position = Vector2(69, 202)
	prompt.size = Vector2(62, 25)
	add_child(prompt)
	name_input = LineEdit.new()
	name_input.name = "PlayerName"
	name_input.text = "小山"
	name_input.placeholder_text = "输入名字（默认：小山）"
	name_input.max_length = 12
	name_input.position = Vector2(137, 196)
	name_input.size = Vector2(244, 34)
	name_input.add_theme_font_size_override("font_size", 17)
	name_input.add_theme_color_override("font_color", INK)
	name_input.add_theme_color_override("caret_color", SDU_RED)
	name_input.add_theme_color_override("font_placeholder_color", Color(MUTED, 0.65))
	for state in ["normal", "read_only"]:
		name_input.add_theme_stylebox_override(state, _underline_style(Color(INK, 0.32)))
	name_input.add_theme_stylebox_override("focus", _underline_style(SDU_RED))
	add_child(name_input)


func _build_route_tabs() -> void:
	var positions := {
		"study": Vector2(71, 258),
		"project": Vector2(98, 358),
		"social": Vector2(71, 458),
	}
	for route in data.get("routes", RouteRulesScript.get_all()):
		var route_data: Dictionary = route
		var route_id := str(route_data.get("id", RouteRulesScript.DEFAULT_ROUTE))
		var tab = RouteFileTabScript.new()
		tab.position = positions.get(route_id, Vector2(71, 258))
		tab.size = Vector2(500, 91)
		tab.configure(route_data, trait_group)
		tab.route_selected.connect(_select_route)
		add_child(tab)
		_route_tabs[route_id] = tab


func _build_route_details() -> void:
	var index_label := _make_label("策略路线", 13, SDU_RED)
	index_label.position = Vector2(676, 111)
	index_label.size = Vector2(120, 26)
	add_child(index_label)
	_route_title = _make_label("稳扎稳打", 37, INK)
	_route_title.name = "RouteTitle"
	_route_title.position = Vector2(673, 136)
	_route_title.size = Vector2(340, 49)
	add_child(_route_title)
	_route_subtitle = _make_label("", 15, MUTED)
	_route_subtitle.position = Vector2(995, 151)
	_route_subtitle.size = Vector2(215, 28)
	_route_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_route_subtitle)

	var fields := [
		["core", "核心风格", 211],
		["advantage", "初始优势", 274],
		["shortcoming", "潜在短板", 337],
		["recommendation", "推荐行动", 400],
		["tendency", "事件倾向", 475],
	]
	for field in fields:
		var marker := ColorRect.new()
		marker.color = SDU_RED
		marker.position = Vector2(676, float(field[2]) + 5)
		marker.size = Vector2(4, 40 if field[0] != "tendency" else 54)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(marker)
		var label := _make_label(str(field[1]), 12, MUTED)
		label.position = Vector2(694, float(field[2]))
		label.size = Vector2(100, 23)
		add_child(label)
		var value := _make_label("", 15, INK)
		value.name = "Route_%s" % str(field[0]).capitalize()
		value.position = Vector2(795, float(field[2]) - 2)
		value.size = Vector2(404, 55 if field[0] != "tendency" else 69)
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		value.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		add_child(value)
		_detail_values[field[0]] = value


func _build_difficulty_scale() -> void:
	var title := _make_label("期末强度", 14, INK)
	title.position = Vector2(68, 573)
	title.size = Vector2(120, 26)
	add_child(title)
	var positions := {"easy": 62.0, "medium": 260.0, "hard": 459.0}
	for difficulty_id in DifficultyRules.ORDER:
		var config: Dictionary = DifficultyRules.get_config(difficulty_id)
		var button := Button.new()
		button.name = "Difficulty_%s" % difficulty_id
		button.text = "%s\n%s" % [str(config.name), str(config.subtitle)]
		button.position = Vector2(float(positions[difficulty_id]), 620)
		button.size = Vector2(100, 58)
		button.toggle_mode = true
		button.button_group = difficulty_group
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 12)
		button.add_theme_color_override("font_color", MUTED)
		button.add_theme_color_override("font_hover_color", INK)
		button.add_theme_color_override("font_pressed_color", Color(str(config.color)))
		button.add_theme_color_override("font_focus_color", Color(str(config.color)))
		button.set_meta("difficulty_id", difficulty_id)
		button.set_meta("audio_cue", &"select")
		_style_difficulty_button(button)
		button.pressed.connect(_select_difficulty.bind(difficulty_id))
		add_child(button)

	_difficulty_detail = _make_label("", 12, MUTED)
	_difficulty_detail.name = "DifficultyDetail"
	_difficulty_detail.position = Vector2(674, 565)
	_difficulty_detail.size = Vector2(535, 47)
	_difficulty_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_difficulty_detail)


func _build_confirm() -> void:
	var button := Button.new()
	button.name = "RouteConfirm"
	button.text = "登记路线并启封档案    →"
	button.position = Vector2(675, 622)
	button.size = Vector2(533, 58)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", PAPER_LIGHT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _confirm_style(SDU_RED, 3))
	button.add_theme_stylebox_override("hover", _confirm_style(SDU_RED.lightened(0.10), 7))
	button.add_theme_stylebox_override("pressed", _confirm_style(SDU_RED.darkened(0.08), 2))
	button.add_theme_stylebox_override("focus", _confirm_style(SDU_RED.lightened(0.10), 7))
	button.set_meta("audio_cue", &"confirm")
	button.pressed.connect(_confirm)
	add_child(button)


func _select_route(route_id: String) -> void:
	selected_route_id = RouteRulesScript.normalize(route_id)
	for id in _route_tabs:
		var tab = _route_tabs[id]
		tab.set_selected(str(id) == selected_route_id)
	var config := RouteRulesScript.get_config(selected_route_id)
	_route_title.text = str(config.name)
	_route_subtitle.text = str(config.subtitle)
	for field_id in _detail_values:
		var value_label: Label = _detail_values[field_id]
		value_label.text = str(config.get(field_id, ""))
	queue_redraw()


func _select_difficulty(difficulty_id: String) -> void:
	selected_difficulty_id = DifficultyRules.normalize(difficulty_id)
	for button in difficulty_group.get_buttons():
		var id := str(button.get_meta("difficulty_id", ""))
		button.button_pressed = id == selected_difficulty_id
	var config := DifficultyRules.get_config(selected_difficulty_id)
	_difficulty_detail.text = "%s · %s  %s" % [config.name, config.subtitle, config.description]
	queue_redraw()


func _confirm() -> void:
	var action: Callable = data.get("confirm_action", Callable())
	if action.is_valid():
		action.call(name_input.text, selected_route_id, selected_difficulty_id)


func _style_difficulty_button(button: Button) -> void:
	var normal := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#FFFDF476")
	hover.border_color = Color(INK, 0.18)
	hover.border_width_bottom = 1
	var pressed := hover.duplicate()
	pressed.bg_color = Color("#E1D5BFA0")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)


func _underline_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = color
	style.border_width_bottom = 2
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_bottom = 5
	return style


func _confirm_style(color: Color, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.darkened(0.24)
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.shadow_color = Color("#4D241C32")
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(3, 4)
	return style


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
