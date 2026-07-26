class_name CampusBackdrop
extends Control

var tint := Color.WHITE:
	set(value):
		tint = value
		queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var canvas_size := size
	draw_rect(Rect2(Vector2.ZERO, canvas_size), Color("#071519") * tint)
	for band in range(14):
		var progress := float(band) / 13.0
		var band_color := Color("#173D43").lerp(Color("#071013"), progress)
		draw_rect(Rect2(0, progress * canvas_size.y, canvas_size.x, canvas_size.y / 13.0 + 2.0), band_color * tint)

	_draw_soft_glow(canvas_size * Vector2(0.18, 0.16), minf(canvas_size.x, canvas_size.y) * 0.42, Color("#B8485024"), 12)
	_draw_soft_glow(canvas_size * Vector2(0.80, 0.72), minf(canvas_size.x, canvas_size.y) * 0.48, Color("#63DDB819"), 12)
	_draw_soft_glow(canvas_size * Vector2(0.54, 0.40), minf(canvas_size.x, canvas_size.y) * 0.34, Color("#7CB9E812"), 10)

	var grid_color := Color("#A7D8D20C")
	for x in range(-200, int(canvas_size.x) + 240, 96):
		draw_line(Vector2(x, 0), Vector2(x + 360, canvas_size.y), grid_color, 1.0, true)
	for y in range(64, int(canvas_size.y), 88):
		draw_line(Vector2(0, y), Vector2(canvas_size.x, y), grid_color, 1.0, true)

	var center := canvas_size * Vector2(0.56, 0.53)
	var campus := PackedVector2Array([
		center + Vector2(-520, -210), center + Vector2(-80, -330),
		center + Vector2(500, -135), center + Vector2(420, 260),
		center + Vector2(-170, 350), center + Vector2(-560, 120),
	])
	draw_colored_polygon(campus, Color("#315E50AA") * tint)

	# Isometric campus paths.
	var path_color := Color("#D7C79A52")
	draw_line(center + Vector2(-460, 120), center + Vector2(380, -150), path_color, 38, true)
	draw_line(center + Vector2(-300, -230), center + Vector2(290, 240), path_color, 30, true)
	draw_circle(center + Vector2(40, 10), 88, Color("#6AA98088"))
	draw_circle(center + Vector2(40, 10), 58, Color("#D7C79A88"))

	# Small original campus silhouettes used only as atmospheric background.
	_draw_building(center + Vector2(-330, -150), Vector2(150, 86), Color("#8275B7"), 34)
	_draw_building(center + Vector2(-40, -235), Vector2(180, 96), Color("#4D947A"), 42)
	_draw_building(center + Vector2(260, -105), Vector2(170, 105), Color("#D08B58"), 38)
	_draw_building(center + Vector2(235, 145), Vector2(180, 92), Color("#4F86AC"), 30)
	_draw_building(center + Vector2(-255, 190), Vector2(160, 88), Color("#C96868"), 28)
	_draw_field(center + Vector2(20, 230), Vector2(235, 105))

	for point in [center + Vector2(-475, -40), center + Vector2(-410, 70), center + Vector2(420, 25), center + Vector2(350, 210), center + Vector2(-390, 235)]:
		draw_circle(point, 24, Color("#2E6C53"))
		draw_circle(point + Vector2(0, -10), 17, Color("#6AAF73"))


func _draw_soft_glow(center: Vector2, radius: float, color: Color, steps: int) -> void:
	for index in range(steps, 0, -1):
		var progress := float(index) / float(steps)
		var layer := color
		layer.a *= (1.0 - progress) * (1.0 - progress) * 0.52
		draw_circle(center, radius * progress, layer)


func _draw_building(position: Vector2, building_size: Vector2, color: Color, roof_height: float) -> void:
	var body := Rect2(position - building_size * 0.5, building_size)
	draw_rect(body, color * tint)
	var roof := PackedVector2Array([
		Vector2(body.position.x, body.position.y),
		Vector2(body.position.x + building_size.x * 0.5, body.position.y - roof_height),
		Vector2(body.end.x, body.position.y),
		Vector2(body.position.x + building_size.x * 0.5, body.position.y + roof_height * 0.35),
	])
	draw_colored_polygon(roof, color.lightened(0.2) * tint)
	for column in range(3):
		var window_position := body.position + Vector2(25 + column * (building_size.x - 50) / 2.0, building_size.y * 0.45)
		draw_rect(Rect2(window_position, Vector2(18, 22)), Color("#FFE6A0AA"))


func _draw_field(position: Vector2, field_size: Vector2) -> void:
	var field_rect := Rect2(position - field_size * 0.5, field_size)
	draw_rect(field_rect, Color("#3D815A") * tint)
	for inset in [8.0, 18.0, 28.0]:
		draw_arc(position, minf(field_size.x, field_size.y) * 0.5 - inset, 0.0, TAU, 48, Color("#D7C79A99"), 2.0, true)
