extends SceneTree

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var app = packed.instantiate()
	root.add_child(app)
	await process_frame
	_expect(app.current_screen == "main_menu", "application should open on main menu")
	_expect(app.repository.events.size() == 32, "main UI should load validated content")
	_expect(app.background_catalog.locations.size() == 6, "main UI should load all location background pools")
	app.show_setup()
	await process_frame
	_expect(app.find_child("Difficulty_easy", true, false) != null and app.find_child("Difficulty_medium", true, false) != null and app.find_child("Difficulty_hard", true, false) != null, "setup should expose three difficulty choices")
	var medium_button := app.find_child("Difficulty_medium", true, false) as Button
	_expect(medium_button != null and medium_button.button_pressed, "new games should recommend medium difficulty")
	app.save_service = SaveService.new("user://campus_ui_smoke_save.json", "user://campus_ui_smoke_settings.json")
	app.save_service.delete_save()
	var name_input := app.find_child("PlayerName", true, false) as LineEdit
	var study_button := app.find_child("Trait_study", true, false) as Button
	app._start_from_setup(name_input, study_button.button_group, medium_button.button_group)
	await process_frame
	_expect(app.session.difficulty_id == "medium" and app.current_screen == "event", "starting from setup should save the selected medium difficulty")

	app.save_service = SaveService.new("user://campus_ui_smoke_save.json", "user://campus_ui_smoke_settings.json")
	app.save_service.delete_save()
	app.session = GameSession.new()
	app.session.reset("流程测试", "study")
	app._present_current_state()
	await process_frame
	_expect(app.current_screen == "event", "new run should present day-one fixed event")

	var first_event: Dictionary = app.event_engine.get_fixed_event(app.session)
	app._resolve_event_choice(first_event, first_event.choices[0])
	await process_frame
	_expect(app.current_screen == "result", "event choice should show consequences")
	app._advance_after_action()
	await process_frame
	_expect(app.current_screen == "map", "continuing should reach the campus map")
	_expect(app.session.clock.get_index() == 1, "first choice should consume one slot")

	app._travel_to_location("library", 0.05)
	await process_frame
	_expect(app.current_screen == "travel", "selecting a location should open the travel transition")
	_expect(app.active_photo_background != null, "travel transition should use a road photograph")
	await create_timer(0.08).timeout
	_expect(app.current_screen == "event", "library should present an eligible location event")
	_expect(app.active_photo_background != null, "location event should retain the selected scene photograph")
	var library_event: Dictionary = app.event_engine.get_location_event("library", app.session)
	app._resolve_event_choice(library_event, library_event.choices[0])
	app._advance_after_action()
	await process_frame
	_expect(app.session.clock.get_index() == 2, "location event should consume one slot")
	_expect(app.current_screen == "event", "day-one schedule notice should trigger on its fixed slot")

	app.show_pause_menu()
	await process_frame
	_expect(app.current_screen == "pause", "pause menu should open")
	app.show_settings("pause")
	await process_frame
	_expect(app.current_screen == "settings", "settings should open from pause")
	app.session.difficulty_id = "medium"
	app.session.stats.stress = DifficultyRules.get_crisis_threshold("medium")
	app._advance_after_action()
	await process_frame
	_expect(app.current_screen == "stress_crisis", "high stress should automatically open the disorientation choice screen after an action")
	_expect(app.active_photo_background != null, "stress crisis should use the long-exposure photograph")
	var stress_before := int(app.session.stats.stress)
	app._resolve_stress_crisis("recover", func(): pass)
	_expect(int(app.session.stats.stress) < stress_before, "choosing to recover should lower stress")
	app.save_service.delete_save()
	app.queue_free()
	await process_frame

	if failures.is_empty():
		print("[PASS] UI smoke: %d checks passed" % checks)
		quit(0)
	else:
		for failure in failures:
			printerr("[FAIL] %s" % failure)
		quit(1)
