extends SceneTree

var capture_failures := 0


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var output_directory := ProjectSettings.globalize_path("res://reports")
	DirAccess.make_dir_recursive_absolute(output_directory)
	var packed := load("res://scenes/main.tscn") as PackedScene
	var app = packed.instantiate()
	root.add_child(app)
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/main_menu.png")
	app.show_setup()
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/difficulty_setup.png")
	app.session = GameSession.new()
	app.session.reset("演示同学", "social")
	app.show_map()
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/campus_map.png")
	app.session = GameSession.new()
	app._present_current_state()
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/event_choice.png")
	app.session = GameSession.new()
	app.session.clock.slot = 1
	app.background_catalog.choose_location_background("library", app.session)
	var road_background: String = app.background_catalog.choose_road_background(app.session)
	app.show_travel(app.repository.get_location("library"), road_background, 10.0)
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/travel_day.png")
	app.show_location("library")
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/library_event.png")
	app.session.current_location_id = "field"
	app.session.current_background_path = "res://assets/backgrounds/locations/field/网球.jpg"
	app.show_event({
		"id": "tennis_visual",
		"title": "{scene_name}里的临时选择",
		"speaker": "旁白",
		"body": "你正在{scene_activity}。身体逐渐进入节奏，但项目群里又弹出了一条新消息。",
		"choices": [
			{"id": "continue", "label": "继续{scene_activity}，完成这次休息", "effects": []},
			{"id": "check", "label": "先停下来查看消息", "effects": []},
		],
	})
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/tennis_event.png")
	app.session.current_location_id = "teaching"
	app.session.current_background_path = "res://assets/backgrounds/locations/teaching/理综楼走廊.jpg"
	app.show_event({
		"id": "teaching_visual",
		"title": "考前的临时复习点",
		"speaker": "旁白",
		"body": "你来到{scene_name}，准备利用这个时段梳理还不牢固的章节。",
		"choices": [
			{"id": "review", "label": "在这里整理错题", "effects": []},
			{"id": "teacher", "label": "先去确认老师是否还在", "effects": []},
		],
	})
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/teaching_named_event.png")
	app.session.difficulty_id = "hard"
	app.session.stats.stress = 78
	app.show_stress_crisis(func(): pass)
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/stress_crisis.png")
	if capture_failures == 0:
		print("[PASS] visual captures written to reports/")
		quit(0)
	else:
		printerr("[FAIL] %d visual captures could not be written" % capture_failures)
		quit(1)


func _save_viewport(path: String) -> void:
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		capture_failures += 1
		printerr("Viewport texture is unavailable for visual capture: %s" % path)
		return
	var image := viewport_texture.get_image()
	if image == null:
		capture_failures += 1
		printerr("Viewport image is unavailable for visual capture: %s" % path)
		return
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		capture_failures += 1
		printerr("Failed to save visual capture: %s" % error_string(error))
