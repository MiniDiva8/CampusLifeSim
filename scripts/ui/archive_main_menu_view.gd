extends Control
class_name ArchiveMainMenuView

const PAPER := Color("#E9E0CD")
const PAPER_LIGHT := Color("#F6F0E3")
const PAPER_DARK := Color("#CFC2AA")
const INK := Color("#29332E")
const MUTED := Color("#6C756E")
const SDU_RED := Color("#9E2A2F")
const GOLD := Color("#A87932")

var data: Dictionary = {}
var photo_rect: OrientedPhotoRect


func configure(view_data: Dictionary) -> void:
	data = view_data
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_title()
	_build_archive_index()
	_build_photo_attachment()
	_build_primary_seal()
	_build_footer()
	queue_redraw()
	if not bool(data.get("reduced_motion", false)):
		modulate.a = 0.0
		position.y = 7.0
		var entrance := create_tween().set_parallel(true)
		entrance.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		entrance.tween_property(self, "position:y", 0.0, 0.25)
		entrance.tween_property(self, "modulate:a", 1.0, 0.20)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER, true)
	draw_rect(Rect2(0, 0, size.x, 26), Color("#D6CAB3"), true)
	draw_rect(Rect2(0, 26, size.x, 3), Color("#B9A98D70"), true)
	_draw_paper_texture()
	_draw_handling_marks()
	_draw_archive_rules()
	_draw_photo_markup()


func _draw_paper_texture() -> void:
	for index in 24:
		var y := 38.0 + float(index) * 28.0
		draw_line(Vector2(0, y), Vector2(size.x, y + 4.0), Color("#FFFFFF", 0.045), 1.0)
	for index in 15:
		var x := 24.0 + float(index) * 91.0
		draw_line(Vector2(x, 28), Vector2(x - 46.0, size.y), Color(INK, 0.022), 1.0)
	draw_rect(Rect2(622, 28, 2, 664), Color("#8E826D20"), true)
	draw_line(Vector2(620, 31), Vector2(614, 689), Color("#FFFFFF4A"), 1.0)


func _draw_handling_marks() -> void:
	draw_arc(Vector2(87, 664), 148, -1.6, -0.18, 40, Color("#6F604C18"), 2.0)
	draw_arc(Vector2(83, 659), 140, -1.58, -0.2, 40, Color("#FFFFFF34"), 1.0)
	draw_line(Vector2(238, 28), Vector2(238, 688), Color("#766C5B13"), 2.0)
	draw_line(Vector2(244, 28), Vector2(246, 688), Color("#FFFFFF30"), 1.0)
	var fold := PackedVector2Array([
		Vector2(size.x - 74, size.y),
		Vector2(size.x, size.y - 71),
		Vector2(size.x, size.y),
	])
	draw_colored_polygon(fold, Color("#D2C6B0"))
	draw_line(Vector2(size.x - 74, size.y), Vector2(size.x, size.y - 71), Color("#A99C8680"), 1.0)


func _draw_archive_rules() -> void:
	draw_line(Vector2(58, 105), Vector2(573, 105), Color(SDU_RED, 0.76), 2.0)
	draw_line(Vector2(58, 257), Vector2(573, 257), Color(INK, 0.25), 1.0)
	draw_line(Vector2(58, 608), Vector2(573, 608), Color(INK, 0.25), 1.0)
	for row in 5:
		var y := 303.0 + float(row) * 58.0
		draw_line(Vector2(74, y + 50), Vector2(559, y + 50), Color(INK, 0.14), 1.0)
	draw_rect(Rect2(447, 52, 121, 36), Color.TRANSPARENT, false, 2.0, false)


func _draw_photo_markup() -> void:
	var photo_origin := Vector2(662, 66)
	draw_rect(Rect2(photo_origin + Vector2(-8, -9), Vector2(584, 488)), Color("#3B302521"), true)
	draw_rect(Rect2(907, 50, 74, 26), Color("#C7AD79A8"), true)
	draw_line(Vector2(908, 63), Vector2(979, 63), Color("#FFFFFF43"), 1.0)


func _build_title() -> void:
	var eyebrow := _make_label("SDU / FINAL WEEK ARCHIVE", 13, SDU_RED)
	eyebrow.position = Vector2(60, 52)
	eyebrow.size = Vector2(320, 28)
	add_child(eyebrow)
	var day_stamp := _make_label("第 0 日 / 入档前", 14, SDU_RED)
	day_stamp.name = "ArchiveDayStamp"
	day_stamp.position = Vector2(456, 55)
	day_stamp.size = Vector2(108, 30)
	day_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(day_stamp)

	var title := _make_label("惊魂期末周", 56, INK)
	title.position = Vector2(55, 116)
	title.size = Vector2(540, 75)
	add_child(title)

	var subtitle := _make_label("一份等待启封的七日记录", 21, INK)
	subtitle.position = Vector2(60, 191)
	subtitle.size = Vector2(460, 34)
	add_child(subtitle)

	var note := _make_label("考试、项目、关系与身体状态都将写入档案。\n没有标准答案，只有被你留下的选择痕迹。", 14, MUTED)
	note.position = Vector2(60, 224)
	note.size = Vector2(505, 58)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(note)

	var notice := str(data.get("notice_text", ""))
	if not notice.is_empty():
		var notice_label := _make_label(notice, 12, SDU_RED)
		notice_label.position = Vector2(60, 280)
		notice_label.size = Vector2(505, 25)
		add_child(notice_label)


func _build_archive_index() -> void:
	var entries := [
		{
			"name": "ArchiveNew",
			"index": "01",
			"title": "新建期末周档案",
			"status": "登记名字、路线与难度",
			"action": data.get("new_action", Callable()),
			"disabled": false,
		},
		{
			"name": "ArchiveContinue",
			"index": "02",
			"title": "调取最近进度",
			"status": str(data.get("continue_status", "尚无可读取的记录")),
			"action": data.get("continue_action", Callable()),
			"disabled": not bool(data.get("has_save", false)),
		},
		{
			"name": "ArchiveSettings",
			"index": "03",
			"title": "档案室设置",
			"status": "声音、显示与辅助选项",
			"action": data.get("settings_action", Callable()),
			"disabled": false,
		},
		{
			"name": "ArchiveCredits",
			"index": "04",
			"title": "制作与许可",
			"status": "来源、署名与离线说明",
			"action": data.get("credits_action", Callable()),
			"disabled": false,
		},
		{
			"name": "ArchiveExit",
			"index": "05",
			"title": "封存并退出",
			"status": "关闭当前档案室",
			"action": data.get("exit_action", Callable()),
			"disabled": false,
		},
	]
	for entry_index in entries.size():
		var entry: Dictionary = entries[entry_index]
		var button := Button.new()
		button.name = str(entry.name)
		button.text = ""
		button.position = Vector2(67, 305 + entry_index * 58)
		button.size = Vector2(498, 52)
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.disabled = bool(entry.disabled)
		button.tooltip_text = "%s · %s" % [entry.title, entry.status]
		button.set_meta("audio_cue", &"back" if entry.name == "ArchiveExit" else &"press")
		_style_index_button(button)
		var action: Callable = entry.action
		if action.is_valid():
			button.pressed.connect(action)
		add_child(button)

		var number_label := _make_label(str(entry.index), 12, SDU_RED if not button.disabled else Color(MUTED, 0.55))
		number_label.position = Vector2(13, 7)
		number_label.size = Vector2(35, 22)
		number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(number_label)
		var title_label := _make_label(str(entry.title), 17, INK if not button.disabled else Color(MUTED, 0.58))
		title_label.position = Vector2(56, 4)
		title_label.size = Vector2(235, 27)
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(title_label)
		var status_label := _make_label(str(entry.status), 12, MUTED if not button.disabled else Color(MUTED, 0.48))
		status_label.position = Vector2(300, 7)
		status_label.size = Vector2(178, 22)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(status_label)
		var arrow := _make_label("→", 17, SDU_RED if not button.disabled else Color(MUTED, 0.38))
		arrow.position = Vector2(462, 25)
		arrow.size = Vector2(25, 22)
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(arrow)


func _build_photo_attachment() -> void:
	var frame := PanelContainer.new()
	frame.name = "ArchivePhotoAttachment"
	frame.position = Vector2(662, 66)
	frame.size = Vector2(568, 470)
	frame.add_theme_stylebox_override("panel", _photo_frame_style())
	add_child(frame)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 50)
	frame.add_child(margin)

	var holder := Control.new()
	holder.clip_contents = true
	margin.add_child(holder)
	var texture := data.get("photo_texture") as Texture2D
	if texture != null:
		photo_rect = OrientedPhotoRect.new()
		photo_rect.name = "ArchivePhoto"
		photo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(photo_rect)
		photo_rect.configure(texture, int(data.get("photo_orientation", 1)), false)

	var caption := _make_label("附图 01 · 中心校区 / 记录地点待确认", 12, MUTED)
	caption.position = Vector2(682, 497)
	caption.size = Vector2(500, 24)
	add_child(caption)
	_build_photo_markup_overlay()


func _build_photo_markup_overlay() -> void:
	var circle := Line2D.new()
	circle.name = "ArchivePhotoCircle"
	circle.default_color = Color(SDU_RED, 0.90)
	circle.width = 3.0
	circle.antialiased = true
	circle.closed = true
	for index in 49:
		var angle := TAU * float(index) / 48.0
		circle.add_point(Vector2(941, 285) + Vector2(cos(angle), sin(angle)) * 48.0)
	add_child(circle)

	var leader := Line2D.new()
	leader.default_color = Color(SDU_RED, 0.82)
	leader.width = 2.0
	leader.antialiased = true
	leader.points = PackedVector2Array([Vector2(977, 318), Vector2(1128, 403)])
	add_child(leader)
	var marker := _make_pin(Vector2(1124, 399), 8, SDU_RED)
	add_child(marker)
	var annotation := _make_label("期末周入口", 14, SDU_RED)
	annotation.position = Vector2(1057, 409)
	annotation.size = Vector2(145, 24)
	annotation.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(annotation)

	var left_pin := _make_pin(Vector2(674, 69), 14, Color("#8B2329"))
	left_pin.name = "ArchivePhotoPinLeft"
	add_child(left_pin)
	var right_pin := _make_pin(Vector2(1203, 69), 14, Color("#8B2329"))
	right_pin.name = "ArchivePhotoPinRight"
	add_child(right_pin)


func _make_pin(position_value: Vector2, diameter: int, color: Color) -> PanelContainer:
	var pin := PanelContainer.new()
	pin.position = position_value
	pin.size = Vector2(diameter, diameter)
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.28)
	style.set_border_width_all(2)
	style.set_corner_radius_all(diameter / 2)
	style.shadow_color = Color("#3C1A1838")
	style.shadow_size = 3
	style.shadow_offset = Vector2(2, 3)
	pin.add_theme_stylebox_override("panel", style)
	return pin


func _build_primary_seal() -> void:
	var button := Button.new()
	button.name = "ArchiveSeal"
	button.text = "启封档案  ·  开始第 1 天    →"
	button.position = Vector2(830, 575)
	button.size = Vector2(380, 74)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", PAPER_LIGHT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _seal_style(SDU_RED, Color("#6D181E"), 4))
	button.add_theme_stylebox_override("hover", _seal_style(SDU_RED.lightened(0.10), SDU_RED.darkened(0.25), 8))
	button.add_theme_stylebox_override("pressed", _seal_style(SDU_RED.darkened(0.08), Color("#571218"), 2))
	button.add_theme_stylebox_override("focus", _seal_style(SDU_RED.lightened(0.10), GOLD, 8))
	button.set_meta("audio_cue", &"confirm")
	var action: Callable = data.get("new_action", Callable())
	if action.is_valid():
		button.pressed.connect(action)
	add_child(button)

	var hint := _make_label("自动保存将在每次选择后写入本地", 11, MUTED)
	hint.position = Vector2(856, 654)
	hint.size = Vector2(328, 22)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)


func _build_footer() -> void:
	var left := _make_label("档号  SDU · AI · 1901", 11, SDU_RED)
	left.position = Vector2(58, 681)
	left.size = Vector2(260, 22)
	add_child(left)
	var right := _make_label("离线运行  /  原图保留  /  七天五时段", 11, MUTED)
	right.position = Vector2(830, 681)
	right.size = Vector2(380, 22)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(right)


func _style_index_button(button: Button) -> void:
	var normal := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#FFFDF4A8")
	hover.border_color = Color(SDU_RED, 0.55)
	hover.border_width_left = 3
	hover.content_margin_left = 4
	var pressed := hover.duplicate()
	pressed.bg_color = Color("#DCCFB9A0")
	var disabled := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)


func _photo_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER_LIGHT
	style.border_color = Color("#92866F")
	style.set_border_width_all(1)
	style.shadow_color = Color("#3D33252A")
	style.shadow_size = 9
	style.shadow_offset = Vector2(5, 7)
	return style


func _seal_style(color: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.shadow_color = Color("#4B241D35")
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(3, 4)
	return style


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label
