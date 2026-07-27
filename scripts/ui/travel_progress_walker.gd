extends Control
class_name TravelProgressWalker

## A small illustrated student that walks with the campus transit progress bar.

const INK := Color("#26352F")
const PAPER := Color("#F7F1E5")
const SDU_RED := Color("#B84850")
const BACKPACK := Color("#4C7D8F")
const SKIN := Color("#E8B98F")

var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 100.0)
		queue_redraw()


func _draw() -> void:
	var x := lerpf(14.0, maxf(size.x - 16.0, 14.0), progress / 100.0)
	var phase := sin(progress / 7.5)
	var ground_y := size.y - 7.0
	draw_set_transform(Vector2(x, ground_y), 0.0, Vector2.ONE)

	# A soft shadow keeps the figure visually attached to the route line.
	_draw_ellipse(Vector2(0, 3), Vector2(9, 2.5), Color("#2A312B33"))
	# Backpack, body, head and cap.
	draw_circle(Vector2(-5, -14), 6.0, BACKPACK)
	draw_circle(Vector2(-5, -14), 6.0, Color(INK, 0.52), false, 1.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -25), Vector2(5, -25), Vector2(7, -12), Vector2(-5, -12)
	]), PAPER)
	draw_polyline(PackedVector2Array([
		Vector2(-4, -25), Vector2(5, -25), Vector2(7, -12), Vector2(-5, -12), Vector2(-4, -25)
	]), INK, 1.2, true)
	draw_circle(Vector2(1, -31), 5.4, SKIN)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -34), Vector2(6, -35), Vector2(4, -38), Vector2(-4, -37)
	]), SDU_RED)
	# Arms and alternating walking legs.
	draw_line(Vector2(5, -22), Vector2(10, -17 + phase * 2.0), INK, 2.0, true)
	draw_line(Vector2(-1, -13), Vector2(-5 + phase * 4.0, -5), INK, 2.4, true)
	draw_line(Vector2(4, -13), Vector2(8 - phase * 4.0, -5), INK, 2.4, true)
	draw_line(Vector2(-8 + phase * 4.0, -5), Vector2(-2 + phase * 4.0, -5), SDU_RED, 2.2, true)
	draw_line(Vector2(5 - phase * 4.0, -5), Vector2(11 - phase * 4.0, -5), SDU_RED, 2.2, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 17:
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
