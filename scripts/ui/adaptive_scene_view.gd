class_name AdaptiveSceneView
extends Control

const GlassPanelScript = preload("res://scripts/ui/glass_panel.gd")
const GlassHoverControllerScript = preload("res://scripts/ui/glass_hover_controller.gd")
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
const SDU_RED := Color("#B84850")

var photo_rect: OrientedPhotoRect
var photo_stage: PanelContainer
var interaction_panel: PanelContainer
var _reduced_motion := false


func configure(data: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reduced_motion = bool(data.get("reduced_motion", false))
	_build_background()
	_build_hud(data)
	var media_width := _recommended_media_width(data)
	var media_position := Vector2(24, 84)
	var media_size := Vector2(media_width, 612)
	var content_position := Vector2(42 + media_width, 84)
	var content_size := Vector2(1238 - content_position.x, 612)
	_build_photo_stage(data, media_position, media_size)
	_build_interaction_panel(data, content_position, content_size)
	_animate_entrance()


func _recommended_media_width(data: Dictionary) -> float:
	if data.has("media_width"):
		return clampf(float(data.media_width), 450.0, 720.0)
	var image_path := str(data.get("image_path", ""))
	if image_path.is_empty() or not ResourceLoader.exists(image_path):
		return 560.0
	var image_texture := data.get("image_texture") as Texture2D
	if image_texture == null:
		image_texture = load(image_path) as Texture2D
	if image_texture == null:
		return 560.0
	var image_size := image_texture.get_size()
	if int(data.get("orientation", 1)) in [6, 8]:
		image_size = Vector2(image_size.y, image_size.x)
	var aspect := image_size.x / maxf(image_size.y, 1.0)
	if aspect < 0.86:
		return 474.0
	if aspect > 1.45:
		return 704.0
	return 652.0


func _build_background() -> void:
	var base := ColorRect.new()
	base.color = BACKGROUND
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)

	var upper_glow := ColorRect.new()
	upper_glow.color = Color("#3E1D224A")
	upper_glow.position = Vector2(0, 0)
	upper_glow.size = Vector2(1280, 190)
	upper_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(upper_glow)

	var rule := ColorRect.new()
	rule.color = Color("#B8485038")
	rule.position = Vector2(24, 74)
	rule.size = Vector2(1232, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)


func _build_hud(data: Dictionary) -> void:
	var hud := _glass_surface(Color("#0D191C"), Color("#527B80A0"), 13, 2.2, Vector4(12, 8, 12, 8))
	hud.name = "SceneHUD"
	hud.position = Vector2(24, 16)
	hud.size = Vector2(1232, 48)
	add_child(hud)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	hud.add_child(row)

	var brand := VBoxContainer.new()
	brand.custom_minimum_size.x = 222
	brand.add_theme_constant_override("separation", -2)
	row.add_child(brand)
	brand.add_child(_label("惊魂期末周", 18, INK))
	brand.add_child(_label("SDU · CENTER CAMPUS · AI", 9, SDU_RED))

	row.add_child(_divider())
	row.add_child(_compact_pair("日期", str(data.get("time", "第 1 天 · 清晨")), TEAL, 178))
	row.add_child(_compact_pair("地点", str(data.get("scene_name", "校园场景")), BLUE, 180))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	row.add_child(_stat_chip("精力", int(data.get("energy", 80)), TEAL))
	row.add_child(_stat_chip("压力", int(data.get("stress", 20)), CORAL))
	row.add_child(_stat_chip("考试", int(data.get("exam", 0)), GOLD))

	var pause_action = data.get("pause_action")
	if pause_action is Callable and not pause_action.is_null():
		var pause_button := Button.new()
		pause_button.name = "ScenePause"
		pause_button.text = "暂停"
		pause_button.custom_minimum_size = Vector2(62, 34)
		pause_button.add_theme_font_size_override("font_size", 11)
		pause_button.add_theme_stylebox_override("normal", _style(Color("#142326"), 9, Color("#36545A"), 1, 8))
		var pause_hover := _style(Color("#20383CDD"), 9, TEAL, 1, 8)
		pause_hover.shadow_color = Color(TEAL, 0.16)
		pause_hover.shadow_size = 7
		pause_button.add_theme_stylebox_override("hover", pause_hover)
		pause_button.add_theme_stylebox_override("pressed", _style(Color("#0B1518"), 9, GOLD, 1, 8))
		pause_button.add_theme_color_override("font_color", MUTED)
		pause_button.set_meta("audio_cue", &"press")
		pause_button.pressed.connect(pause_action)
		_attach_hover(pause_button, TEAL, 1.025, 0.12)
		row.add_child(pause_button)


func _build_photo_stage(data: Dictionary, stage_position: Vector2, stage_size: Vector2) -> void:
	photo_stage = PanelContainer.new()
	photo_stage.name = "PhotoStage"
	photo_stage.position = stage_position
	photo_stage.size = stage_size
	var stage_style := _style(Color("#071013F2"), 18, Color("#52757A"), 1, 8)
	stage_style.shadow_color = Color("#00000070")
	stage_style.shadow_size = 14
	stage_style.shadow_offset = Vector2(0, 7)
	photo_stage.add_theme_stylebox_override("panel", stage_style)
	add_child(photo_stage)

	var media := Control.new()
	media.clip_contents = true
	photo_stage.add_child(media)

	var image_backdrop := ColorRect.new()
	image_backdrop.color = Color("#10191B")
	image_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	media.add_child(image_backdrop)

	photo_rect = OrientedPhotoRect.new()
	photo_rect.name = "PhotoFrame"
	var image_path := str(data.get("image_path", ""))
	var image_texture := data.get("image_texture") as Texture2D
	if image_texture == null and not image_path.is_empty() and ResourceLoader.exists(image_path):
		image_texture = load(image_path) as Texture2D
	photo_rect.configure(image_texture, int(data.get("orientation", 1)), false)
	photo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	media.add_child(photo_rect)

	var caption := _glass_surface(Color("#081113"), Color("#79A39F88"), 12, 2.0, Vector4(14, 10, 14, 10))
	caption.name = "PhotoCaption"
	caption.position = Vector2(14, stage_size.y - 82)
	caption.size = Vector2(stage_size.x - 28, 66)
	media.add_child(caption)
	var caption_row := HBoxContainer.new()
	caption_row.add_theme_constant_override("separation", 10)
	caption.add_child(caption_row)
	var caption_copy := VBoxContainer.new()
	caption_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption_copy.add_theme_constant_override("separation", 0)
	caption_row.add_child(caption_copy)
	caption_copy.add_child(_label(str(data.get("scene_name", "校园场景")), 19, INK))
	caption_copy.add_child(_label(str(data.get("activity", "安排当前时段")), 12, MUTED))


func _build_interaction_panel(data: Dictionary, panel_position: Vector2, panel_size: Vector2) -> void:
	var accent := Color(str(data.get("accent", "#63DDB8")))
	interaction_panel = _glass_surface(Color("#0B171A"), Color(accent, 0.68), 18, 3.0, Vector4(22, 18, 22, 18))
	interaction_panel.name = str(data.get("panel_name", "InteractionPanel"))
	interaction_panel.position = panel_position
	interaction_panel.size = panel_size
	add_child(interaction_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	interaction_panel.add_child(content)

	var eyebrow_row := HBoxContainer.new()
	content.add_child(eyebrow_row)
	eyebrow_row.add_child(_badge(str(data.get("section", "校园事件")), accent))
	var eyebrow_spacer := Control.new()
	eyebrow_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eyebrow_row.add_child(eyebrow_spacer)
	eyebrow_row.add_child(_label(str(data.get("cost_text", "选择后推进 1 个时段")), 11, Color("#7D908D")))

	var title := _label(str(data.get("title", "这个时段要怎么安排？")), int(data.get("title_size", 30)), INK)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.y = 40
	content.add_child(title)

	var body := _label(str(data.get("body", "")), 15, MUTED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = float(data.get("body_height", 58))
	content.add_child(body)

	var state_row := HBoxContainer.new()
	state_row.add_theme_constant_override("separation", 7)
	content.add_child(state_row)
	for state_value in data.get("state_tags", []):
		var state: Dictionary = state_value
		state_row.add_child(_badge(str(state.get("text", "状态")), Color(str(state.get("color", "#7CB9E8")))))

	var separator := HSeparator.new()
	separator.modulate = Color("#49606466")
	separator.custom_minimum_size.y = 4
	content.add_child(separator)

	var question := HBoxContainer.new()
	content.add_child(question)
	var question_label := _label(str(data.get("question", "你准备怎么做？")), 15, INK)
	question_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question.add_child(question_label)
	question.add_child(_label("%d 个选择" % data.get("choices", []).size(), 11, Color("#728681")))

	var choice_scroll := ScrollContainer.new()
	choice_scroll.name = "ChoiceScroll"
	choice_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(choice_scroll)
	var choices := VBoxContainer.new()
	choices.name = "ChoiceList"
	choices.add_theme_constant_override("separation", 9)
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_scroll.add_child(choices)
	var choice_index := 1
	for choice_value in data.get("choices", []):
		choices.add_child(_choice_card(choice_index, choice_value, accent))
		choice_index += 1

	var footer := HBoxContainer.new()
	content.add_child(footer)
	footer.add_child(_label("●  自动存档开启", 10, Color("#5D8C80")))
	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)
	footer.add_child(_label(str(data.get("footer_hint", "ESC  暂停")), 10, Color("#61736F")))


func _choice_card(index: int, choice_value, accent: Color) -> Button:
	var choice: Dictionary = choice_value
	var button := Button.new()
	button.name = str(choice.get("name", "Choice_%02d" % index))
	button.custom_minimum_size.y = float(choice.get("height", 76))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal_style := _style(Color("#102024C4"), 12, Color(accent, 0.42), 1, 12)
	normal_style.shadow_color = Color("#00000040")
	normal_style.shadow_size = 4
	normal_style.shadow_offset = Vector2(0, 2)
	var hover_style := _style(Color("#173338E0"), 12, accent.lightened(0.12), 1, 12)
	hover_style.shadow_color = Color(accent, 0.20)
	hover_style.shadow_size = 12
	hover_style.shadow_offset = Vector2(0, 5)
	var pressed_style := _style(Color("#0C1719ED"), 12, GOLD, 1, 12)
	pressed_style.shadow_color = Color(GOLD, 0.14)
	pressed_style.shadow_size = 5
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("disabled", _style(Color("#111C1E"), 12, Color("#2D3B3D"), 1, 12))
	button.disabled = bool(choice.get("disabled", false))
	button.set_meta("audio_cue", &"choice")

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 11)
	button.add_child(row)

	var number := _label("%02d" % index, 13, accent)
	number.custom_minimum_size.x = 27
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(number)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var title := _label(str(choice.get("title", "选择")), 16, INK)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title)
	var detail := _label(str(choice.get("detail", "")), 11, MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(detail)

	var effect := _badge(str(choice.get("effect", "查看后果")), Color(str(choice.get("effect_color", "#7CB9E8"))))
	effect.custom_minimum_size.x = float(choice.get("effect_width", 112))
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(effect)
	for child in effect.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var action = choice.get("action")
	if action is Callable and not action.is_null():
		button.pressed.connect(action)
	_attach_hover(button, accent, 1.012, 0.13)
	return button


func _glass_surface(tint: Color, accent: Color, radius: int, blur_lod: float, padding: Vector4) -> PanelContainer:
	var panel = GlassPanelScript.new()
	panel.configure(tint, accent, radius, blur_lod, 0.76, padding)
	return panel


func _attach_hover(control: Control, accent: Color, scale_amount: float, light_strength: float) -> void:
	var controller = GlassHoverControllerScript.new()
	controller.name = "GlassHoverController"
	controller.configure(accent, scale_amount, _reduced_motion, light_strength)
	control.add_child(controller)


func _animate_entrance() -> void:
	if _reduced_motion or photo_stage == null or interaction_panel == null:
		return
	var photo_rest := photo_stage.position
	var panel_rest := interaction_panel.position
	photo_stage.position.x -= 12.0
	interaction_panel.position.x += 14.0
	photo_stage.modulate.a = 0.0
	interaction_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(photo_stage, "position", photo_rest, 0.24)
	tween.tween_property(photo_stage, "modulate:a", 1.0, 0.20)
	tween.tween_property(interaction_panel, "position", panel_rest, 0.26).set_delay(0.035)
	tween.tween_property(interaction_panel, "modulate:a", 1.0, 0.22).set_delay(0.035)


func _compact_pair(key: String, value: String, accent: Color, width: float) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = width
	box.add_theme_constant_override("separation", -1)
	box.add_child(_label(key, 9, Color("#657975")))
	box.add_child(_label(value, 14, accent))
	return box


func _stat_chip(title: String, value: int, accent: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(88, 34)
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
