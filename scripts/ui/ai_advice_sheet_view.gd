class_name AIAdviceSheetView
extends Control

const StatusRibbonScript = preload("res://scripts/ui/status_ribbon.gd")
const PAPER := Color("#EAE2D2")
const PAPER_LIGHT := Color("#F7F1E5")
const INK := Color("#24342E")
const MUTED := Color("#66766E")
const RULE := Color("#83908755")
const BLUE := Color("#477FA8")
const BLUE_LIGHT := Color("#D8E5EA")
const SDU_RED := Color("#9E2A2F")
const CORAL_PAPER := Color("#E9D2CC")

var data: Dictionary = {}


func configure(view_data: Dictionary) -> void:
	data = view_data
	for child in get_children():
		child.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_header()
	_build_status()
	_build_recommendation()
	_build_risk_note()
	_build_footer()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER, true)
	for index in 17:
		var y := 92.0 + index * 34.0
		draw_line(Vector2(0, y), Vector2(size.x, y + 8.0), Color("#FFFFFF", 0.035), 1.0)
	for index in 12:
		var x := 30.0 + index * 112.0
		draw_line(Vector2(x, 0), Vector2(x - 26.0, size.y), Color(INK, 0.022), 1.0)
	draw_line(Vector2(42, 86), Vector2(1238, 86), Color(INK, 0.24), 1.0, true)
	draw_line(Vector2(794, 122), Vector2(794, 598), Color(INK, 0.18), 1.0, true)
	draw_line(Vector2(55, 654), Vector2(1225, 654), Color(INK, 0.22), 1.0, true)


func _build_header() -> void:
	var tab := PanelContainer.new()
	tab.position = Vector2(42, 19)
	tab.size = Vector2(184, 46)
	tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tab_style := StyleBoxFlat.new()
	tab_style.bg_color = BLUE
	tab_style.set_corner_radius_all(3)
	tab.add_theme_stylebox_override("panel", tab_style)
	var tab_text := _label("AI 学伴 · 核验单", 16, PAPER_LIGHT)
	tab_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tab.add_child(tab_text)
	add_child(tab)

	var heading := _label("建议只是一张参考纸", 22, INK)
	heading.position = Vector2(246, 22)
	heading.size = Vector2(330, 35)
	add_child(heading)
	var meta := _label("离线规则生成  /  不联网  /  决定权仍在玩家", 12, MUTED)
	meta.position = Vector2(246, 51)
	meta.size = Vector2(410, 24)
	add_child(meta)

	var time := _label(str(data.get("time", "期末周")), 13, INK)
	time.position = Vector2(930, 28)
	time.size = Vector2(292, 28)
	time.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(time)


func _build_status() -> void:
	var section := _label("01  /  AI 当前看到的状态", 13, BLUE)
	section.position = Vector2(55, 110)
	section.size = Vector2(310, 25)
	add_child(section)
	var status_ribbon = StatusRibbonScript.new()
	status_ribbon.name = "AIStatusRibbon"
	status_ribbon.position = Vector2(55, 140)
	status_ribbon.configure(data.get("stats", {}), true, 172.0, 52.0)
	add_child(status_ribbon)

	var tasks: Dictionary = data.get("tasks", {})
	var deadline := _label(
		"截止任务：考试准备 %d%%  ·  项目展示 %d%%  ·  平均关系 %d" % [
			int(tasks.get("exam", 0)),
			int(tasks.get("presentation", 0)),
			int(data.get("relationship_average", 0)),
		],
		13,
		MUTED
	)
	deadline.position = Vector2(57, 200)
	deadline.size = Vector2(690, 26)
	add_child(deadline)


func _build_recommendation() -> void:
	var advice: Dictionary = data.get("advice", {})
	var section := _label("02  /  建议行动", 13, BLUE)
	section.position = Vector2(55, 244)
	section.size = Vector2(250, 25)
	add_child(section)
	var marker := ColorRect.new()
	marker.color = BLUE
	marker.position = Vector2(55, 282)
	marker.size = Vector2(5, 128)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marker)
	var title := _label(str(advice.get("title", "保留一点余量")), 34, INK)
	title.name = "AIAdviceTitle"
	title.position = Vector2(78, 276)
	title.size = Vector2(665, 54)
	add_child(title)
	var message := _label(str(advice.get("message", "")), 19, INK)
	message.name = "AIAdviceMessage"
	message.position = Vector2(78, 337)
	message.size = Vector2(665, 105)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(message)

	var basis_section := _label("03  /  判断依据", 13, BLUE)
	basis_section.position = Vector2(55, 470)
	basis_section.size = Vector2(250, 24)
	add_child(basis_section)
	var basis := _label(str(data.get("basis", "AI 只读取当前数值与截止时间，没有完整理解你的长期安排。")), 15, MUTED)
	basis.position = Vector2(78, 505)
	basis.size = Vector2(665, 76)
	basis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(basis)


func _build_risk_note() -> void:
	var note := PanelContainer.new()
	note.name = "AIAdviceRiskNote"
	note.position = Vector2(830, 135)
	note.size = Vector2(382, 392)
	note.rotation_degrees = 0.8
	var style := StyleBoxFlat.new()
	style.bg_color = CORAL_PAPER
	style.border_color = Color(SDU_RED, 0.44)
	style.set_border_width_all(1)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 30
	style.content_margin_bottom = 26
	style.shadow_color = Color("#3F2D2930")
	style.shadow_size = 7
	style.shadow_offset = Vector2(4, 6)
	note.add_theme_stylebox_override("panel", style)
	add_child(note)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	note.add_child(box)
	var stamp := _label("需要你亲自核验", 13, SDU_RED)
	box.add_child(stamp)
	var heading := _label("AI 可能遗漏了什么？", 25, INK)
	box.add_child(heading)
	var risk := _label(str(data.get("risk", "建议可能不完整。")), 17, INK)
	risk.name = "AIAdviceRisk"
	risk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	risk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(risk)
	var reminder := _label("核验顺序\n1. 对照真实截止时间\n2. 检查精力与压力\n3. 问问同伴是否掌握了新信息", 14, MUTED)
	reminder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(reminder)


func _build_footer() -> void:
	var note := _label("AI 可以帮你整理线索，但不会替你承担选择的后果。", 13, MUTED)
	note.position = Vector2(55, 670)
	note.size = Vector2(660, 26)
	add_child(note)
	var button := Button.new()
	button.name = "AIAdviceReturn"
	button.text = "记为参考，返回校园地图  →"
	button.position = Vector2(836, 642)
	button.size = Vector2(376, 54)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", PAPER_LIGHT)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("audio_cue", &"choice")
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(BLUE, 0.90 if state == "normal" else 1.0)
		style.border_color = Color("#2C5F80")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.shadow_color = Color("#294A5A2A")
		style.shadow_size = 3 if state == "normal" else 6
		button.add_theme_stylebox_override(state, style)
	var return_action: Callable = data.get("return_action", Callable())
	if return_action.is_valid():
		button.pressed.connect(return_action)
	add_child(button)


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result
