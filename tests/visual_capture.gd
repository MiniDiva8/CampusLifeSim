extends SceneTree


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
	print("[PASS] visual captures written to reports/")
	quit(0)


func _save_viewport(path: String) -> void:
	var image := root.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		printerr("Failed to save visual capture: %s" % error_string(error))
