extends Node
## Adds restrained lift, focus and mouse-following light to a Control.

var accent := Color("#63DDB8")
var hover_scale := 1.018
var reduced_motion := false
var spotlight_strength := 0.15

var _target: Control
var _spotlight: TextureRect
var _tween: Tween
var _base_z_index := 0
var _hovered := false
var _pressed := false


func configure(
	accent_color: Color,
	scale_amount: float = 1.018,
	reduce_motion: bool = false,
	light_strength: float = 0.15
) -> void:
	accent = accent_color
	hover_scale = scale_amount
	reduced_motion = reduce_motion
	spotlight_strength = light_strength


func _ready() -> void:
	_target = get_parent() as Control
	if _target == null:
		queue_free()
		return
	_base_z_index = _target.z_index
	_target.clip_contents = true
	_target.resized.connect(_refresh_pivot)
	_target.mouse_entered.connect(_on_mouse_entered)
	_target.mouse_exited.connect(_on_mouse_exited)
	_target.focus_entered.connect(_on_focus_entered)
	_target.focus_exited.connect(_on_focus_exited)
	_target.gui_input.connect(_on_gui_input)
	if _target is BaseButton:
		var button := _target as BaseButton
		button.button_down.connect(_on_button_down)
		button.button_up.connect(_on_button_up)
	_refresh_pivot()
	_create_spotlight.call_deferred()


func _create_spotlight() -> void:
	if _target == null or not is_instance_valid(_target) or is_instance_valid(_spotlight):
		return
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.34, 1.0])
	gradient.colors = PackedColorArray([
		Color(accent, spotlight_strength),
		Color(accent.lightened(0.15), spotlight_strength * 0.52),
		Color(accent, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient

	_spotlight = TextureRect.new()
	_spotlight.name = "HoverSpotlight"
	_spotlight.texture = texture
	_spotlight.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_spotlight.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spotlight.modulate.a = 0.0
	_spotlight.size = Vector2(220, 220)
	_spotlight.position = (_target.size - _spotlight.size) * 0.5
	_spotlight.show_behind_parent = true
	_target.add_child(_spotlight, false, Node.INTERNAL_MODE_FRONT)


func _refresh_pivot() -> void:
	if _target == null:
		return
	_target.pivot_offset = _target.size * 0.5


func _on_mouse_entered() -> void:
	_hovered = true
	_target.z_index = _base_z_index + 3
	_animate_to(hover_scale if not reduced_motion else 1.0, 1.0, 0.14)


func _on_mouse_exited() -> void:
	_hovered = false
	_pressed = false
	_target.z_index = _base_z_index
	_animate_to(1.0, 0.0, 0.18)


func _on_focus_entered() -> void:
	if not _hovered and is_instance_valid(_spotlight):
		_spotlight.position = (_target.size - _spotlight.size) * 0.5
		_animate_to(hover_scale if not reduced_motion else 1.0, 0.72, 0.14)


func _on_focus_exited() -> void:
	if not _hovered:
		_animate_to(1.0, 0.0, 0.16)


func _on_button_down() -> void:
	_pressed = true
	_animate_to(0.985 if not reduced_motion else 1.0, 1.0, 0.07)


func _on_button_up() -> void:
	_pressed = false
	_animate_to(hover_scale if _hovered and not reduced_motion else 1.0, 0.86 if _hovered else 0.0, 0.10)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_instance_valid(_spotlight):
		var mouse_event := event as InputEventMouseMotion
		_spotlight.position = mouse_event.position - _spotlight.size * 0.5


func _animate_to(target_scale: float, target_light: float, duration: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if reduced_motion:
		_target.scale = Vector2.ONE
		if is_instance_valid(_spotlight):
			_spotlight.modulate.a = target_light
		return
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_target, "scale", Vector2.ONE * target_scale, duration)
	if is_instance_valid(_spotlight):
		_tween.tween_property(_spotlight, "modulate:a", target_light, duration)
