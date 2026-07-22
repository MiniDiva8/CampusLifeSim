extends Control

const COLOR_INK := Color("#EAF4F1")
const COLOR_MUTED := Color("#A9BDBA")
const COLOR_DARK := Color("#10242C")
const COLOR_PANEL := Color("#17333BEE")
const COLOR_PANEL_LIGHT := Color("#214650F2")
const COLOR_ACCENT := Color("#F2B84B")
const COLOR_TEAL := Color("#55C2A3")
const COLOR_CORAL := Color("#EF7E73")
const COLOR_BLUE := Color("#66A9D2")

var repository := ContentRepository.new()
var event_engine: EventEngine
var save_service := SaveService.new()
var session: GameSession
var current_screen := "main_menu"
var settings_return_screen := "main_menu"
var settings := {}
var screen_layer: Control
var notice_text := ""


func _ready() -> void:
	set_process_unhandled_input(true)
	_build_theme()
	settings = save_service.load_settings()
	_apply_settings()
	if not repository.load_all():
		_show_fatal_error("内容数据校验失败\n\n" + "\n".join(repository.errors))
		return
	event_engine = EventEngine.new(repository)
	if _try_debug_preset():
		return
	show_main_menu()


func _try_debug_preset() -> bool:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--demo-preset="):
			var preset_id := argument.trim_prefix("--demo-preset=")
			session = GameSession.new()
			if DebugPresets.apply(session, preset_id):
				_present_current_state()
				return true
			push_warning("Unknown demo preset: %s" % preset_id)
	return false


func _build_theme() -> void:
	var game_theme := Theme.new()
	game_theme.default_font_size = 18
	theme = game_theme


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	match current_screen:
		"map", "location":
			show_pause_menu()
		"pause":
			show_map()
		"settings":
			_return_from_settings()
		"credits", "setup":
			show_main_menu()
		"main_menu":
			show_exit_confirmation()
		_:
			pass
	get_viewport().set_input_as_handled()


func _reset_screen(screen_name: String, backdrop_tint: Color = Color.WHITE) -> VBoxContainer:
	current_screen = screen_name
	for child in get_children():
		child.queue_free()
	screen_layer = Control.new()
	screen_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen_layer)

	var backdrop := CampusBackdrop.new()
	backdrop.tint = backdrop_tint
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(backdrop)

	var shade := ColorRect.new()
	shade.color = Color("#07161CB8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	screen_layer.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	return content


func show_main_menu() -> void:
	var root := _reset_screen("main_menu", Color("#6DAF9A"))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	var card := _make_panel(Color("#102D36F5"), 22, Color("#4B807C"))
	card.custom_minimum_size = Vector2(520, 0)
	row.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)

	var eyebrow := _make_label("CAMPUS CHOICE SIMULATION", 14, COLOR_TEAL)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	var title := _make_label("惊魂期末周", 52, COLOR_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := _make_label("七天、五个时段，以及没有标准答案的校园生活", 18, COLOR_MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(subtitle)
	box.add_child(_make_separator())

	var new_button := _make_button("开始新的期末周", show_setup, true)
	box.add_child(new_button)
	var continue_button := _make_button("继续上次进度", continue_game)
	continue_button.disabled = not save_service.has_save()
	box.add_child(continue_button)
	box.add_child(_make_button("设置", func(): show_settings("main_menu")))
	box.add_child(_make_button("制作与许可", show_credits))
	box.add_child(_make_button("退出游戏", show_exit_confirmation, false, true))

	var footnote := _make_label("离线运行 · 自动存档 · Godot 4.7.1", 13, Color("#789994"))
	footnote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(footnote)

	var bottom := Control.new()
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(bottom)


func show_setup() -> void:
	var root := _reset_screen("setup", Color("#7CA7B8"))
	root.add_child(_make_header("新生档案", "在期末周开始前，给自己一个名字和起点", show_main_menu))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(COLOR_PANEL, 20, Color("#3C6B70"))
	panel.custom_minimum_size = Vector2(940, 500)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_make_label("你的名字", 16, COLOR_MUTED))
	var name_input := LineEdit.new()
	name_input.name = "PlayerName"
	name_input.placeholder_text = "输入名字（默认：小山）"
	name_input.text = "小山"
	name_input.max_length = 12
	name_input.custom_minimum_size.y = 48
	_style_line_edit(name_input)
	box.add_child(name_input)
	box.add_child(_make_label("选择初始特长", 20, COLOR_INK))

	var trait_group := ButtonGroup.new()
	var trait_row := HBoxContainer.new()
	trait_row.add_theme_constant_override("separation", 12)
	box.add_child(trait_row)
	var traits := [
		{"id": "study", "title": "稳扎稳打", "desc": "学习进度 +10\n适合先建立知识优势"},
		{"id": "project", "title": "实干派", "desc": "项目进度 +10\n更快做出可展示成果"},
		{"id": "social", "title": "协调者", "desc": "四名 NPC 关系各 +5\n让同伴支持更早出现"},
	]
	for trait_entry in traits:
		var trait_button := Button.new()
		trait_button.name = "Trait_%s" % trait_entry.id
		trait_button.text = "%s\n\n%s" % [trait_entry.title, trait_entry.desc]
		trait_button.toggle_mode = true
		trait_button.button_group = trait_group
		trait_button.custom_minimum_size = Vector2(290, 150)
		trait_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		trait_button.add_theme_font_size_override("font_size", 17)
		_style_button(trait_button, Color("#21464F"), COLOR_TEAL)
		trait_button.set_meta("trait_id", trait_entry.id)
		trait_row.add_child(trait_button)
		if trait_entry.id == "study":
			trait_button.button_pressed = true

	var tip := _make_label("所有路线都能通向有意义的结局。特长只是起点，不是标准答案。", 15, COLOR_MUTED)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tip)
	var start_button := _make_button("进入期末周", func(): _start_from_setup(name_input, trait_group), true)
	box.add_child(start_button)


func _start_from_setup(name_input: LineEdit, trait_group: ButtonGroup) -> void:
	var trait_id := "study"
	var pressed := trait_group.get_pressed_button()
	if pressed != null:
		trait_id = str(pressed.get_meta("trait_id"))
	session = GameSession.new()
	session.reset(name_input.text, trait_id)
	var error := save_service.save_game(session)
	if error != OK:
		_show_fatal_error("无法创建自动存档：%s" % error_string(error))
		return
	_present_current_state()


func continue_game() -> void:
	session = save_service.load_game()
	if session == null:
		notice_text = "自动存档无法读取，已保留原文件。"
		show_main_menu()
		return
	if bool(session.flags.get("presentation_completed", false)) or session.clock.is_finished():
		show_ending()
	else:
		_present_current_state()


func _present_current_state() -> void:
	if session == null:
		show_main_menu()
		return
	if session.clock.is_finished() or bool(session.flags.get("presentation_completed", false)):
		show_ending()
		return
	var fixed_event := event_engine.get_fixed_event(session)
	if not fixed_event.is_empty():
		show_event(fixed_event)
	else:
		show_map()


func show_map() -> void:
	if session == null:
		show_main_menu()
		return
	var root := _reset_screen("map", Color("#79B69D"))
	root.add_child(_make_game_header())
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)

	columns.add_child(_build_status_panel())
	columns.add_child(_build_map_panel())
	columns.add_child(_build_schedule_panel())


func _make_game_header() -> Control:
	var panel := _make_panel(Color("#112C34F4"), 16, Color("#3E7372"))
	panel.custom_minimum_size.y = 72
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)
	title_box.add_child(_make_label("惊魂期末周", 24, COLOR_INK))
	title_box.add_child(_make_label("%s · %s" % [session.player_name, session.clock.get_display_text()], 14, COLOR_MUTED))
	var exam_badge := _make_badge("考试：第 5 天上午", COLOR_TEAL)
	row.add_child(exam_badge)
	var project_badge := _make_badge("展示：第 7 天下午", COLOR_ACCENT)
	row.add_child(project_badge)
	row.add_child(_make_button("暂停  Esc", show_pause_menu, false, false, 120))
	return panel


func _build_status_panel() -> Control:
	var panel := _make_panel(COLOR_PANEL, 16, Color("#365E64"))
	panel.custom_minimum_size.x = 250
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	box.add_child(_make_label("当前状态", 21, COLOR_INK))
	box.add_child(_make_stat_bar("学习进度", int(session.stats.study), COLOR_TEAL))
	box.add_child(_make_stat_bar("项目进度", int(session.stats.project), COLOR_BLUE))
	box.add_child(_make_stat_bar("精力", int(session.stats.energy), COLOR_ACCENT))
	box.add_child(_make_stat_bar("压力", int(session.stats.stress), COLOR_CORAL))
	box.add_child(_make_separator())
	box.add_child(_make_label("同伴关系", 17, COLOR_INK))
	for npc in repository.npcs:
		box.add_child(_make_relationship_row(npc))
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(space)
	var reminder := _make_label("提示：关系不是装饰。\n你投入的时间，可能在关键时刻变成帮助。", 13, COLOR_MUTED)
	reminder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(reminder)
	return panel


func _build_map_panel() -> Control:
	var panel := _make_panel(Color("#17343ACC"), 18, Color("#46776F"))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := _make_label("校园总览", 23, COLOR_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := _make_label("选择一个地点安排本时段。每次行动都会推进时间。", 14, COLOR_MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(grid)
	for location in repository.locations:
		grid.add_child(_make_location_button(location))
	return panel


func _build_schedule_panel() -> Control:
	var panel := _make_panel(COLOR_PANEL, 16, Color("#365E64"))
	panel.custom_minimum_size.x = 275
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_make_label("日程与任务", 21, COLOR_INK))
	box.add_child(_make_progress_card("算法考试", int(session.tasks.exam), "第 5 天上午"))
	box.add_child(_make_progress_card("项目展示", int(session.tasks.presentation), "第 7 天下午"))
	box.add_child(_make_separator())
	box.add_child(_make_label("AI 学伴", 18, COLOR_BLUE))
	var advice := AIAdvisor.new(repository.ai_advice).choose_advice(session)
	var advice_title := _make_label(str(advice.get("title", "今日建议")), 16, COLOR_INK)
	advice_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(advice_title)
	var advice_text := _make_label(str(advice.get("message", "")), 14, COLOR_MUTED)
	advice_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	advice_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(advice_text)
	box.add_child(_make_button("查看建议与风险", func(): show_ai_advice(advice), false, false, 0))
	var note := _make_label("AI 依赖度不会在流程中直接显示。你的使用和核验习惯会影响结局。", 12, Color("#789994"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	return panel


func _make_location_button(location: Dictionary) -> Button:
	var button := Button.new()
	button.text = "%s   %s\n%s" % [location.get("icon", "◆"), location.get("name", "地点"), location.get("subtitle", "")]
	button.custom_minimum_size = Vector2(260, 126)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var accent := Color(str(location.get("color", "#55C2A3")))
	_style_button(button, Color("#1C3D44E8"), accent)
	button.tooltip_text = str(location.get("description", ""))
	button.pressed.connect(show_location.bind(str(location.get("id", ""))))
	return button


func show_location(location_id: String) -> void:
	var location := repository.get_location(location_id)
	if location.is_empty():
		return
	var event := event_engine.get_location_event(location_id, session)
	if not event.is_empty():
		show_event(event)
		return
	var root := _reset_screen("location", Color(str(location.get("color", "#6DAF9A"))))
	root.add_child(_make_header(str(location.name), str(location.subtitle), show_map))
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var panel := _make_panel(COLOR_PANEL, 20, Color(str(location.color)))
	panel.custom_minimum_size = Vector2(900, 470)
	body.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var icon := _make_label(str(location.icon), 52, Color(str(location.color)))
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(icon)
	var description := _make_label(str(location.description), 19, COLOR_INK)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	box.add_child(_make_separator())
	box.add_child(_make_label("本时段可以：", 18, COLOR_MUTED))
	for action in location.get("actions", []):
		var action_button := _make_button("%s\n%s" % [action.get("label", "行动"), action.get("description", "")], _resolve_fallback_action.bind(action), true)
		action_button.custom_minimum_size.y = 72
		box.add_child(action_button)


func show_event(event: Dictionary) -> void:
	var root := _reset_screen("event", Color("#4D8190"))
	var top := HBoxContainer.new()
	root.add_child(top)
	var time_label := _make_badge(session.clock.get_display_text(), COLOR_TEAL)
	top.add_child(time_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(_make_badge("选择将消耗一个时段", COLOR_ACCENT))

	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var card := _make_panel(Color("#122C35FA"), 22, Color("#4B7F84"))
	card.custom_minimum_size = Vector2(980, 560)
	center.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 13)
	card.add_child(box)
	var speaker := _make_label(str(event.get("speaker", "校园事件")), 15, COLOR_TEAL)
	box.add_child(speaker)
	box.add_child(_make_label(str(event.get("title", "事件")), 31, COLOR_INK))
	var body := _make_label(str(event.get("body", "")), 19, COLOR_MUTED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = 110
	box.add_child(body)
	box.add_child(_make_separator())
	box.add_child(_make_label("你准备怎么做？", 17, COLOR_INK))
	for choice in event.get("choices", []):
		var button := _make_button(str(choice.get("label", "选择")), _resolve_event_choice.bind(event, choice), true)
		button.custom_minimum_size.y = 56
		box.add_child(button)


func _resolve_event_choice(event: Dictionary, choice: Dictionary) -> void:
	var effects := event_engine.apply_choice(event, choice, session)
	var outcome := str(choice.get("outcome", "你的选择产生了影响。"))
	show_result(str(event.get("title", "事件结果")), outcome, _visible_effects(effects), _advance_after_action)


func _resolve_fallback_action(action: Dictionary) -> void:
	var effects := event_engine.apply_fallback_action(action, session)
	show_result(str(action.get("label", "行动完成")), str(action.get("description", "这个时段结束了。")), _visible_effects(effects), _advance_after_action)


func _visible_effects(effects: Array[String]) -> Array[String]:
	var visible: Array[String] = []
	for effect in effects:
		if effect.begins_with("AI依赖"):
			visible.append("AI 使用习惯发生变化")
		else:
			visible.append(effect)
	return visible


func show_result(title_text: String, description: String, effects: Array[String], continue_action: Callable) -> void:
	var root := _reset_screen("result", Color("#678F8C"))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(Color("#122C35F8"), 22, COLOR_TEAL)
	panel.custom_minimum_size = Vector2(760, 430)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var small := _make_label("选择的回声", 14, COLOR_TEAL)
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(small)
	var title := _make_label(title_text, 30, COLOR_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var text := _make_label(description, 18, COLOR_MUTED)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(text)
	var effect_box := VBoxContainer.new()
	effect_box.add_theme_constant_override("separation", 6)
	box.add_child(effect_box)
	for effect in effects:
		var effect_label := _make_label("•  " + effect, 16, COLOR_INK)
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_box.add_child(effect_label)
	box.add_child(_make_button("继续", continue_action, true))


func _advance_after_action() -> void:
	var transition := session.clock.advance()
	var day_messages: Array[String] = []
	if bool(transition.get("day_changed", false)) and not session.clock.is_finished():
		var energy_change := session.change_stat("energy", 7)
		var stress_change := session.change_stat("stress", -2)
		day_messages.append("跨夜恢复：精力 %s%d" % ["+" if energy_change >= 0 else "", energy_change])
		day_messages.append("新的一天：压力 %s%d" % ["+" if stress_change >= 0 else "", stress_change])
	var consequences := event_engine.process_due_consequences(session)
	var save_error := save_service.save_game(session)
	if save_error != OK:
		notice_text = "自动存档失败：%s" % error_string(save_error)
	if bool(session.flags.get("presentation_completed", false)) or session.clock.is_finished():
		show_ending()
		return
	if not consequences.is_empty():
		var first: Dictionary = consequences[0]
		var effect_lines: Array[String] = []
		for line in first.get("effects", []):
			effect_lines.append(str(line))
		effect_lines.append_array(day_messages)
		show_result(str(first.get("title", "延迟后果")), str(first.get("message", "之前的选择产生了影响。")), _visible_effects(effect_lines), _present_current_state)
	elif not day_messages.is_empty():
		show_result("新的一天", "睡眠没有解决所有问题，但给了你重新安排的机会。", day_messages, _present_current_state)
	else:
		_present_current_state()


func show_ai_advice(advice: Dictionary) -> void:
	var root := _reset_screen("ai_advice", Color("#527F9C"))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(Color("#102B38F8"), 22, COLOR_BLUE)
	panel.custom_minimum_size = Vector2(760, 460)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var ai_icon := _make_label("AI  学伴", 18, COLOR_BLUE)
	ai_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ai_icon)
	var title := _make_label(str(advice.get("title", "建议")), 30, COLOR_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var message := _make_label(str(advice.get("message", "")), 20, COLOR_INK)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(message)
	var risk_panel := _make_panel(Color("#4B3034E8"), 12, COLOR_CORAL)
	box.add_child(risk_panel)
	var risk := _make_label("核验提醒：%s" % advice.get("risk", "建议可能不完整。"), 15, Color("#FFD4CE"))
	risk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	risk_panel.add_child(risk)
	box.add_child(_make_button("我会自己判断", show_map, true))


func show_pause_menu() -> void:
	if session == null:
		show_main_menu()
		return
	var root := _reset_screen("pause", Color("#466D72"))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(Color("#102931FA"), 22, COLOR_ACCENT)
	panel.custom_minimum_size = Vector2(500, 470)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 13)
	panel.add_child(box)
	var title := _make_label("暂停一下", 36, COLOR_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var time := _make_label(session.clock.get_display_text(), 16, COLOR_MUTED)
	time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(time)
	box.add_child(_make_separator())
	box.add_child(_make_button("继续游戏", show_map, true))
	box.add_child(_make_button("保存进度", _manual_save))
	box.add_child(_make_button("设置", func(): show_settings("pause")))
	box.add_child(_make_button("返回主菜单", show_main_menu, false, true))


func _manual_save() -> void:
	var error := save_service.save_game(session)
	var text := "进度已保存。" if error == OK else "保存失败：%s" % error_string(error)
	show_result("自动存档", text, [], show_pause_menu)


func show_settings(return_screen: String) -> void:
	settings_return_screen = return_screen
	var root := _reset_screen("settings", Color("#577D86"))
	root.add_child(_make_header("设置", "设置数据与游戏进度分开保存", _return_from_settings))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(COLOR_PANEL, 20, Color("#4D7B82"))
	panel.custom_minimum_size = Vector2(720, 430)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	box.add_child(_make_label("主音量", 18, COLOR_INK))
	var volume_row := HBoxContainer.new()
	box.add_child(volume_row)
	var volume_slider := HSlider.new()
	volume_slider.name = "MasterVolume"
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = float(settings.get("master_volume", 0.8))
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_row.add_child(volume_slider)
	var volume_value := _make_label("%d%%" % int(volume_slider.value * 100.0), 16, COLOR_MUTED)
	volume_value.custom_minimum_size.x = 70
	volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	volume_row.add_child(volume_value)
	volume_slider.value_changed.connect(func(value): volume_value.text = "%d%%" % int(value * 100.0))

	var fullscreen := CheckButton.new()
	fullscreen.name = "Fullscreen"
	fullscreen.text = "全屏显示"
	fullscreen.button_pressed = bool(settings.get("fullscreen", false))
	fullscreen.custom_minimum_size.y = 48
	box.add_child(fullscreen)
	var reduced_motion := CheckButton.new()
	reduced_motion.name = "ReducedMotion"
	reduced_motion.text = "减少界面动效"
	reduced_motion.button_pressed = bool(settings.get("reduced_motion", false))
	reduced_motion.custom_minimum_size.y = 48
	box.add_child(reduced_motion)
	var note := _make_label("本 Demo 不采集遥测数据，也不会上传设置或存档。", 14, COLOR_MUTED)
	box.add_child(note)
	box.add_child(_make_button("保存设置", _save_settings.bind(volume_slider, fullscreen, reduced_motion), true))


func _save_settings(volume: HSlider, fullscreen: CheckButton, reduced_motion: CheckButton) -> void:
	settings = {
		"master_volume": volume.value,
		"fullscreen": fullscreen.button_pressed,
		"reduced_motion": reduced_motion.button_pressed,
	}
	var error := save_service.save_settings(settings)
	_apply_settings()
	if error != OK:
		notice_text = "设置保存失败：%s" % error_string(error)
	_return_from_settings()


func _apply_settings() -> void:
	var volume := maxf(float(settings.get("master_volume", 0.8)), 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))
	AudioServer.set_bus_mute(0, volume <= 0.001)
	if not OS.has_feature("headless"):
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(settings.get("fullscreen", false)) else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(mode)


func _return_from_settings() -> void:
	if settings_return_screen == "pause" and session != null:
		show_pause_menu()
	else:
		show_main_menu()


func show_credits() -> void:
	var root := _reset_screen("credits", Color("#5E8C82"))
	root.add_child(_make_header("制作与许可", "原创内容与第三方来源透明记录", show_main_menu))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(COLOR_PANEL, 20, Color("#49756F"))
	panel.custom_minimum_size = Vector2(900, 500)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	panel.add_child(box)
	box.add_child(_make_label("惊魂期末周 · CampusLifeSim", 28, COLOR_INK))
	var text := _make_label("策划、程序、事件文本与程序化校园视觉：CampusLifeSim 项目\n\n引擎：Godot 4.7.1（MIT License）\n菜单、加载、暂停及音频基础参考：Maaack/Godot-Game-Template v1.4.7（MIT License）\n上游作者：Marek Belski\n\n本项目未使用 Maaack 品牌 Logo、Godot Logo、Git Logo或来源不明的第三方美术。完整许可证与素材记录随项目分发。", 17, COLOR_MUTED)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(text)
	box.add_child(_make_button("返回", show_main_menu, true))


func show_exit_confirmation() -> void:
	var root := _reset_screen("exit_confirm", Color("#4D6B70"))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(Color("#102931FA"), 20, COLOR_CORAL)
	panel.custom_minimum_size = Vector2(520, 300)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := _make_label("要退出游戏吗？", 30, COLOR_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var desc := _make_label("进度会在每个行动后自动保存。", 16, COLOR_MUTED)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desc)
	box.add_child(_make_button("取消", show_main_menu))
	box.add_child(_make_button("退出", func(): get_tree().quit(), false, true))


func show_ending() -> void:
	var ending := EndingEvaluator.new().evaluate(session, repository.endings)
	var ending_color := Color(str(ending.get("color", "#E0B14C")))
	var root := _reset_screen("ending", ending_color)
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(Color("#102931F8"), 24, ending_color)
	panel.custom_minimum_size = Vector2(940, 600)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 13)
	panel.add_child(box)
	var eyebrow := _make_label("你的期末周结局", 15, ending_color)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	var title := _make_label(str(ending.get("title", "结局")), 43, COLOR_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var tagline := _make_label(str(ending.get("tagline", "")), 19, COLOR_ACCENT)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tagline)
	var description := _make_label(str(ending.get("description", "")), 18, COLOR_MUTED)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.y = 90
	box.add_child(description)
	box.add_child(_make_separator())
	var summary := GridContainer.new()
	summary.columns = 4
	summary.add_theme_constant_override("h_separation", 10)
	box.add_child(summary)
	summary.add_child(_make_summary_cell("学习", int(session.stats.study), COLOR_TEAL))
	summary.add_child(_make_summary_cell("项目", int(session.stats.project), COLOR_BLUE))
	summary.add_child(_make_summary_cell("精力", int(session.stats.energy), COLOR_ACCENT))
	summary.add_child(_make_summary_cell("压力", int(session.stats.stress), COLOR_CORAL))
	var reveal := _make_label("AI 依赖度：%d   ·   平均关系：%d   ·   经历事件：%d" % [int(session.stats.ai_dependence), int(session.average_relationship()), session.event_history.size()], 15, COLOR_MUTED)
	reveal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(reveal)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	var again := _make_button("再玩一次", _restart_game, true)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(again)
	var menu := _make_button("返回主菜单", show_main_menu)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(menu)


func _restart_game() -> void:
	save_service.delete_save()
	show_setup()


func _show_fatal_error(message: String) -> void:
	var root := _reset_screen("fatal", Color("#7A4650"))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(Color("#2C171CFA"), 20, COLOR_CORAL)
	panel.custom_minimum_size = Vector2(760, 420)
	center.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_make_label("项目无法启动", 32, COLOR_CORAL))
	var details := _make_label(message, 16, COLOR_INK)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(details)
	box.add_child(_make_button("退出", func(): get_tree().quit(), false, true))


func _make_header(title_text: String, subtitle_text: String, back_action: Callable) -> Control:
	var panel := _make_panel(Color("#112C34F4"), 16, Color("#3E7372"))
	panel.custom_minimum_size.y = 72
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	row.add_child(_make_button("← 返回", back_action, false, false, 110))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(box)
	box.add_child(_make_label(title_text, 24, COLOR_INK))
	box.add_child(_make_label(subtitle_text, 14, COLOR_MUTED))
	return panel


func _make_panel(color: Color, radius: int = 14, border_color: Color = Color.TRANSPARENT) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	if border_color.a > 0.0:
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = border_color
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_label(text_value: String, size: int = 18, color: Color = COLOR_INK) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(text_value: String, action: Callable, accent: bool = false, danger: bool = false, width: int = 0) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(width, 48)
	button.add_theme_font_size_override("font_size", 17)
	var color := Color("#244850")
	var border := Color("#52757A")
	if accent:
		color = Color("#29735F")
		border = COLOR_TEAL
	elif danger:
		color = Color("#63363C")
		border = COLOR_CORAL
	_style_button(button, color, border)
	button.pressed.connect(action)
	return button


func _style_button(button: Button, base_color: Color, border_color: Color) -> void:
	var normal := _button_style(base_color, border_color, 10)
	var hover := _button_style(base_color.lightened(0.12), border_color.lightened(0.12), 10)
	var pressed := _button_style(base_color.darkened(0.08), COLOR_ACCENT, 10)
	var disabled := _button_style(Color("#27383B"), Color("#405154"), 10)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", COLOR_INK)
	button.add_theme_color_override("font_disabled_color", Color("#738381"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)


func _button_style(color: Color, border_color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _style_line_edit(line_edit: LineEdit) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0D252DE8")
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color("#467078")
	style.content_margin_left = 14
	style.content_margin_right = 14
	line_edit.add_theme_stylebox_override("normal", style)
	line_edit.add_theme_stylebox_override("focus", style)
	line_edit.add_theme_color_override("font_color", COLOR_INK)
	line_edit.add_theme_color_override("font_placeholder_color", Color("#718B88"))


func _make_separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.modulate = Color("#5B7B7C88")
	separator.custom_minimum_size.y = 6
	return separator


func _make_badge(text_value: String, accent: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent, 0.13)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(accent, 0.65)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	badge.add_theme_stylebox_override("panel", style)
	badge.add_child(_make_label(text_value, 14, accent.lightened(0.16)))
	return badge


func _make_stat_bar(label_text: String, value: int, color: Color) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var row := HBoxContainer.new()
	box.add_child(row)
	var label := _make_label(label_text, 14, COLOR_MUTED)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(_make_label(str(value), 15, color))
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size.y = 8
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#0A2026")
	background.corner_radius_top_left = 4
	background.corner_radius_top_right = 4
	background.corner_radius_bottom_left = 4
	background.corner_radius_bottom_right = 4
	var fill := background.duplicate()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	box.add_child(bar)
	return box


func _make_relationship_row(npc: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	var avatar := _make_badge(str(npc.get("avatar", "同")), Color(str(npc.get("color", "#55C2A3"))))
	avatar.custom_minimum_size.x = 42
	row.add_child(avatar)
	var name_label := _make_label(str(npc.get("name", "同学")), 14, COLOR_MUTED)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.add_child(_make_label(str(int(session.relationships.get(npc.get("id", ""), 0))), 15, COLOR_INK))
	return row


func _make_progress_card(title_text: String, value: int, deadline: String) -> PanelContainer:
	var panel := _make_panel(Color("#102A31CC"), 10, Color("#385D62"))
	var box := VBoxContainer.new()
	panel.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var title := _make_label(title_text, 15, COLOR_INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(_make_label("%d%%" % value, 15, COLOR_ACCENT))
	box.add_child(_make_label(deadline, 12, COLOR_MUTED))
	return panel


func _make_summary_cell(title_text: String, value: int, accent: Color) -> PanelContainer:
	var panel := _make_panel(Color("#17343BDD"), 12, Color(accent, 0.55))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	panel.add_child(box)
	var value_label := _make_label(str(value), 28, accent)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value_label)
	var title := _make_label(title_text, 13, COLOR_MUTED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	return panel
