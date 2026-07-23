class_name OrientedPhotoRect
extends TextureRect

var exif_orientation := 1


func configure(photo_texture: Texture2D, orientation: int, cover: bool) -> void:
	texture = photo_texture
	exif_orientation = orientation
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_update_layout()


func _ready() -> void:
	var parent_control := get_parent() as Control
	if parent_control != null and not parent_control.resized.is_connected(_update_layout):
		parent_control.resized.connect(_update_layout)
	_update_layout()


func _update_layout() -> void:
	var parent_control := get_parent() as Control
	if parent_control == null:
		return
	var available := parent_control.size
	if available.x <= 0.0 or available.y <= 0.0:
		return
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	if exif_orientation in [6, 8]:
		size = Vector2(available.y, available.x)
		position = (available - size) * 0.5
		pivot_offset = size * 0.5
		rotation = PI * 0.5 if exif_orientation == 6 else -PI * 0.5
	else:
		size = available
		position = Vector2.ZERO
		pivot_offset = size * 0.5
		rotation = PI if exif_orientation == 3 else 0.0
