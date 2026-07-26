class_name EditorialEventView
extends Control
## THESIS: The campus photograph is the event canvas; no dashboard, split cards, or boxed choices.
## OWN-WORLD: Stone paper, mist blue, graphite type, and one SDU-red annotation system.
## STORY: Recognize the real place, understand the event, then compare consequential actions.
## FIRST VIEWPORT: Full original photo, lower-left narrative, right-hand borderless choice index.
## FORM: Campus documentary editorial, composition A with the brighter material range of B.

const PAPER := Color("#E9E6DC")
const PAPER_LIGHT := Color("#F4F1E8")
const GRAPHITE := Color("#252A2B")
const GRAPHITE_SOFT := Color("#515B5C")
const GRAPHITE_FAINT := Color("#6F7878")
const RULE := Color("#4D5A5A5C")
const SDU_RED := Color("#B84850")
const MIST_BLUE := Color("#527C8A")
const ENERGY := Color("#287C68")
const STRESS := Color("#A94F54")
const EXAM := Color("#9A6A18")

var photo_rect: OrientedPhotoRect
var _reduced_motion := false
var _narrative: Control
var _choice_region: Control
var _interaction_status: Label
var _photo_stage: Control
var _layout: Dictionary = {}
var _layout_mode := "cinematic"


func configure(data: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reduced_motion = bool(data.get("reduced_motion", false))
	_layout = _resolve_layout(data)
	_layout_mode = str(_layout.get("mode", "cinematic"))
	set_meta("photo_layout_mode", _layout_mode)
	set_meta("photo_side", str(_layout.get("side", "left")))
	_build_canvas(data)
	_build_top_margin(data)
	_build_narrative(data)
	_build_choices(data)
	_build_day_line(data)
	_animate_entrance()


func show_pending(message: String) -> void:
	if _interaction_status == null:
		return
	_interaction_status.name = "InteractionPending"
	_interaction_status.text = "—  %s" % message
	_interaction_status.add_theme_color_override("font_color", SDU_RED)


func _build_canvas(data: Dictionary) -> void:
	var paper := ColorRect.new()
	paper.name = "EditorialPaper"
	paper.color = PAPER
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)

	var stage_rect: Rect2 = _layout.get("photo_rect", Rect2(0, 0, 1280, 720))
	if _layout_mode != "cinematic":
		var mount := Panel.new()
		mount.name = "PhotoMount"
		mount.position = stage_rect.position - Vector2(1, 1)
		mount.size = stage_rect.size + Vector2(2, 2)
		mount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mount_style := StyleBoxFlat.new()
		mount_style.bg_color = PAPER_LIGHT
		mount_style.border_color = Color("#6F787852")
		mount_style.set_border_width_all(1)
		mount.add_theme_stylebox_override("panel", mount_style)
		add_child(mount)

	_photo_stage = Control.new()
	_photo_stage.name = "PhotoStage"
	_photo_stage.position = stage_rect.position
	_photo_stage.size = stage_rect.size
	_photo_stage.clip_contents = true
	_photo_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_photo_stage)

	photo_rect = OrientedPhotoRect.new()
	photo_rect.name = "PhotoFrame"
	var image_path := str(data.get("image_path", ""))
	var image_texture := data.get("image_texture") as Texture2D
	if image_texture == null and not image_path.is_empty() and ResourceLoader.exists(image_path):
		image_texture = load(image_path) as Texture2D
	photo_rect.configure(image_texture, int(data.get("orientation", 1)), false)
	photo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_photo_stage.add_child(photo_rect)

	if _layout_mode == "cinematic":
		var left_veil := _gradient_veil([
			Color(PAPER_LIGHT, 0.98),
			Color(PAPER, 0.78),
			Color(PAPER, 0.16),
			Color(PAPER, 0.0),
		])
		left_veil.position = Vector2(0, 0)
		left_veil.size = Vector2(440, 720)
		add_child(left_veil)
		add_child(_localized_choice_veil())
	else:
		var caption := _label(
			"%s  /  %s" % [
				str(data.get("photo_shape", "原图完整比例")),
				str(data.get("scene_name", "校园场景")),
			],
			11,
			MIST_BLUE
		)
		caption.name = "PhotoPresentationLabel"
		caption.position = Vector2(stage_rect.position.x, stage_rect.end.y + 7)
		caption.size = Vector2(stage_rect.size.x, 20)
		caption.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_RIGHT
			if str(_layout.get("side", "left")) == "right"
			else HORIZONTAL_ALIGNMENT_LEFT
		)
		add_child(caption)

	var top_wash := ColorRect.new()
	top_wash.color = Color("#F4F1E8B8") if _layout_mode != "cinematic" else Color("#F4F1E866")
	top_wash.position = Vector2(0, 0)
	top_wash.size = Vector2(1280, 76)
	top_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_wash)


func _build_top_margin(data: Dictionary) -> void:
	var top_rule := ColorRect.new()
	top_rule.color = Color("#3F4B4B42")
	top_rule.position = Vector2(40, 74)
	top_rule.size = Vector2(1200, 1)
	top_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_rule)

	var time_marker := ColorRect.new()
	time_marker.color = SDU_RED
	time_marker.position = Vector2(40, 26)
	time_marker.size = Vector2(3, 26)
	time_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(time_marker)

	var time_label := _label(str(data.get("time", "第 1 天 · 周一 · 早晨")), 17, GRAPHITE)
	time_label.position = Vector2(56, 24)
	time_label.size = Vector2(250, 30)
	add_child(time_label)

	var location_label := _label(str(data.get("scene_name", "校园场景")), 15, MIST_BLUE)
	location_label.position = Vector2(316, 26)
	location_label.size = Vector2(260, 28)
	add_child(location_label)

	var state_row := HBoxContainer.new()
	state_row.name = "EditorialStateLine"
	state_row.position = Vector2(893, 20)
	state_row.size = Vector2(347, 38)
	state_row.alignment = BoxContainer.ALIGNMENT_END
	state_row.add_theme_constant_override("separation", 14)
	add_child(state_row)
	state_row.add_child(_state_pair("精力", int(data.get("energy", 0)), ENERGY))
	state_row.add_child(_thin_divider())
	state_row.add_child(_state_pair("压力", int(data.get("stress", 0)), STRESS))
	state_row.add_child(_thin_divider())
	state_row.add_child(_state_pair("考试", int(data.get("exam", 0)), EXAM))


func _build_narrative(data: Dictionary) -> void:
	var narrative_rect: Rect2 = _layout.get("narrative_rect", Rect2(56, 318, 308, 334))
	_narrative = Control.new()
	_narrative.name = "EventNarrative"
	_narrative.position = narrative_rect.position
	_narrative.size = narrative_rect.size
	add_child(_narrative)

	var section_line := ColorRect.new()
	section_line.color = SDU_RED
	section_line.position = Vector2(0, 0)
	section_line.size = Vector2(38, 4)
	section_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narrative.add_child(section_line)

	var section := _label(str(data.get("section", "校园事件")), 13, SDU_RED)
	section.position = Vector2(0, 15)
	section.size = Vector2(230, 24)
	_narrative.add_child(section)

	var title_size := int(_layout.get("title_size", data.get("title_size", 36)))
	var title_height := float(_layout.get("title_height", 132))
	var body_height := float(_layout.get("body_height", 102))
	var title := _label(str(data.get("title", "这个时段发生了什么？")), title_size, GRAPHITE)
	title.name = "EventTitle"
	title.position = Vector2(0, 43)
	title.size = Vector2(narrative_rect.size.x - 4, title_height)
	title.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	title.clip_text = true
	title.max_lines_visible = int(_layout.get("title_lines", 3))
	title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_narrative.add_child(title)

	var body := _paragraph(str(data.get("body", "")), 15, GRAPHITE_SOFT)
	body.name = "EventBody"
	body.position = Vector2(0, 55 + title_height)
	body.size = Vector2(narrative_rect.size.x - 4, body_height)
	_narrative.add_child(body)

	var state_copy := _state_copy(data.get("state_tags", []))
	var state_line := _label(state_copy, 13, GRAPHITE_FAINT)
	state_line.position = Vector2(0, narrative_rect.size.y - 26)
	state_line.size = Vector2(narrative_rect.size.x - 4, 24)
	state_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_narrative.add_child(state_line)


func _build_choices(data: Dictionary) -> void:
	var choice_rect: Rect2 = _layout.get("choice_rect", Rect2(676, 190, 548, 446))
	_choice_region = Control.new()
	_choice_region.name = "EditorialChoiceRegion"
	_choice_region.position = choice_rect.position
	_choice_region.size = choice_rect.size
	add_child(_choice_region)

	var question := _label(str(data.get("question", "你准备怎么做？")), 16, GRAPHITE)
	question.position = Vector2(0, 0)
	question.size = Vector2(choice_rect.size.x * 0.58, 28)
	_choice_region.add_child(question)

	_interaction_status = _label(str(data.get("cost_text", "选择后推进 1 个时段")), 12, GRAPHITE_FAINT)
	_interaction_status.name = "InteractionStatus"
	_interaction_status.position = Vector2(choice_rect.size.x * 0.56, 3)
	_interaction_status.size = Vector2(choice_rect.size.x * 0.44, 24)
	_interaction_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_choice_region.add_child(_interaction_status)

	var choices := VBoxContainer.new()
	choices.name = "ChoiceList"
	choices.position = Vector2(0, 41)
	choices.size = Vector2(choice_rect.size.x, choice_rect.size.y - 82)
	choices.add_theme_constant_override("separation", 0)
	_choice_region.add_child(choices)

	var choice_index := 1
	for choice_value in data.get("choices", []):
		choices.add_child(_choice_row(choice_index, choice_value))
		choice_index += 1

	var save_line := _label("自动存档已开启", 12, Color("#526A65"))
	save_line.position = Vector2(0, choice_rect.size.y - 24)
	save_line.size = Vector2(choice_rect.size.x * 0.38, 22)
	_choice_region.add_child(save_line)

	var hint := _label(str(data.get("footer_hint", "ESC  暂停")), 11, GRAPHITE_FAINT)
	hint.position = Vector2(choice_rect.size.x * 0.38, choice_rect.size.y - 24)
	hint.size = Vector2(choice_rect.size.x * 0.62, 22)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_choice_region.add_child(hint)


func _choice_row(index: int, choice_value) -> Button:
	var choice: Dictionary = choice_value
	var row_width := float(_layout.get("choice_width", 548.0))
	var row_height := float(choice.get("height", _layout.get("choice_height", 106.0)))
	var button := Button.new()
	button.name = str(choice.get("name", "Choice_%02d" % index))
	button.custom_minimum_size = Vector2(row_width, row_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.disabled = bool(choice.get("disabled", false))
	button.set_meta("audio_cue", &"choice")
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())

	var marker := ColorRect.new()
	marker.name = "ChoiceMarker"
	marker.color = SDU_RED
	marker.position = Vector2(0, (row_height - 28.0) * 0.5)
	marker.size = Vector2(3, 28)
	marker.modulate.a = 0.0
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(marker)

	var copy := Control.new()
	copy.name = "ChoiceCopy"
	copy.position = Vector2(18, 0)
	copy.size = Vector2(row_width - 18.0, row_height)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(copy)

	var number := _label("%02d" % index, 25, SDU_RED)
	number.position = Vector2(0, maxf(12.0, (row_height - 40.0) * 0.5))
	number.size = Vector2(50, 40)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(number)

	var effect_width := clampf(row_width * 0.27, 104.0, 164.0)
	var text_width := maxf(142.0, row_width - 66.0 - effect_width - 24.0)
	var title := _label(str(choice.get("title", "选择")), 18, GRAPHITE)
	title.position = Vector2(66, 10)
	title.size = Vector2(text_width, 30)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title)

	var detail := _label(str(choice.get("detail", "")), 13, GRAPHITE_SOFT)
	detail.position = Vector2(66, 40)
	detail.size = Vector2(text_width, maxf(32.0, row_height - 46.0))
	detail.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	detail.clip_text = true
	detail.max_lines_visible = 2
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(detail)

	var effect_color := Color(str(choice.get("effect_color", "#527C8A"))).darkened(0.24)
	var effect := _label(str(choice.get("effect", "查看后果")), 13, effect_color)
	effect.position = Vector2(row_width - effect_width - 2.0, maxf(14.0, (row_height - 36.0) * 0.5))
	effect.size = Vector2(effect_width, 36)
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	effect.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(effect)

	var rule := ColorRect.new()
	rule.name = "ChoiceRule"
	rule.color = RULE
	rule.position = Vector2(66, row_height - 1.0)
	rule.size = Vector2(row_width - 86.0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(rule)
	button.set_meta("_rule_rest_width", rule.size.x)
	button.set_meta("_rule_active_width", rule.size.x + 10.0)

	var action = choice.get("action")
	if action is Callable and not action.is_null():
		button.pressed.connect(action)
	button.mouse_entered.connect(_set_choice_active.bind(button, copy, marker, rule, true))
	button.mouse_exited.connect(_set_choice_active.bind(button, copy, marker, rule, false))
	button.focus_entered.connect(_set_choice_active.bind(button, copy, marker, rule, true))
	button.focus_exited.connect(_set_choice_active.bind(button, copy, marker, rule, false))
	if button.disabled:
		button.modulate.a = 0.45
	return button


func _set_choice_active(
	button: Button,
	copy: Control,
	marker: ColorRect,
	rule: ColorRect,
	active: bool
) -> void:
	if button.disabled:
		return
	var previous := button.get_meta("_editorial_tween") as Tween if button.has_meta("_editorial_tween") else null
	if previous != null and previous.is_valid():
		previous.kill()
	var duration := 0.01 if _reduced_motion else 0.16
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	button.set_meta("_editorial_tween", tween)
	tween.tween_property(copy, "position:x", 28.0 if active else 18.0, duration)
	tween.tween_property(marker, "modulate:a", 1.0 if active else 0.0, duration)
	tween.tween_property(rule, "color", Color(SDU_RED, 0.68) if active else RULE, duration)
	tween.tween_property(
		rule,
		"size:x",
		float(button.get_meta("_rule_active_width") if active else button.get_meta("_rule_rest_width")),
		duration
	)


func _build_day_line(data: Dictionary) -> void:
	var footer_rule := ColorRect.new()
	footer_rule.color = Color("#3F4B4B40")
	footer_rule.position = Vector2(40, 674)
	footer_rule.size = Vector2(1200, 1)
	footer_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer_rule)

	var slots := ["早晨", "上午", "下午", "晚上", "深夜"]
	var current_slot := clampi(int(data.get("slot_index", 0)), 0, slots.size() - 1)
	var day_line := HBoxContainer.new()
	day_line.name = "DayTimeline"
	day_line.position = Vector2(40, 682)
	day_line.size = Vector2(580, 26)
	day_line.add_theme_constant_override("separation", 18)
	add_child(day_line)
	for slot_index in slots.size():
		var slot_label := _label(slots[slot_index], 11, SDU_RED if slot_index == current_slot else GRAPHITE_FAINT)
		slot_label.custom_minimum_size.x = 72
		day_line.add_child(slot_label)

	var day_label := _label("第 %d 天 / 7" % int(data.get("day", 1)), 11, GRAPHITE_FAINT)
	day_label.position = Vector2(1124, 682)
	day_label.size = Vector2(116, 24)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(day_label)


func _animate_entrance() -> void:
	if _reduced_motion or _narrative == null or _choice_region == null:
		return
	var narrative_rest := _narrative.position
	var choice_rest := _choice_region.position
	_narrative.position.y += 10.0
	_choice_region.position.x += 12.0
	if _photo_stage != null:
		_photo_stage.modulate.a = 0.82
	_narrative.modulate.a = 0.0
	_choice_region.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_narrative, "position", narrative_rest, 0.20)
	tween.tween_property(_narrative, "modulate:a", 1.0, 0.16)
	tween.tween_property(_choice_region, "position", choice_rest, 0.24).set_delay(0.035)
	tween.tween_property(_choice_region, "modulate:a", 1.0, 0.19).set_delay(0.035)
	if _photo_stage != null:
		tween.tween_property(_photo_stage, "modulate:a", 1.0, 0.42)


func _resolve_layout(data: Dictionary) -> Dictionary:
	var mode := str(data.get("presentation_mode", "auto"))
	var side := str(data.get("photo_side", "auto"))
	if mode == "auto":
		var image_size := Vector2.ZERO
		var image_texture := data.get("image_texture") as Texture2D
		if image_texture != null:
			image_size = image_texture.get_size()
		if int(data.get("orientation", 1)) in [6, 8]:
			image_size = Vector2(image_size.y, image_size.x)
		var aspect := image_size.x / maxf(image_size.y, 1.0)
		if aspect >= 1.5:
			mode = "cinematic"
		elif aspect < 0.85:
			mode = "portrait"
		else:
			mode = "editorial"
	if side not in ["left", "right"]:
		side = "left"
	if mode == "portrait":
		var portrait_photo_x := 48.0 if side == "left" else 776.0
		var portrait_copy_x := 552.0 if side == "left" else 56.0
		return {
			"mode": mode,
			"side": side,
			"photo_rect": Rect2(portrait_photo_x, 100, 456, 540),
			"narrative_rect": Rect2(portrait_copy_x, 96, 672, 202),
			"choice_rect": Rect2(portrait_copy_x, 320, 672, 330),
			"choice_width": 672.0,
			"choice_height": 86.0,
			"title_size": 31,
			"title_height": 72.0,
			"title_lines": 2,
			"body_height": 54.0,
		}
	if mode == "editorial":
		var editorial_photo_x := 48.0 if side == "left" else 592.0
		var editorial_copy_x := 736.0 if side == "left" else 56.0
		return {
			"mode": mode,
			"side": side,
			"photo_rect": Rect2(editorial_photo_x, 128, 640, 480),
			"narrative_rect": Rect2(editorial_copy_x, 96, 488, 202),
			"choice_rect": Rect2(editorial_copy_x, 320, 488, 330),
			"choice_width": 488.0,
			"choice_height": 86.0,
			"title_size": 30,
			"title_height": 72.0,
			"title_lines": 2,
			"body_height": 54.0,
		}
	return {
		"mode": "cinematic",
		"side": side,
		"photo_rect": Rect2(0, 0, 1280, 720),
		"narrative_rect": Rect2(56, 318, 308, 334),
		"choice_rect": Rect2(676, 190, 548, 446),
		"choice_width": 548.0,
		"choice_height": 106.0,
		"title_size": 36,
		"title_height": 132.0,
		"title_lines": 3,
		"body_height": 102.0,
	}


func _gradient_veil(colors: Array[Color]) -> TextureRect:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.34, 0.72, 1.0])
	gradient.colors = PackedColorArray(colors)
	var texture := GradientTexture2D.new()
	texture.width = 512
	texture.height = 4
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	var veil := TextureRect.new()
	veil.texture = texture
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return veil


func _localized_choice_veil() -> ColorRect:
	var veil := ColorRect.new()
	veil.name = "ChoiceReadabilityVeil"
	veil.color = Color.WHITE
	veil.position = Vector2(610, 142)
	veil.size = Vector2(670, 514)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 paper_color : source_color = vec4(0.914, 0.902, 0.863, 1.0);

void fragment() {
	float horizontal = smoothstep(0.0, 0.34, UV.x);
	float vertical_in = smoothstep(0.0, 0.12, UV.y);
	float vertical_out = 1.0 - smoothstep(0.88, 1.0, UV.y);
	float paper_alpha = mix(0.28, 0.97, horizontal) * vertical_in * vertical_out;
	COLOR = vec4(paper_color.rgb, paper_alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	veil.material = material
	return veil


func _state_pair(title: String, value: int, color: Color) -> HBoxContainer:
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", 6)
	pair.add_child(_label(title, 11, GRAPHITE_FAINT))
	pair.add_child(_label(str(value), 17, color))
	return pair


func _thin_divider() -> VSeparator:
	var divider := VSeparator.new()
	divider.modulate = Color("#48545452")
	divider.custom_minimum_size.x = 3
	return divider


func _state_copy(values) -> String:
	if not values is Array:
		return ""
	var labels: Array[String] = []
	for value in values:
		if value is Dictionary:
			labels.append(str(value.get("text", "")))
	return "  /  ".join(labels)


func _label(text_value: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result


func _paragraph(text_value: String, size: int, color: Color) -> RichTextLabel:
	var result := RichTextLabel.new()
	result.text = text_value
	result.bbcode_enabled = false
	result.fit_content = false
	result.scroll_active = false
	result.selection_enabled = false
	result.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("normal_font_size", size)
	result.add_theme_color_override("default_color", color)
	result.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	return result
