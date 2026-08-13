extends SceneTree

var capture_failures := 0


func _wait_for_screen(app: Node, expected_screen: String, timeout_ms: int = 3000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while str(app.current_screen) != expected_screen and Time.get_ticks_msec() < deadline:
		await process_frame
	return str(app.current_screen) == expected_screen


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
	app.show_commitment()
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/commitment_sheet.png")
	DecisionRules.begin_commitment(app.session, "social")
	DecisionRules.register_effect(app.session, "relationship", "roommate", 4)
	app.show_map()
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/campus_map.png")
	var scholar_marker := app.find_child("MapNPC_scholar", true, false) as Button
	if scholar_marker != null:
		scholar_marker.pressed.emit()
		for _frame in 3:
			await process_frame
		_save_viewport("res://reports/campus_map_companion.png")
		app.show_map()
		for _frame in 3:
			await process_frame
	var library_hotspot := app.find_child("Location_library", true, false) as Button
	if library_hotspot != null:
		library_hotspot.mouse_entered.emit()
		for _frame in 3:
			await process_frame
		_save_viewport("res://reports/campus_map_hover.png")
		library_hotspot.mouse_exited.emit()
		library_hotspot.pressed.emit()
		for _frame in 3:
			await process_frame
		_save_viewport("res://reports/campus_map_route.png")
	var advice := AIAdvisor.new(app.repository.ai_advice).choose_advice(app.session)
	app.show_ai_advice(advice)
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/ai_advice_sheet.png")
	app.session = GameSession.new()
	app._present_current_state()
	await _wait_for_screen(app, "event")
	for _frame in 5:
		await process_frame
	await create_timer(0.45).timeout
	_save_viewport("res://reports/event_choice.png")
	var first_event_choice := app.find_child("Choice_plan", true, false) as Button
	if first_event_choice != null:
		first_event_choice.mouse_entered.emit()
		await create_timer(0.18).timeout
		_save_viewport("res://reports/event_choice_hover.png")
		first_event_choice.mouse_exited.emit()
	var arrival_event: Dictionary = app.event_engine.get_fixed_event(app.session)
	app._resolve_event_choice(arrival_event, arrival_event.choices[0])
	for _frame in 5:
		await process_frame
	await create_timer(0.45).timeout
	_save_viewport("res://reports/result_choice.png")
	app.show_pause_menu()
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/pause_menu.png")
	app.show_settings("pause")
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/audio_settings.png")
	app.session = GameSession.new()
	app.session.clock.slot = 1
	app.background_catalog.choose_location_background("library", app.session)
	var road_background: String = app.background_catalog.choose_road_background(app.session)
	var library_location: Dictionary = app.repository.get_location("library")
	app.show_travel(library_location, road_background, 10.0)
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
	await create_timer(0.45).timeout
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
	await create_timer(0.45).timeout
	_save_viewport("res://reports/teaching_named_event.png")
	app.session.current_background_path = "res://assets/backgrounds/locations/teaching/理综楼.jpg"
	app.show_event({
		"id": "building_editorial_visual",
		"title": "理综楼里的考前整理",
		"speaker": "旁白",
		"body": "你来到理综楼，把考场信息、课程重点和最后一轮复习顺序重新排好。",
		"choices": [
			{"id": "review", "label": "先核对考试范围", "effects": []},
			{"id": "questions", "label": "整理最后的问题清单", "effects": []},
			{"id": "rest", "label": "留十分钟让注意力恢复", "effects": []},
		],
	})
	for _frame in 5:
		await process_frame
	await create_timer(0.45).timeout
	_save_viewport("res://reports/building_editorial_event.png")
	app.session.current_location_id = "canteen"
	app.session.current_background_path = "res://assets/backgrounds/locations/canteen/水果/30c11daead283879b3c1714fad9a425e.jpg"
	var canteen_context: Dictionary = app.background_catalog.get_active_scene_context(app.session)
	var canteen_data: Dictionary = app._base_scene_data(canteen_context, app.session.current_background_path)
	canteen_data.merge({
		"panel_name": "LocationCard",
		"section": "齐园餐厅 · 地点行动",
		"title": "抵达 · 齐园餐厅 · 水果区",
		"body": "你来到齐园餐厅的水果区，准备挑些水果补充能量。",
		"question": "这个时段，你准备做什么？",
		"cost_text": "自主行动会推进约 3 个时段",
		"state_tags": [],
		"choices": [],
	}, true)
	app._show_adaptive_scene("location", canteen_data)
	for _frame in 5:
		await process_frame
	await create_timer(0.30).timeout
	_save_viewport("res://reports/location_photo_clean.png")
	app.session.difficulty_id = "hard"
	app.session.stats.stress = 78
	app.show_stress_crisis(func(): pass)
	await _wait_for_screen(app, "stress_crisis")
	for _frame in 5:
		await process_frame
	await create_timer(0.45).timeout
	_save_viewport("res://reports/stress_crisis.png")
	app.session.stats.study = 78
	app.session.stats.project = 81
	app.session.stats.energy = 46
	app.session.stats.stress = 58
	app.session.stats.ai_dependence = 38
	app.session.flags["verified_ai"] = true
	app.session.flags["exam_outcome"] = "strong"
	app.session.flags["presentation_outcome"] = "pass"
	app.show_ending()
	for _frame in 5:
		await process_frame
	_save_viewport("res://reports/ending_report.png")
	var audio_director := root.get_node_or_null("ProjectUISoundController") as AudioDirector
	if audio_director != null:
		audio_director.prepare_for_shutdown()
		await process_frame
	var ambience := root.get_node_or_null("ProjectAmbientSoundController")
	if ambience != null:
		ambience.prepare_for_shutdown()
		await process_frame
		await create_timer(0.25).timeout
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
