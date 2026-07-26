extends Control

const COLOR_INK := Color("#F4F2E9")
const COLOR_MUTED := Color("#9BAAA7")
const COLOR_DARK := Color("#071013")
const COLOR_PANEL := Color("#0E191CF5")
const COLOR_PANEL_LIGHT := Color("#142326F5")
const COLOR_ACCENT := Color("#F4C45E")
const COLOR_TEAL := Color("#63DDB8")
const COLOR_CORAL := Color("#FF8580")
const COLOR_BLUE := Color("#7CB9E8")
# Screen-accessible derivative of SDU's official print color C26 M100 Y100 K28.
const COLOR_SDU_RED := Color("#B84850")
const TRAVEL_DURATION_SECONDS := 2.0

var repository := ContentRepository.new()
var background_catalog := BackgroundCatalog.new()
var event_engine: EventEngine
var save_service := SaveService.new()
var session: GameSession
var current_screen := "main_menu"
var settings_return_screen := "main_menu"
var settings := {}
var screen_layer: Control
var active_photo_background: TextureRect
var active_photo_fill: TextureRect
var notice_text := ""


func _ready() -> void:
	set_process_unhandled_input(true)
	_build_theme()
	settings = save_service.load_settings()
	_apply_settings()
	if not repository.load_all():
		_show_fatal_error("内容数据校验失败\n\n" + "\n".join(repository.errors))
		return
	if not background_catalog.load_all():
		_show_fatal_error("场景图片校验失败\n\n" + "\n".join(background_catalog.errors))
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


func _reset_screen(screen_name: String, backdrop_tint: Color = Color.WHITE, background_path: String = "", shade_color: Color = Color("#07161CB8")) -> VBoxContainer:
	current_screen = screen_name
	active_photo_background = null
	active_photo_fill = null
	for child in get_children():
		child.queue_free()
	screen_layer = Control.new()
	screen_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen_layer)

	if not background_path.is_empty() and ResourceLoader.exists(background_path):
		var photo_texture := load(background_path) as Texture2D
		var photo_orientation := background_catalog.get_photo_orientation(background_path)
		active_photo_background = OrientedPhotoRect.new()
		active_photo_background.name = "PhotoFrame"
		active_photo_background.configure(photo_texture, photo_orientation, true)
		active_photo_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		screen_layer.add_child(active_photo_background)
	else:
		var backdrop := CampusBackdrop.new()
		backdrop.tint = backdrop_tint
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		screen_layer.add_child(backdrop)

	var shade := ColorRect.new()
	shade.color = shade_color
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


func _show_adaptive_scene(screen_name: String, data: Dictionary) -> AdaptiveSceneView:
	current_screen = screen_name
	active_photo_background = null
	active_photo_fill = null
	for child in get_children():
		child.queue_free()
	screen_layer = Control.new()
	screen_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen_layer)
	var view := AdaptiveSceneView.new()
	view.name = "AdaptiveScene"
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layer.add_child(view)
	view.configure(data)
	active_photo_background = view.photo_rect
	return view


func _base_scene_data(scene_context: Dictionary, background_path: String) -> Dictionary:
	var scene_name := str(scene_context.get("display_name", "校园场景"))
	var photo_shape := "原图比例"
	if not background_path.is_empty() and ResourceLoader.exists(background_path):
		var image_texture := load(background_path) as Texture2D
		if image_texture != null:
			var image_size := image_texture.get_size()
			if background_catalog.get_photo_orientation(background_path) in [6, 8]:
				image_size = Vector2(image_size.y, image_size.x)
			photo_shape = "竖幅原图" if image_size.x < image_size.y else "横幅原图"
	return {
		"image_path": background_path,
		"orientation": background_catalog.get_photo_orientation(background_path),
		"time": session.clock.get_display_text() if session != null else "期末周",
		"scene_name": scene_name,
		"activity": str(scene_context.get("activity_text", "安排当前时段")),
		"photo_shape": photo_shape,
		"energy": int(session.stats.energy) if session != null else 0,
		"stress": int(session.stats.stress) if session != null else 0,
		"exam": int(session.tasks.exam) if session != null else 0,
		"footer_hint": "山东大学中心校区 · 离线运行 · 自动存档",
	}


func _scene_state_tags() -> Array:
	if session == null:
		return []
	var difficulty_color := str(DifficultyRules.get_config(session.difficulty_id).get("color", "#63DDB8"))
	var energy_state := "精力尚可"
	var energy_color := "#63DDB8"
	if int(session.stats.energy) <= 25:
		energy_state = "精力告急"
		energy_color = "#FF8580"
	elif int(session.stats.energy) <= 50:
		energy_state = "精力偏低"
		energy_color = "#F4C45E"
	var stress_state := "压力可控"
	var stress_color := "#7CB9E8"
	if int(session.stats.stress) >= DifficultyRules.get_crisis_threshold(session.difficulty_id):
		stress_state = "压力过载"
		stress_color = "#FF8580"
	elif int(session.stats.stress) >= 60:
		stress_state = "压力偏高"
		stress_color = "#F4C45E"
	return [
		{"text": "%s难度" % DifficultyRules.get_display_name(session.difficulty_id), "color": difficulty_color},
		{"text": energy_state, "color": energy_color},
		{"text": stress_state, "color": stress_color},
	]


func _effect_preview(effects) -> String:
	if not effects is Array or effects.is_empty():
		return "情境选择"
	var parts: Array[String] = []
	for effect_value in effects:
		if not effect_value is Dictionary:
			continue
		var effect: Dictionary = effect_value
		var effect_type := str(effect.get("type", ""))
		var target := str(effect.get("target", ""))
		var amount := int(effect.get("amount", 0))
		var target_name: String = {
			"study": "学习",
			"project": "项目",
			"energy": "精力",
			"stress": "压力",
			"ai_dependence": "AI习惯",
			"exam": "考试",
			"presentation": "展示",
			"roommate": "室友关系",
			"teammate": "组员关系",
			"scholar": "同学关系",
			"monitor": "班长关系",
		}.get(target, target)
		if effect_type == "flag":
			continue
		if target == "ai_dependence":
			parts.append("AI 使用习惯")
			continue
		var adjusted: int = DifficultyRules.adjust_effect_amount(effect_type, target, amount, session.difficulty_id) if session != null else amount
		parts.append("%s %s%d" % [target_name, "+" if adjusted >= 0 else "", adjusted])
		if parts.size() >= 2:
			break
	return " · ".join(parts) if not parts.is_empty() else "记录线索"


func _choice_detail(choice: Dictionary) -> String:
	if not choice.get("delayed", []).is_empty():
		return "这项决定还可能在之后继续产生影响。"
	for effect_value in choice.get("effects", []):
		if effect_value is Dictionary and str(effect_value.get("target", "")) == "ai_dependence":
			return "可以快速推进，但仍需要你保留自己的判断。"
	return "根据当前精力、压力和截止日期权衡这项选择。"


func _soundscape_period() -> StringName:
	if session == null or session.clock.is_finished():
		return &"evening"
	if session.clock.slot <= 2:
		return &"day"
	if session.clock.slot == 3:
		return &"evening"
	return &"night"


func _session_soundscape_context() -> StringName:
	if session == null or session.current_location_id.is_empty():
		return &"campus"
	return StringName(session.current_location_id)


func _set_soundscape(context: StringName, fade_seconds: float = 0.65, period_override: StringName = &"", stress_override: int = -1) -> void:
	var ambient_controller := get_node_or_null("/root/ProjectAmbientSoundController")
	if ambient_controller == null or not ambient_controller.has_method("transition_to"):
		return
	var period := period_override if period_override != &"" else _soundscape_period()
	var stress_level := stress_override if stress_override >= 0 else (int(session.stats.stress) if session != null else 0)
	ambient_controller.transition_to(context, period, fade_seconds, stress_level)


func show_main_menu() -> void:
	_set_soundscape(&"menu", 0.85, &"evening", 0)
	var root := _reset_screen("main_menu", Color("#284246"), background_catalog.get_menu_background(), Color("#050C0EE0"))
	var top := HBoxContainer.new()
	root.add_child(top)
	top.add_child(_make_badge("山东大学中心校区 · 人工智能学院", COLOR_SDU_RED))
	var top_space := Control.new()
	top_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_space)
	var build_version := str(ProjectSettings.get_setting("application/config/version", "DEV")).trim_suffix("-demo")
	top.add_child(_make_label("BUILD  %s · OFFLINE" % build_version, 11, Color("#71837F")))

	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 54)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(main)

	var identity := VBoxContainer.new()
	identity.custom_minimum_size.x = 650
	identity.add_theme_constant_override("separation", 13)
	main.add_child(identity)
	var marker := ColorRect.new()
	marker.color = COLOR_SDU_RED
	marker.custom_minimum_size = Vector2(72, 3)
	identity.add_child(marker)
	identity.add_child(_make_label("SHANDONG UNIVERSITY · FINAL WEEK", 16, COLOR_SDU_RED))
	var title := _make_label("惊魂期末周", 70, COLOR_INK)
	identity.add_child(title)
	var subtitle := _make_label("山大南路 27 号，七天、五个时段，以及没有标准答案的校园生活。", 23, Color("#D3DDD8"))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity.add_child(subtitle)
	var statement := _make_label("在考试、项目、关系与身体状态之间做选择。\n每一次取舍都会留下痕迹，并在之后重新出现。", 16, COLOR_MUTED)
	statement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity.add_child(statement)
	var feature_row := HBoxContainer.new()
	feature_row.add_theme_constant_override("separation", 8)
	identity.add_child(feature_row)
	feature_row.add_child(_make_badge("中心校区", COLOR_SDU_RED))
	feature_row.add_child(_make_badge("7 天", COLOR_TEAL))
	feature_row.add_child(_make_badge("5 时段 / 天", COLOR_BLUE))
	feature_row.add_child(_make_badge("6 个地点", COLOR_ACCENT))
	feature_row.add_child(_make_badge("7 种结局", COLOR_CORAL))

	var card := _make_panel(Color("#0B1518F5"), 20, Color("#36545A"))
	card.custom_minimum_size = Vector2(410, 480)
	main.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	card.add_child(box)
	box.add_child(_make_label("开始你的期末周", 25, COLOR_INK))
	var menu_note := _make_label("进度在每次选择后自动保存。", 13, COLOR_MUTED)
	box.add_child(menu_note)
	box.add_child(_make_separator())
	var new_button := _make_button("开始新的期末周  →", show_setup, true)
	new_button.custom_minimum_size.y = 58
	box.add_child(new_button)
	var continue_button := _make_button("继续上次进度", continue_game)
	continue_button.disabled = not save_service.has_save()
	box.add_child(continue_button)
	box.add_child(_make_button("设置", func(): show_settings("main_menu")))
	box.add_child(_make_button("制作与许可", show_credits))
	var card_space := Control.new()
	card_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(card_space)
	box.add_child(_make_button("退出游戏", show_exit_confirmation, false, true))
	box.add_child(_make_label("离线运行 · 原图展示 · Godot 4.7.1", 11, Color("#61736F")))

	var footer := HBoxContainer.new()
	root.add_child(footer)
	footer.add_child(_make_label("SDU · 1901 · CAMPUSLIFESIM", 10, COLOR_SDU_RED))
	var footer_space := Control.new()
	footer_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_space)
	footer.add_child(_make_label("学无止境，气有浩然", 10, Color("#8F9F9B")))


func show_setup() -> void:
	_set_soundscape(&"menu", 0.5, &"evening", 0)
	var root := _reset_screen("setup", Color("#244046"), "", Color("#07101388"))
	root.add_child(_make_header("人工智能学院 · 期末周档案", "在山大期末周开始前，给自己一个名字和起点", show_main_menu))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(COLOR_PANEL, 20, Color("#36545A"))
	panel.custom_minimum_size = Vector2(940, 550)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
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
		trait_button.custom_minimum_size = Vector2(290, 118)
		trait_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		trait_button.add_theme_font_size_override("font_size", 17)
		_style_button(trait_button, Color("#21464F"), COLOR_TEAL)
		trait_button.set_meta("trait_id", trait_entry.id)
		trait_button.set_meta("audio_cue", &"select")
		trait_row.add_child(trait_button)
		if trait_entry.id == "study":
			trait_button.button_pressed = true

	box.add_child(_make_label("选择难度", 20, COLOR_INK))
	var difficulty_group := ButtonGroup.new()
	var difficulty_row := HBoxContainer.new()
	difficulty_row.add_theme_constant_override("separation", 12)
	box.add_child(difficulty_row)
	for difficulty_id in DifficultyRules.ORDER:
		var config: Dictionary = DifficultyRules.get_config(difficulty_id)
		var difficulty_button := Button.new()
		difficulty_button.name = "Difficulty_%s" % difficulty_id
		difficulty_button.text = "%s · %s\n%s" % [config.name, config.subtitle, config.description]
		difficulty_button.toggle_mode = true
		difficulty_button.button_group = difficulty_group
		difficulty_button.custom_minimum_size = Vector2(290, 82)
		difficulty_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		difficulty_button.add_theme_font_size_override("font_size", 14)
		_style_button(difficulty_button, Color("#21464F"), Color(str(config.color)))
		difficulty_button.set_meta("difficulty_id", difficulty_id)
		difficulty_button.set_meta("audio_cue", &"select")
		difficulty_row.add_child(difficulty_button)
		if difficulty_id == DifficultyRules.DEFAULT_NEW_GAME:
			difficulty_button.button_pressed = true

	var tip := _make_label("难度会改变每次结算：压力、精力消耗、恢复效率与学业收益。中等为推荐体验。", 14, COLOR_MUTED)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tip)
	var start_button := _make_button("进入期末周", func(): _start_from_setup(name_input, trait_group, difficulty_group), true)
	box.add_child(start_button)


func _start_from_setup(name_input: LineEdit, trait_group: ButtonGroup, difficulty_group: ButtonGroup) -> void:
	var trait_id := "study"
	var pressed := trait_group.get_pressed_button()
	if pressed != null:
		trait_id = str(pressed.get_meta("trait_id"))
	var difficulty_id := DifficultyRules.DEFAULT_NEW_GAME
	var pressed_difficulty := difficulty_group.get_pressed_button()
	if pressed_difficulty != null:
		difficulty_id = str(pressed_difficulty.get_meta("difficulty_id"))
	session = GameSession.new()
	session.reset(name_input.text, trait_id, difficulty_id)
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
	_set_soundscape(&"campus", 0.65)
	var root := _reset_screen("map", Color("#18373A"), "", Color("#07101366"))
	root.add_child(_make_game_header())
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)

	columns.add_child(_build_status_panel())
	columns.add_child(_build_map_panel())
	columns.add_child(_build_schedule_panel())


func _make_game_header() -> Control:
	var panel := _make_panel(Color("#0B1518F5"), 16, Color("#36545A"))
	panel.custom_minimum_size.y = 72
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)
	title_box.add_child(_make_label("惊魂期末周 · 山东大学中心校区", 23, COLOR_INK))
	title_box.add_child(_make_label("%s  /  %s  /  %s难度  /  人工智能学院" % [session.player_name, session.clock.get_display_text(), DifficultyRules.get_display_name(session.difficulty_id)], 13, COLOR_MUTED))
	var exam_badge := _make_badge("核心课考试：第 5 天上午", COLOR_TEAL)
	row.add_child(exam_badge)
	var project_badge := _make_badge("展示：第 7 天下午", COLOR_ACCENT)
	row.add_child(project_badge)
	row.add_child(_make_button("暂停  Esc", show_pause_menu, false, false, 120))
	return panel


func _build_status_panel() -> Control:
	var panel := _make_panel(Color("#0B1518F2"), 16, Color("#294247"))
	panel.custom_minimum_size.x = 245
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	box.add_child(_make_label("STATUS / 当前状态", 18, COLOR_INK))
	var difficulty_config := DifficultyRules.get_config(session.difficulty_id)
	box.add_child(_make_label("%s难度 · %s" % [difficulty_config.name, difficulty_config.subtitle], 13, Color(str(difficulty_config.color))))
	box.add_child(_make_stat_bar("学习进度", int(session.stats.study), COLOR_TEAL))
	box.add_child(_make_stat_bar("项目进度", int(session.stats.project), COLOR_BLUE))
	box.add_child(_make_stat_bar("精力", int(session.stats.energy), COLOR_ACCENT))
	box.add_child(_make_stat_bar("压力", int(session.stats.stress), COLOR_CORAL))
	if int(session.stats.stress) >= DifficultyRules.get_crisis_threshold(session.difficulty_id):
		var warning := _make_label("⚠ 高压：下一次结算可能出现眩晕", 12, Color("#FFD4CE"))
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(warning)
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
	var panel := _make_panel(Color("#0E191CF0"), 18, Color("#36545A"))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := _make_label("选择下一站", 25, COLOR_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := _make_label("点击地点后将经过约 2 秒校园路途。每次行动都会推进时间。", 13, COLOR_MUTED)
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
	var panel := _make_panel(Color("#0B1518F2"), 16, Color("#294247"))
	panel.custom_minimum_size.x = 275
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_make_label("DEADLINES / 日程", 18, COLOR_INK))
	box.add_child(_make_progress_card("人工智能核心课", int(session.tasks.exam), "第 5 天上午"))
	box.add_child(_make_progress_card("AI 课程项目展示", int(session.tasks.presentation), "第 7 天下午"))
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
	_style_button(button, Color("#142326F2"), Color(accent, 0.72))
	button.tooltip_text = str(location.get("description", ""))
	button.set_meta("audio_cue", &"location_enter")
	button.pressed.connect(_travel_to_location.bind(str(location.get("id", ""))))
	return button


func _travel_to_location(location_id: String, duration: float = TRAVEL_DURATION_SECONDS) -> void:
	var location := repository.get_location(location_id)
	if location.is_empty() or session == null:
		return
	background_catalog.choose_location_background(location_id, session)
	var road_background := background_catalog.choose_road_background(session)
	var save_error := save_service.save_game(session)
	if save_error != OK:
		notice_text = "自动存档失败：%s" % error_string(save_error)
	show_travel(location, road_background, duration)
	await get_tree().create_timer(maxf(duration, 0.01)).timeout
	if current_screen == "travel" and session != null and session.current_location_id == location_id:
		show_location(location_id)


func show_travel(location: Dictionary, road_background: String, duration: float = TRAVEL_DURATION_SECONDS) -> void:
	_set_soundscape(&"road", minf(maxf(duration, 0.01) * 0.32, 0.65))
	var ambient_controller := get_node_or_null("/root/ProjectAmbientSoundController")
	if ambient_controller != null and ambient_controller.has_method("prepare_context"):
		ambient_controller.call_deferred("prepare_context", StringName(location.get("id", "campus")), _soundscape_period())
	var root := _reset_screen("travel", Color("#416B72"), road_background, Color("#07101372"))
	if active_photo_background != null:
		var resting_position := active_photo_background.position
		active_photo_background.scale = Vector2(1.12, 1.12)
		active_photo_background.position.x = resting_position.x + 24.0
		if not bool(settings.get("reduced_motion", false)):
			var pan_tween := create_tween().set_parallel(true)
			pan_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			pan_tween.tween_property(active_photo_background, "position:x", resting_position.x - 24.0, maxf(duration, 0.01))

	var top := HBoxContainer.new()
	root.add_child(top)
	top.add_child(_make_badge("SDU · CAMPUS TRANSIT", COLOR_SDU_RED))
	var top_space := Control.new()
	top_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_space)
	top.add_child(_make_badge(session.clock.get_display_text(), COLOR_BLUE))
	var vertical_space := Control.new()
	vertical_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(vertical_space)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(bottom)
	var panel := _make_panel(Color("#091316F2"), 18, Color(str(location.get("color", "#63DDB8"))))
	panel.custom_minimum_size = Vector2(760, 178)
	bottom.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	var route := HBoxContainer.new()
	box.add_child(route)
	route.add_child(_make_label("正在穿过校园", 12, COLOR_TEAL))
	var route_space := Control.new()
	route_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route.add_child(route_space)
	route.add_child(_make_label("约 2 秒", 11, COLOR_MUTED))
	var title := _make_label("前往  %s" % location.get("name", "新地点"), 31, COLOR_INK)
	box.add_child(title)
	box.add_child(_make_label("路上的片刻，也属于山大期末周。学无止境，先从下一步开始。", 14, COLOR_MUTED))
	var progress := ProgressBar.new()
	progress.name = "TravelProgress"
	progress.show_percentage = false
	progress.value = 0.0
	progress.custom_minimum_size.y = 10
	box.add_child(progress)
	var progress_tween := create_tween()
	progress_tween.set_trans(Tween.TRANS_LINEAR)
	progress_tween.tween_property(progress, "value", 100.0, maxf(duration, 0.01))
	var photo_note := _make_label("校园道路原图 · 仅做等比裁切与平移", 10, Color("#80918D"))
	photo_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(photo_note)


func show_location(location_id: String) -> void:
	var location := repository.get_location(location_id)
	if location.is_empty():
		return
	_set_soundscape(StringName(location_id), 0.55)
	if session.current_location_id != location_id or session.current_background_path.is_empty():
		background_catalog.choose_location_background(location_id, session)
	var scene_context := background_catalog.get_active_scene_context(session)
	var event := event_engine.get_location_event(location_id, session)
	if not event.is_empty():
		show_event(event)
		return
	var scene_name := str(scene_context.get("display_name", location.name))
	var choices: Array = []
	for action in location.get("actions", []):
		var presented_action := _present_action_for_scene(action, location_id, scene_context)
		choices.append({
			"name": "Action_%s" % str(action.get("id", "")),
			"title": str(presented_action.get("label", "行动")),
			"detail": str(presented_action.get("description", "")),
			"effect": _effect_preview(action.get("effects", [])),
			"effect_color": str(location.get("color", "#63DDB8")),
			"action": _resolve_fallback_action.bind(presented_action),
		})
	var data := _base_scene_data(scene_context, session.current_background_path)
	data.merge({
		"panel_name": "LocationCard",
		"section": "%s · 地点行动" % str(location.get("icon", "◆")),
		"accent": str(location.get("color", "#63DDB8")),
		"title": "抵达 · %s" % scene_name,
		"body": "%s\n%s" % [scene_context.get("arrival_text", location.description), location.description],
		"question": "这个时段，你准备做什么？",
		"cost_text": "行动后推进 1 个时段",
		"state_tags": _scene_state_tags(),
		"choices": choices,
		"pause_action": show_pause_menu,
	}, true)
	_show_adaptive_scene("location", data)


func show_event(event: Dictionary) -> void:
	background_catalog.ensure_event_background(str(event.get("id", "")), session)
	_set_soundscape(_session_soundscape_context(), 0.55)
	var scene_context := background_catalog.get_active_scene_context(session)
	var choices: Array = []
	for choice in event.get("choices", []):
		var choice_label := _format_scene_text(str(choice.get("label", "选择")), scene_context)
		choices.append({
			"name": "Choice_%s" % str(choice.get("id", "")),
			"title": choice_label,
			"detail": _choice_detail(choice),
			"effect": _effect_preview(choice.get("effects", [])),
			"effect_color": "#7CB9E8" if str(event.get("speaker", "")) == "AI 学伴" else "#63DDB8",
			"action": _resolve_event_choice.bind(event, choice),
		})
	var data := _base_scene_data(scene_context, session.current_background_path)
	data.merge({
		"panel_name": "EventCard",
		"section": str(event.get("speaker", "校园事件")),
		"accent": "#7CB9E8" if str(event.get("speaker", "")) == "AI 学伴" else "#63DDB8",
		"title": _format_scene_text(str(event.get("title", "事件")), scene_context),
		"body": _format_scene_text(str(event.get("body", "")), scene_context),
		"question": "你准备怎么做？",
		"cost_text": "选择后推进 1 个时段",
		"state_tags": _scene_state_tags(),
		"choices": choices,
	}, true)
	_show_adaptive_scene("event", data)


func _format_scene_text(text_value: String, scene_context: Dictionary) -> String:
	return text_value \
		.replace("{scene_name}", str(scene_context.get("display_name", "校园场景"))) \
		.replace("{scene_activity}", str(scene_context.get("activity_text", "处理眼前的安排")))


func _present_action_for_scene(action: Dictionary, location_id: String, scene_context: Dictionary) -> Dictionary:
	var presented := action.duplicate(true)
	var action_id := str(action.get("id", ""))
	var action_overrides = scene_context.get("action_overrides", {})
	if action_overrides is Dictionary and action_overrides.has(action_id):
		var override = action_overrides[action_id]
		if override is Dictionary:
			presented.merge(override, true)
	if location_id != "field":
		return presented
	if action_id == "exercise":
		var activity_label := str(scene_context.get("activity_label", ""))
		if not activity_label.is_empty():
			presented.label = activity_label
			presented.description = "按照照片中的真实场地活动身体，缓解压力并消耗少量精力。"
	elif action_id == "walk":
		presented.label = "在场边放松调整"
		presented.description = "先观察和舒展，让呼吸与心态慢慢稳定下来。"
	return presented


func _resolve_event_choice(event: Dictionary, choice: Dictionary) -> void:
	var effects := event_engine.apply_choice(event, choice, session)
	var scene_context := background_catalog.get_active_scene_context(session)
	var outcome := _format_scene_text(str(choice.get("outcome", "你的选择产生了影响。")), scene_context)
	var result_title := _format_scene_text(str(event.get("title", "事件结果")), scene_context)
	show_result(result_title, outcome, _visible_effects(effects), _advance_after_action)


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
	_set_soundscape(_session_soundscape_context(), 0.35)
	var background_path := session.current_background_path if session != null else ""
	if background_path.is_empty():
		background_path = background_catalog.get_menu_background()
	var scene_context := background_catalog.get_scene_context(background_path, session.current_location_id if session != null else "")
	var effect_text := "本次选择没有直接改变可见数值。"
	if not effects.is_empty():
		effect_text = " · ".join(effects)
	var data := _base_scene_data(scene_context, background_path)
	data.merge({
		"panel_name": "ResultCard",
		"section": "选择的回声",
		"accent": "#F4C45E",
		"title": title_text,
		"body": description,
		"question": "这次选择带来的变化",
		"cost_text": "结果已结算",
		"state_tags": _scene_state_tags(),
		"choices": [{
			"name": "ContinueResult",
			"title": "继续期末周",
			"detail": effect_text,
			"effect": "继续",
			"effect_color": "#F4C45E",
			"action": continue_action,
			"height": 88,
		}],
	}, true)
	_show_adaptive_scene("result", data)


func _advance_after_action() -> void:
	var transition := session.clock.advance()
	var day_messages: Array[String] = []
	if bool(transition.get("day_changed", false)) and not session.clock.is_finished():
		var energy_recovery := DifficultyRules.adjust_effect_amount("stat", "energy", 7, session.difficulty_id)
		var stress_relief := DifficultyRules.adjust_effect_amount("stat", "stress", -2, session.difficulty_id)
		var energy_change := session.change_stat("energy", energy_recovery)
		var stress_change := session.change_stat("stress", stress_relief)
		day_messages.append("跨夜恢复：精力 %s%d" % ["+" if energy_change >= 0 else "", energy_change])
		day_messages.append("新的一天：压力 %s%d" % ["+" if stress_change >= 0 else "", stress_change])
	var consequences := event_engine.process_due_consequences(session)
	session.clear_current_background()
	if bool(session.flags.get("presentation_completed", false)) or session.clock.is_finished():
		_save_current_session()
		show_ending()
		return
	var continue_action := _complete_advance.bind(consequences, day_messages)
	var crisis_key := "stress_crisis_slot_%d" % session.clock.get_index()
	if int(session.stats.stress) >= DifficultyRules.get_crisis_threshold(session.difficulty_id) and not bool(session.flags.get(crisis_key, false)):
		session.flags[crisis_key] = true
		session.flags["stress_crisis_count"] = int(session.flags.get("stress_crisis_count", 0)) + 1
		_save_current_session()
		show_stress_crisis(continue_action)
	else:
		_save_current_session()
		continue_action.call()


func _save_current_session() -> void:
	var save_error := save_service.save_game(session)
	if save_error != OK:
		notice_text = "自动存档失败：%s" % error_string(save_error)


func _complete_advance(consequences: Array[Dictionary], day_messages: Array[String]) -> void:
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


func show_stress_crisis(continue_action: Callable) -> void:
	_set_soundscape(_session_soundscape_context(), 0.35)
	var background_path := background_catalog.get_stress_background()
	var config := DifficultyRules.get_config(session.difficulty_id)
	var focus_target := "考试准备" if not bool(session.flags.get("exam_completed", false)) else "展示准备"
	var scene_context := {
		"display_name": "压力过载",
		"activity_text": "长曝光 · 感官失衡",
	}
	var choices: Array = [
		{
			"name": "StressRecover",
			"title": "停下来喝水，调整呼吸",
			"detail": "先让身体重新获得对当下的控制。",
			"effect": "压力 -%d · 精力 +3" % int(config.crisis_relief),
			"effect_color": "#63DDB8",
			"action": _resolve_stress_crisis.bind("recover", continue_action),
		},
		{
			"name": "StressFocus",
			"title": "趁思路还在，记下关键点",
			"detail": "继续推进，但会用更多精力和压力换取进度。",
			"effect": "%s +%d" % [focus_target, int(config.focus_gain)],
			"effect_color": "#F4C45E",
			"action": _resolve_stress_crisis.bind("focus", continue_action),
		},
		{
			"name": "StressSocial",
			"title": "给信任的人发消息",
			"detail": "至少一段关系达到 50 时，可以获得真实支持。",
			"effect": "压力 -%d" % int(config.social_relief),
			"effect_color": "#7CB9E8",
			"action": _resolve_stress_crisis.bind("social", continue_action),
			"disabled": _highest_relationship_id().is_empty(),
		},
	]
	var data := _base_scene_data(scene_context, background_path)
	data.merge({
		"panel_name": "StressCard",
		"section": "压力危机 · %s难度" % DifficultyRules.get_display_name(session.difficulty_id),
		"accent": "#FF8580",
		"title": "视线开始拉扯",
		"body": "压力已经达到 %d。灯光拖成了长线，耳边的声音忽远忽近。你必须先处理此刻的状态。" % int(session.stats.stress),
		"question": "现在怎样回应身体的警报？",
		"cost_text": "危机应对不额外耗时",
		"state_tags": [
			{"text": "压力过载", "color": "#FF8580"},
			{"text": "判断受影响", "color": "#F4C45E"},
			{"text": "必须回应", "color": "#7CB9E8"},
		],
		"choices": choices,
	}, true)
	_show_adaptive_scene("stress_crisis", data)
	if active_photo_background != null and not bool(settings.get("reduced_motion", false)):
		var disorient := active_photo_background.create_tween().set_loops()
		disorient.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		disorient.tween_property(active_photo_background, "modulate", Color("#FFC7D4"), 0.45)
		disorient.parallel().tween_property(active_photo_background, "position:x", active_photo_background.position.x - 5.0, 0.45)
		disorient.tween_property(active_photo_background, "modulate", Color.WHITE, 0.45)
		disorient.parallel().tween_property(active_photo_background, "position:x", active_photo_background.position.x, 0.45)


func _resolve_stress_crisis(response_id: String, continue_action: Callable) -> void:
	var config := DifficultyRules.get_config(session.difficulty_id)
	match response_id:
		"focus":
			var task_id := "exam" if not bool(session.flags.get("exam_completed", false)) else "presentation"
			session.change_task(task_id, int(config.focus_gain))
			session.change_stat("energy", -int(config.focus_energy_cost))
			session.change_stat("stress", int(config.focus_stress_gain))
			session.flags["pushed_through_stress"] = true
		"social":
			var npc_id := _highest_relationship_id()
			if not npc_id.is_empty():
				session.change_stat("stress", -int(config.social_relief))
				session.change_relationship(npc_id, 1)
				session.flags["sought_support_under_stress"] = true
		_:
			session.change_stat("stress", -int(config.crisis_relief))
			session.change_stat("energy", 3)
			session.flags["paused_under_stress"] = true
	session.clamp_all()
	_save_current_session()
	continue_action.call()


func _highest_relationship_id() -> String:
	var best_id := ""
	var best_value := 49
	for npc_id in session.relationships:
		var value := int(session.relationships[npc_id])
		if value > best_value:
			best_value = value
			best_id = str(npc_id)
	return best_id


func show_ai_advice(advice: Dictionary) -> void:
	var root := _reset_screen("ai_advice", Color("#1B3441"), "", Color("#07101388"))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(Color("#0B1518FA"), 22, COLOR_BLUE)
	panel.custom_minimum_size = Vector2(760, 460)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	var root := _reset_screen("pause", Color("#1B3337"), "", Color("#07101388"))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(Color("#0B1518FA"), 22, COLOR_ACCENT)
	panel.custom_minimum_size = Vector2(500, 470)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 13)
	panel.add_child(box)
	var title := _make_label("暂停 / PAUSED", 34, COLOR_INK)
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
	var root := _reset_screen("settings", Color("#1B343A"), "", Color("#07101388"))
	root.add_child(_make_header("设置", "声音、显示与辅助选项单独保存", _return_from_settings))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(COLOR_PANEL, 20, Color("#36545A"))
	panel.custom_minimum_size = Vector2(960, 510)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var intro := _make_label("AUDIO MIX / 声音混合", 13, COLOR_TEAL)
	box.add_child(intro)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 32)
	box.add_child(columns)
	var audio_box := VBoxContainer.new()
	audio_box.custom_minimum_size.x = 570
	audio_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	audio_box.add_theme_constant_override("separation", 11)
	columns.add_child(audio_box)
	var audio_controls := {}
	var audio_specs := [
		{"key": "master", "name": "MasterVolume", "label": "总音量", "bus": &"Master", "value": float(settings.get("master_volume", 0.8))},
		{"key": "music", "name": "MusicVolume", "label": "音乐", "bus": &"Music", "value": float(settings.get("music_volume", 0.65))},
		{"key": "sfx", "name": "SFXVolume", "label": "交互与事件", "bus": &"SFX", "value": float(settings.get("sfx_volume", 0.8))},
		{"key": "ambience", "name": "AmbienceVolume", "label": "校园环境", "bus": &"Ambience", "value": float(settings.get("ambience_volume", 0.65))},
	]
	for spec_value in audio_specs:
		var spec: Dictionary = spec_value
		var control := _make_volume_control(str(spec.label), str(spec.name), float(spec.value))
		audio_controls[spec.key] = control.slider
		control.slider.value_changed.connect(_preview_bus_volume.bind(StringName(spec.bus)))
		audio_box.add_child(control.root)

	var option_box := VBoxContainer.new()
	option_box.custom_minimum_size.x = 280
	option_box.add_theme_constant_override("separation", 12)
	columns.add_child(option_box)
	option_box.add_child(_make_label("DISPLAY & ACCESS / 显示与辅助", 13, COLOR_BLUE))

	var fullscreen := CheckButton.new()
	fullscreen.name = "Fullscreen"
	fullscreen.text = "全屏显示"
	fullscreen.button_pressed = bool(settings.get("fullscreen", false))
	fullscreen.custom_minimum_size.y = 48
	option_box.add_child(fullscreen)
	var reduced_motion := CheckButton.new()
	reduced_motion.name = "ReducedMotion"
	reduced_motion.text = "减少界面动效"
	reduced_motion.button_pressed = bool(settings.get("reduced_motion", false))
	reduced_motion.custom_minimum_size.y = 48
	option_box.add_child(reduced_motion)
	var pressure_audio := CheckButton.new()
	pressure_audio.name = "PressureAudio"
	pressure_audio.text = "启用压力状态音效"
	pressure_audio.button_pressed = bool(settings.get("pressure_audio", true))
	pressure_audio.custom_minimum_size.y = 48
	pressure_audio.toggled.connect(_preview_pressure_audio)
	option_box.add_child(pressure_audio)
	var preview := _make_button("试听确认音", func(): pass)
	preview.set_meta("audio_cue", &"confirm")
	option_box.add_child(preview)

	var note := _make_label("交互音效与校园声景均为原创程序化声音；本 Demo 不采集遥测数据，也不会上传设置或存档。", 13, COLOR_MUTED)
	box.add_child(note)
	box.add_child(_make_button("保存设置", _save_settings.bind(audio_controls, fullscreen, reduced_motion, pressure_audio), true))


func _save_settings(audio_controls: Dictionary, fullscreen: CheckButton, reduced_motion: CheckButton, pressure_audio: CheckButton) -> void:
	var master_slider := audio_controls.get("master") as HSlider
	var music_slider := audio_controls.get("music") as HSlider
	var sfx_slider := audio_controls.get("sfx") as HSlider
	var ambience_slider := audio_controls.get("ambience") as HSlider
	settings = {
		"master_volume": master_slider.value,
		"music_volume": music_slider.value,
		"sfx_volume": sfx_slider.value,
		"ambience_volume": ambience_slider.value,
		"pressure_audio": pressure_audio.button_pressed,
		"fullscreen": fullscreen.button_pressed,
		"reduced_motion": reduced_motion.button_pressed,
	}
	var error := save_service.save_settings(settings)
	_apply_settings()
	if error != OK:
		notice_text = "设置保存失败：%s" % error_string(error)
	_return_from_settings()


func _apply_settings() -> void:
	var audio_director := get_node_or_null("/root/ProjectUISoundController")
	if audio_director != null and audio_director.has_method("apply_mixer_settings"):
		audio_director.apply_mixer_settings(settings)
	else:
		_apply_fallback_bus_volume(&"Master", float(settings.get("master_volume", 0.8)))
		_apply_fallback_bus_volume(&"Music", float(settings.get("music_volume", 0.65)))
		_apply_fallback_bus_volume(&"SFX", float(settings.get("sfx_volume", 0.8)))
		_apply_fallback_bus_volume(&"Ambience", float(settings.get("ambience_volume", 0.65)))
	if not OS.has_feature("headless"):
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(settings.get("fullscreen", false)) else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(mode)


func _apply_fallback_bus_volume(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var level := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, level <= 0.0001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(level, 0.0001)))


func _preview_bus_volume(value: float, bus_name: StringName) -> void:
	_apply_fallback_bus_volume(bus_name, value)


func _preview_pressure_audio(enabled: bool) -> void:
	var bus_index := AudioServer.get_bus_index(&"Stress")
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, not enabled)


func _return_from_settings() -> void:
	_apply_settings()
	if settings_return_screen == "pause" and session != null:
		show_pause_menu()
	else:
		show_main_menu()


func show_credits() -> void:
	_set_soundscape(&"menu", 0.5, &"evening", 0)
	var root := _reset_screen("credits", Color("#1D3935"), "", Color("#07101388"))
	root.add_child(_make_header("制作与许可", "原创内容与第三方来源透明记录", show_main_menu))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(COLOR_PANEL, 20, Color("#36545A"))
	panel.custom_minimum_size = Vector2(900, 500)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	panel.add_child(box)
	box.add_child(_make_label("惊魂期末周 · CampusLifeSim", 28, COLOR_INK))
	var text := _make_label("参赛场景：山东大学中心校区 · 人工智能学院\n策划、程序与事件文本：CampusLifeSim 项目\n校园场景摄影：项目所有者提供的校园照片\n交互音效与校园声景：项目原创程序化生成\n\n引擎：Godot 4.7.1（MIT License）\n菜单、加载、暂停与音乐持久化基础参考：Maaack/Godot-Game-Template v1.4.7（MIT License）\n上游作者：Marek Belski\n\n本项目未使用山东大学校徽、Maaack 品牌 Logo、Godot Logo、Git Logo或来源不明的第三方美术。完整许可证、学校信息来源与素材记录随项目分发。", 17, COLOR_MUTED)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(text)
	box.add_child(_make_button("返回", show_main_menu, true))


func show_exit_confirmation() -> void:
	var root := _reset_screen("exit_confirm", Color("#26383B"), "", Color("#07101388"))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(Color("#0B1518FA"), 20, COLOR_CORAL)
	panel.custom_minimum_size = Vector2(520, 300)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	box.add_child(_make_button("退出", _quit_game, false, true))


func _quit_game() -> void:
	var audio_director := get_node_or_null("/root/ProjectUISoundController")
	var ambient_controller := get_node_or_null("/root/ProjectAmbientSoundController")
	if audio_director != null and audio_director.has_method("play_cue"):
		audio_director.play_cue(&"danger", true)
	await get_tree().create_timer(0.17).timeout
	if audio_director != null and audio_director.has_method("prepare_for_shutdown"):
		audio_director.prepare_for_shutdown()
	if ambient_controller != null and ambient_controller.has_method("prepare_for_shutdown"):
		ambient_controller.prepare_for_shutdown()
	await get_tree().process_frame
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()


func show_ending() -> void:
	_set_soundscape(&"menu", 0.9, &"evening")
	var ending := EndingEvaluator.new().evaluate(session, repository.endings)
	var ending_color := Color(str(ending.get("color", "#E0B14C")))
	var root := _reset_screen("ending", ending_color.darkened(0.65), "", Color("#07101388"))
	var heading := HBoxContainer.new()
	root.add_child(heading)
	heading.add_child(_make_badge("FINAL REPORT / 期末周结算", ending_color))
	var heading_space := Control.new()
	heading_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_space)
	heading.add_child(_make_label("7 DAYS COMPLETE", 11, Color("#71837F")))
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var panel := _make_panel(Color("#0B1518FA"), 24, ending_color)
	panel.custom_minimum_size = Vector2(1120, 570)
	center.add_child(panel)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 34)
	panel.add_child(columns)
	var narrative := VBoxContainer.new()
	narrative.custom_minimum_size.x = 670
	narrative.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	narrative.add_theme_constant_override("separation", 15)
	columns.add_child(narrative)
	narrative.add_child(_make_label("你的期末周结局", 14, ending_color))
	var title := _make_label(str(ending.get("title", "结局")), 52, COLOR_INK)
	narrative.add_child(title)
	var tagline := _make_label(str(ending.get("tagline", "")), 20, COLOR_ACCENT)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narrative.add_child(tagline)
	var description := _make_label(str(ending.get("description", "")), 18, COLOR_MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.y = 120
	narrative.add_child(description)
	var narrative_space := Control.new()
	narrative_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	narrative.add_child(narrative_space)
	var reveal := _make_label("难度：%s   ·   眩晕危机：%d 次\nAI 依赖度：%d   ·   平均关系：%d   ·   经历事件：%d" % [DifficultyRules.get_display_name(session.difficulty_id), int(session.flags.get("stress_crisis_count", 0)), int(session.stats.ai_dependence), int(session.average_relationship()), session.event_history.size()], 13, COLOR_MUTED)
	reveal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narrative.add_child(reveal)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	narrative.add_child(buttons)
	var again := _make_button("再玩一次", _restart_game, true)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(again)
	var menu := _make_button("返回主菜单", show_main_menu)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(menu)

	var report := VBoxContainer.new()
	report.custom_minimum_size.x = 340
	report.add_theme_constant_override("separation", 12)
	columns.add_child(report)
	report.add_child(_make_label("WEEK SUMMARY", 13, Color("#71837F")))
	var summary := GridContainer.new()
	summary.columns = 2
	summary.add_theme_constant_override("h_separation", 10)
	summary.add_theme_constant_override("v_separation", 10)
	report.add_child(summary)
	summary.add_child(_make_summary_cell("学习", int(session.stats.study), COLOR_TEAL))
	summary.add_child(_make_summary_cell("项目", int(session.stats.project), COLOR_BLUE))
	summary.add_child(_make_summary_cell("精力", int(session.stats.energy), COLOR_ACCENT))
	summary.add_child(_make_summary_cell("压力", int(session.stats.stress), COLOR_CORAL))
	report.add_child(_make_separator())
	var reflection := _make_label("没有唯一最优路线。\n这份报告记录的是你如何在有限时间里取舍、求助、核验并继续前进。\n\n学无止境，气有浩然。", 14, COLOR_MUTED)
	reflection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reflection.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report.add_child(reflection)


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
	box.add_child(_make_button("退出", _quit_game, false, true))


func _make_header(title_text: String, subtitle_text: String, back_action: Callable) -> Control:
	var panel := _make_panel(Color("#0B1518F5"), 16, Color("#36545A"))
	panel.custom_minimum_size.y = 72
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var back_button := _make_button("← 返回", back_action, false, false, 110)
	back_button.set_meta("audio_cue", &"back")
	row.add_child(back_button)
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
	var color := Color("#142326")
	var border := Color("#36545A")
	if accent:
		color = Color("#245E50")
		border = COLOR_TEAL
	elif danger:
		color = Color("#522D33")
		border = COLOR_CORAL
	_style_button(button, color, border)
	button.set_meta("audio_cue", &"danger" if danger else (&"confirm" if accent else &"press"))
	button.pressed.connect(action)
	return button


func _make_volume_control(label_text: String, node_name: String, value: float) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := _make_label(label_text, 16, COLOR_INK)
	label.custom_minimum_size.x = 128
	row.add_child(label)
	var slider := HSlider.new()
	slider.name = node_name
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = clampf(value, 0.0, 1.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = 40
	row.add_child(slider)
	var value_label := _make_label("%d%%" % int(slider.value * 100.0), 15, COLOR_MUTED)
	value_label.custom_minimum_size.x = 58
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	slider.value_changed.connect(func(new_value: float): value_label.text = "%d%%" % int(new_value * 100.0))
	return {"root": row, "slider": slider}


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
	style.bg_color = Color("#091517F2")
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color("#36545A")
	style.content_margin_left = 14
	style.content_margin_right = 14
	line_edit.add_theme_stylebox_override("normal", style)
	line_edit.add_theme_stylebox_override("focus", style)
	line_edit.add_theme_color_override("font_color", COLOR_INK)
	line_edit.add_theme_color_override("font_placeholder_color", Color("#718B88"))


func _make_separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.modulate = Color("#49606466")
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
