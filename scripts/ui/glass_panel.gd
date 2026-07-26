extends PanelContainer
## Large, reusable frosted-glass surface for the competition UI.
##
## The shader sits behind this container. The container itself draws the border
## and shadow, keeping text and controls crisp above the blurred background.

const GLASS_SHADER = preload("res://assets/shaders/neo_glass.gdshader")

var _glass_rect: ColorRect
var _material: ShaderMaterial
var _configured := false


func configure(
	tint: Color,
	accent: Color,
	radius: int = 18,
	blur_lod: float = 2.8,
	tint_strength: float = 0.78,
	padding: Vector4 = Vector4(20, 18, 20, 18)
) -> void:
	_ensure_surface()
	var glass_tint := tint
	glass_tint.a = clampf(tint_strength, 0.0, 1.0)
	var edge_tint := accent
	edge_tint.a = clampf(maxf(accent.a, 0.32), 0.0, 0.72)
	_material.set_shader_parameter("glass_tint", glass_tint)
	_material.set_shader_parameter("edge_tint", edge_tint)
	_material.set_shader_parameter("blur_lod", clampf(blur_lod, 0.0, 5.0))
	_material.set_shader_parameter("corner_radius_px", float(radius))
	_material.set_shader_parameter("edge_strength", 0.36)

	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.02, 0.06, 0.07, 0.05)
	frame.corner_radius_top_left = radius
	frame.corner_radius_top_right = radius
	frame.corner_radius_bottom_left = radius
	frame.corner_radius_bottom_right = radius
	frame.border_width_left = 1
	frame.border_width_top = 1
	frame.border_width_right = 1
	frame.border_width_bottom = 1
	frame.border_color = Color(accent, clampf(accent.a * 0.75, 0.24, 0.58))
	frame.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	frame.shadow_size = 13
	frame.shadow_offset = Vector2(0, 6)
	frame.content_margin_left = padding.x
	frame.content_margin_top = padding.y
	frame.content_margin_right = padding.z
	frame.content_margin_bottom = padding.w
	frame.anti_aliasing = true
	add_theme_stylebox_override("panel", frame)
	_configured = true


func set_glass_intensity(value: float) -> void:
	_ensure_surface()
	_material.set_shader_parameter("blur_lod", lerpf(1.2, 3.8, clampf(value, 0.0, 1.0)))
	_material.set_shader_parameter("grain_strength", lerpf(0.004, 0.016, clampf(value, 0.0, 1.0)))


func _ready() -> void:
	_ensure_surface()
	if not _configured:
		configure(Color("#0B171A"), Color("#54777B80"))


func _ensure_surface() -> void:
	if is_instance_valid(_glass_rect):
		return
	_glass_rect = ColorRect.new()
	_glass_rect.name = "GlassBackdrop"
	_glass_rect.color = Color.WHITE
	_glass_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glass_rect.show_behind_parent = true
	_glass_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_material = ShaderMaterial.new()
	_material.shader = GLASS_SHADER
	_glass_rect.material = _material
	add_child(_glass_rect, false, Node.INTERNAL_MODE_BACK)
