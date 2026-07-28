extends SceneTree

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _has_label_containing(node: Node, fragment: String) -> bool:
	if node is Label and str(node.text).contains(fragment):
		return true
	if node is RichTextLabel and str(node.text).contains(fragment):
		return true
	for child in node.get_children():
		if _has_label_containing(child, fragment):
			return true
	return false


func _count_nodes_with_script(node: Node, script_path: String) -> int:
	var count := 0
	var attached_script: Script = node.get_script() as Script
	if attached_script != null and attached_script.resource_path == script_path:
		count += 1
	for child in node.get_children():
		count += _count_nodes_with_script(child, script_path)
	return count


func _wait_for_screen(app: Node, expected_screen: String, timeout_ms: int = 3000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while str(app.current_screen) != expected_screen and Time.get_ticks_msec() < deadline:
		await process_frame
	return str(app.current_screen) == expected_screen


func _wait_for_node(app: Node, node_name: String, timeout_ms: int = 3000) -> Node:
	var deadline := Time.get_ticks_msec() + timeout_ms
	var found := app.find_child(node_name, true, false)
	while found == null and Time.get_ticks_msec() < deadline:
		await process_frame
		found = app.find_child(node_name, true, false)
	return found


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var app = packed.instantiate()
	root.add_child(app)
	await process_frame
	_expect(app.current_screen == "main_menu", "application should open on main menu")
	_expect(app.find_child("ArchiveMainMenuView", true, false) != null, "main menu should open as a dedicated final-week archive cover")
	_expect(app.find_child("ArchivePhotoAttachment", true, false) != null and app.find_child("ArchiveSeal", true, false) != null, "archive cover should mount the campus evidence photo and expose a ritual seal action")
	_expect(_count_nodes_with_script(app, "res://scripts/ui/glass_panel.gd") == 0, "archive cover should not reuse the legacy dashboard glass cards")
	_expect(_has_label_containing(app, "第 0 日 / 入档前"), "archive cover should establish the pre-run record state")
	var ambience := root.get_node_or_null("ProjectAmbientSoundController")
	_expect(ambience != null and ambience.get_current_context() == &"menu", "main menu should start the restrained campus soundscape")
	_expect(app.repository.events.size() == 32, "main UI should load validated content")
	_expect(app.background_catalog.locations.size() == 6, "main UI should load all location background pools")
	app.show_setup()
	await process_frame
	_expect(app.find_child("RouteSetupView", true, false) != null, "setup should use the dedicated two-page route dossier")
	_expect(_has_label_containing(app, "档案署名") and (app.find_child("PlayerName", true, false) as LineEdit).has_theme_stylebox_override("normal"), "setup should present the player name as a clear dossier-signature field")
	_expect(app.find_child("Difficulty_easy", true, false) != null and app.find_child("Difficulty_medium", true, false) != null and app.find_child("Difficulty_hard", true, false) != null, "setup should expose three difficulty choices")
	var medium_button := app.find_child("Difficulty_medium", true, false) as Button
	_expect(medium_button != null and medium_button.button_pressed, "new games should recommend medium difficulty")
	var project_route := app.find_child("Trait_project", true, false) as Button
	project_route.pressed.emit()
	await process_frame
	_expect(_has_label_containing(app, "每次行动会额外积累 1 点压力"), "route dossier should expose a truthful gameplay shortcoming")
	var study_route := app.find_child("Trait_study", true, false) as Button
	study_route.pressed.emit()
	app.save_service = SaveService.new("user://campus_ui_smoke_save.json", "user://campus_ui_smoke_settings.json")
	app.save_service.delete_save()
	var name_input := app.find_child("PlayerName", true, false) as LineEdit
	var study_button := app.find_child("Trait_study", true, false) as Button
	app._start_from_setup(name_input, study_button.button_group, medium_button.button_group)
	_expect(await _wait_for_screen(app, "event"), "starting from setup should prepare the first event without blocking")
	_expect(app.session.difficulty_id == "medium", "starting from setup should save the selected medium difficulty")

	app.save_service = SaveService.new("user://campus_ui_smoke_save.json", "user://campus_ui_smoke_settings.json")
	app.save_service.delete_save()
	app.session = GameSession.new()
	app.session.reset("流程测试", "study")
	app._present_current_state()
	await process_frame
	_expect(app.current_screen == "event", "new run should present day-one fixed event")
	_expect(not app.session.current_background_path.is_empty() and app.session.current_location_id == "teaching", "fixed schedule events should receive a semantic campus photograph")
	_expect(_has_label_containing(app, "考试 +5"), "choice cards should preview difficulty-adjusted consequences")

	var first_choice_button := app.find_child("Choice_plan", true, false) as Button
	_expect(first_choice_button != null, "data-driven event choices should become named interactive cards")
	var first_photo_texture: Texture2D = app.active_photo_background.texture
	var choice_click_started := Time.get_ticks_usec()
	first_choice_button.pressed.emit()
	var choice_click_ms := float(Time.get_ticks_usec() - choice_click_started) / 1000.0
	_expect(choice_click_ms < 150.0, "choice callback should yield responsive feedback within 150 ms")
	_expect(app.find_child("InteractionPending", true, false) != null, "choice clicks should show feedback before any heavier result work")
	_expect(await _wait_for_screen(app, "result"), "event choice should show consequences")
	_expect(app.find_child("EditorialEventView", true, false) != null and app.find_child("AdaptiveScene", true, false) == null, "choice results should use the paper editorial receipt instead of the legacy dark adaptive panel")
	_expect(_has_label_containing(app, "选择回执") and _has_label_containing(app, "翻页 · 继续期末周"), "result receipt should clearly separate settled consequences from the next-page action")
	_expect(app.active_photo_background.texture == first_photo_texture, "choice result should reuse the active original photo texture instead of decoding it again")
	var first_continue := app.find_child("ContinueResult", true, false) as Button
	first_continue.pressed.emit()
	_expect(await _wait_for_screen(app, "map"), "continuing should reach the campus map")
	_expect(app.session.clock.get_index() == 1, "first choice should consume one slot")
	var campus_map := app.find_child("CampusMapView", true, false) as Control
	var library_location_button := app.find_child("Location_library", true, false) as Button
	_expect(campus_map != null and library_location_button != null, "campus screen should expose a full-canvas map with building hotspots")
	_expect(_count_nodes_with_script(campus_map, "res://scripts/ui/glass_panel.gd") == 0, "campus navigation should not return to the legacy dashboard glass panels")
	library_location_button.mouse_entered.emit()
	await process_frame
	var hover_note := app.find_child("MapHoverNote", true, false) as Control
	_expect(library_location_button.tooltip_text.is_empty(), "building hotspots should suppress Godot's black system tooltip when the paper hover note is active")
	_expect(hover_note != null and hover_note.visible, "hovering a campus building should reveal one white paper activity note")
	_expect(_has_label_containing(hover_note, "专注复习") and _has_label_containing(hover_note, "整理资料"), "library paper note should explain the concrete actions available there")
	library_location_button.mouse_exited.emit()
	await process_frame
	_expect(not hover_note.visible, "the paper activity note should leave with the pointer instead of lingering")
	library_location_button.pressed.emit()
	await process_frame
	var travel_selected := app.find_child("TravelSelected", true, false) as Button
	_expect(str(campus_map.selected_location_id) == "library", "selecting a building should draw its route before travel")
	_expect(travel_selected != null and not travel_selected.disabled, "selected building should expose one contextual travel action")
	_expect(_has_label_containing(app, "蒋震图书馆"), "selected building should reveal its real campus name")

	var travel_click_started := Time.get_ticks_usec()
	app._travel_to_location("library", 0.05)
	var travel_click_ms := float(Time.get_ticks_usec() - travel_click_started) / 1000.0
	_expect(travel_click_ms < 150.0, "location callback should acknowledge the click before original photos finish loading")
	_expect(app.current_screen == "travel", "selecting a location should open the travel transition")
	_expect(_has_label_containing(app, "已收到你的选择"), "cold photo loads should first show a responsive travel acknowledgement")
	var travel_progress := await _wait_for_node(app, "TravelProgress") as ProgressBar
	_expect(ambience != null and ambience.get_current_context() == &"road", "travel transition should crossfade to the road soundscape")
	_expect(app.active_photo_background != null, "travel transition should use a road photograph")
	_expect(travel_progress != null and travel_progress.has_theme_stylebox_override("fill"), "travel transition should use the luminous progress treatment")
	_expect(app.find_child("TravelProgressWalker", true, false) != null, "travel transition should place a walking student illustration above the progress bar")
	_expect(not _has_label_containing(app, "约 2 秒"), "travel transition should not expose a mechanical two-second countdown")
	_expect(await _wait_for_screen(app, "event"), "library should present an eligible location event")
	_expect(ambience != null and ambience.get_current_context() == &"library", "arrival should crossfade from the road into the library")
	_expect(app.active_photo_background != null, "location event should retain the selected scene photograph")
	var library_event: Dictionary = app.event_engine.get_location_event("library", app.session)
	var library_choice := app.find_child("Choice_%s" % str(library_event.choices[0].id), true, false) as Button
	library_choice.pressed.emit()
	_expect(await _wait_for_screen(app, "result"), "library choice should resolve after responsive feedback")
	var library_continue := app.find_child("ContinueResult", true, false) as Button
	library_continue.pressed.emit()
	_expect(await _wait_for_screen(app, "event"), "day-one schedule notice should trigger on its fixed slot")
	_expect(app.session.clock.get_index() == 2, "location event should consume one slot")

	app.session.current_location_id = "field"
	app.session.current_background_path = "res://assets/backgrounds/locations/field/网球.jpg"
	app.show_event({
		"id": "scene_ui_test",
		"title": "{scene_name}里的临时选择",
		"speaker": "旁白",
		"body": "你正在{scene_activity}，需要决定下一步。",
		"choices": [{"id": "continue", "label": "继续{scene_activity}", "effects": []}],
	})
	await process_frame
	_expect(_has_label_containing(app, "网球场"), "event UI should show the real scene name from the displayed photo")
	_expect(_has_label_containing(app, "你正在打网球"), "event text should describe the real activity from the displayed photo")
	_expect(app.active_photo_background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and app.active_photo_fill == null, "scene photo should fit its original aspect without a duplicate fill layer")
	_expect(app.active_photo_background.texture.get_size() == Vector2(4284, 5712), "event UI should load the original-resolution tennis photo")
	var event_card := app.find_child("EventCard", true, false) as PanelContainer
	var editorial_view := app.find_child("EditorialEventView", true, false) as Control
	var photo_stage := app.find_child("PhotoStage", true, false) as Control
	var event_narrative := app.find_child("EventNarrative", true, false) as Control
	var choice_list := app.find_child("ChoiceList", true, false) as VBoxContainer
	_expect(event_card == null, "event choices should no longer be wrapped in the legacy glass card")
	_expect(editorial_view != null and photo_stage != null and event_narrative != null and choice_list != null, "event screen should use the full-canvas editorial composition")
	_expect(editorial_view.get_meta("photo_layout_mode") == "portrait", "vertical originals should select the portrait event layout")
	_expect(photo_stage.position.x > 640.0 and photo_stage.size == Vector2(456, 540), "right-hand vertical originals should occupy only their dedicated magazine page")
	_expect(app.find_child("PhotoPresentationLabel", true, false) == null, "event photos should not expose internal presentation terminology")
	_expect(not _has_label_containing(app, "完整比例"), "event UI should not show photo-layout debug copy to players")
	var editorial_choice := app.find_child("Choice_continue", true, false) as Button
	_expect(editorial_choice != null and editorial_choice.get_node_or_null("GlassHoverController") == null, "editorial choices should use text-and-rule focus rather than card lift")
	if editorial_choice != null:
		var editorial_marker := editorial_choice.get_node_or_null("ChoiceMarker") as ColorRect
		var editorial_copy := editorial_choice.get_node_or_null("ChoiceCopy") as Control
		editorial_choice.mouse_entered.emit()
		await create_timer(0.18).timeout
		_expect(editorial_marker != null and editorial_marker.modulate.a > 0.9, "editorial choice hover should reveal the SDU-red margin marker")
		_expect(editorial_copy != null and editorial_copy.position.x > 18.0, "editorial choice hover should shift typography without lifting a box")
		editorial_choice.mouse_exited.emit()
		editorial_choice.grab_focus()
		await create_timer(0.18).timeout
		_expect(editorial_marker.modulate.a > 0.9, "keyboard focus should expose the same visible editorial choice marker")
	app.session.current_location_id = "teaching"
	app.session.current_background_path = "res://assets/backgrounds/locations/teaching/理综楼走廊.jpg"
	app.show_event({
		"id": "orientation_ui_test",
		"title": "来到{scene_name}",
		"speaker": "旁白",
		"body": "确认原图方向。",
		"choices": [{"id": "ok", "label": "继续", "effects": []}],
	})
	await process_frame
	_expect(_has_label_containing(app, "理综楼走廊"), "teaching event should show the exact building scene name")
	_expect(is_equal_approx(absf(app.active_photo_background.rotation), PI * 0.5), "EXIF orientation six should rotate the untouched original at display time")
	app.session.current_background_path = "res://assets/backgrounds/locations/teaching/理综楼.jpg"
	app.show_event({
		"id": "editorial_ui_test",
		"title": "理综楼里的考前整理",
		"speaker": "旁白",
		"body": "保留四比三原图，不把建筑裁成伪全屏。",
		"choices": [{"id": "ok", "label": "确认下一项安排", "effects": []}],
	})
	await process_frame
	var editorial_building_view := app.find_child("EditorialEventView", true, false) as Control
	var editorial_building_stage := app.find_child("PhotoStage", true, false) as Control
	_expect(editorial_building_view != null and editorial_building_view.get_meta("photo_layout_mode") == "editorial", "four-by-three building photos should select the editorial spread")
	_expect(editorial_building_stage != null and editorial_building_stage.size == Vector2(640, 480), "editorial building photos should retain a four-by-three display plate")
	app.session.current_location_id = "canteen"
	app.session.current_background_path = "res://assets/backgrounds/locations/canteen/水果/30c11daead283879b3c1714fad9a425e.jpg"
	var canteen_context: Dictionary = app.background_catalog.get_active_scene_context(app.session)
	var canteen_data: Dictionary = app._base_scene_data(canteen_context, app.session.current_background_path)
	canteen_data.merge({
		"panel_name": "LocationCard",
		"section": "地点行动",
		"title": "抵达 · 齐园餐厅 · 水果区",
		"body": "你准备挑些水果补充能量。",
		"question": "这个时段，你准备做什么？",
		"cost_text": "行动后推进 1 个时段",
		"state_tags": [],
		"choices": [],
	}, true)
	app._show_adaptive_scene("location", canteen_data)
	await process_frame
	_expect(app.current_screen == "location", "canteen should open its location action screen")
	_expect(not _has_label_containing(app, "SCENE") and not _has_label_containing(app, "完整比例"), "location photo stage should hide internal scene and aspect-ratio labels")
	_expect(_has_label_containing(app, "齐园餐厅 · 水果区"), "location photo stage should retain the real player-facing place name")

	app.show_pause_menu()
	await process_frame
	_expect(app.current_screen == "pause", "pause menu should open")
	app.show_settings("pause")
	await process_frame
	_expect(app.current_screen == "settings", "settings should open from pause")
	_expect(app.find_child("MusicVolume", true, false) != null and app.find_child("SFXVolume", true, false) != null and app.find_child("AmbienceVolume", true, false) != null, "settings should expose separate music, interaction, and ambience volumes")
	_expect(app.find_child("PressureAudio", true, false) != null, "settings should expose the optional pressure-audio control")
	var music_volume := app.find_child("MusicVolume", true, false) as HSlider
	_expect(music_volume != null and music_volume.has_theme_stylebox_override("grabber_area"), "settings sliders should use the unified luminous glass rail")
	app.session.difficulty_id = "medium"
	app.session.stats.stress = DifficultyRules.get_crisis_threshold("medium")
	app._advance_after_action()
	_expect(await _wait_for_screen(app, "stress_crisis"), "high stress should automatically open the disorientation choice screen after an action")
	_expect(ambience != null and ambience.is_stress_layer_playing(), "stress crisis should add the optional body-feedback sound layer")
	_expect(app.active_photo_background != null, "stress crisis should use the long-exposure photograph")
	var stress_before := int(app.session.stats.stress)
	var recover_button := app.find_child("StressRecover", true, false) as Button
	_expect(recover_button != null, "stress crisis responses should use interactive choice cards")
	recover_button.pressed.emit()
	await process_frame
	_expect(int(app.session.stats.stress) < stress_before, "choosing to recover should lower stress")
	_expect(app._photo_texture_cache.size() <= 4, "photo cache should remain bounded after visiting several original-resolution scenes")
	app.save_service.delete_save()
	app.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	var audio_director := root.get_node_or_null("ProjectUISoundController") as AudioDirector
	if audio_director != null:
		await create_timer(0.25).timeout
		audio_director.prepare_for_shutdown()
		await process_frame
	if ambience != null:
		ambience.prepare_for_shutdown()
		await process_frame
		await create_timer(0.25).timeout

	if failures.is_empty():
		print("[METRIC] immediate choice feedback %.2f ms; immediate travel acknowledgement %.2f ms" % [choice_click_ms, travel_click_ms])
		print("[PASS] UI smoke: %d checks passed" % checks)
		quit(0)
	else:
		for failure in failures:
			printerr("[FAIL] %s" % failure)
		quit(1)
