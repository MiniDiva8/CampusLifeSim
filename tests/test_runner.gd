extends SceneTree

const AmbientSoundControllerScript = preload("res://scripts/services/ambient_sound_controller.gd")
const RouteRulesScript = preload("res://scripts/core/route_rules.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	print("[TEST] CampusLifeSim native test suite")
	_test_content_repository()
	_test_background_catalog()
	_test_clock()
	_test_session_and_clamping()
	_test_difficulty_rules()
	_test_route_rules()
	_test_event_conditions_and_delays()
	_test_ai_determinism()
	_test_audio_foundation()
	_test_ambience_contract()
	_test_runtime_loading_surface()
	_test_save_round_trip()
	_test_endings_reachable()
	if failures.is_empty():
		print("[PASS] %d checks passed" % checks)
		quit(0)
	else:
		for failure in failures:
			printerr("[FAIL] %s" % failure)
		printerr("[FAIL] %d of %d checks failed" % [failures.size(), checks])
		quit(1)


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _test_content_repository() -> void:
	var repository := ContentRepository.new()
	_expect(repository.load_all(), "content repository should validate: %s" % "; ".join(repository.errors))
	_expect(repository.locations.size() == 6, "six locations should load")
	_expect(repository.events.size() == 32, "thirty-two events should load")
	_expect(repository.endings.size() == 7, "seven endings should load")
	var kind_counts := {"fixed": 0, "location": 0, "npc": 0, "ai": 0}
	for event in repository.events:
		var kind := str(event.get("kind", ""))
		kind_counts[kind] = int(kind_counts.get(kind, 0)) + 1
	_expect(kind_counts == {"fixed": 8, "location": 12, "npc": 8, "ai": 4}, "event category counts should match the demo scope")
	for npc in repository.npcs:
		_expect(not str(npc.get("location", "")).is_empty() and not npc.get("contact", {}).is_empty(), "every map companion should provide a location and repeatable contact action")
	for event in repository.events:
		if str(event.get("kind", "")) == "npc":
			_expect(not str(event.get("npc_id", "")).is_empty(), "every NPC event should identify its companion explicitly")


func _test_background_catalog() -> void:
	var catalog := BackgroundCatalog.new()
	_expect(catalog.load_all(), "background catalog should validate: %s" % "; ".join(catalog.errors))
	var location_total := 0
	for options in catalog.locations.values():
		location_total += options.size()
	_expect(catalog.menu.size() == 1, "one menu background should load")
	_expect(not catalog.get_stress_background().is_empty(), "one long-exposure stress background should load")
	_expect(location_total == 46, "forty-six location backgrounds should load")
	_expect(catalog.scenes.size() == 16, "sixteen named teaching and sports scenes should load")
	_expect(catalog.presentations.size() == 6, "six representative photos should carry explicit editorial presentation metadata")
	_expect(catalog.roads.get("day", []).size() == 13 and catalog.roads.get("night", []).size() == 4, "seventeen day and night travel backgrounds should load")
	var tennis_path := "res://assets/backgrounds/locations/field/网球.jpg"
	var tennis_context := catalog.get_scene_context(tennis_path, "field")
	_expect(tennis_context.display_name == "中心校区室外网球场" and tennis_context.activity_text == "打网球", "tennis photo should provide its real SDU scene and activity names")
	var tennis_presentation := catalog.get_photo_presentation(tennis_path, Vector2(4284, 5712))
	_expect(tennis_presentation.presentation_mode == "portrait" and tennis_presentation.photo_side == "right", "vertical tennis original should use the right-hand magazine spread")
	var future_wide := catalog.get_photo_presentation("res://future-landscape.jpg", Vector2(3840, 2160))
	_expect(future_wide.presentation_mode == "cinematic", "future sixteen-by-nine originals should automatically use the full-screen cinematic layout")
	var current_four_by_three := catalog.get_photo_presentation("res://current-four-by-three.jpg", Vector2(5712, 4284))
	_expect(current_four_by_three.presentation_mode == "editorial", "current four-by-three originals should use a no-crop editorial layout")
	var teaching_context := catalog.get_scene_context("res://assets/backgrounds/locations/teaching/理综楼走廊.jpg", "teaching")
	_expect(teaching_context.display_name == "理综楼走廊", "teaching photo should expose its exact filename-based place")
	_expect(catalog.get_photo_orientation("res://assets/backgrounds/locations/teaching/理综楼走廊.jpg") == 6, "EXIF-oriented originals should keep their display rotation metadata")
	var meal_context := catalog.get_scene_context("res://assets/backgrounds/locations/canteen/早餐/8969be5d9c0b20d7439da056e4fd3b7a.jpg", "canteen")
	_expect(meal_context.display_name == "齐园餐厅 · 早餐", "canteen subfolder should provide the official Qiyuan scene name")
	_expect(catalog.event_scenes.get("fixed_exam", "") == "res://assets/backgrounds/locations/teaching/董明珠楼.jpg", "fixed exam should use the verified Dongmingzhu Building scene")
	var tennis_texture := load(tennis_path) as Texture2D
	_expect(tennis_texture != null and tennis_texture.get_size() == Vector2(4284, 5712), "tennis photo should retain its original 4284 by 5712 resolution")
	var session := GameSession.new()
	var first := catalog.choose_location_background("library", session)
	var second := catalog.choose_location_background("library", session)
	_expect(not first.is_empty() and first != second, "location backgrounds should avoid an immediate repeat")
	var first_road := catalog.choose_road_background(session)
	var second_road := catalog.choose_road_background(session)
	_expect(not first_road.is_empty() and first_road != second_road, "travel backgrounds should avoid an immediate repeat")


func _test_clock() -> void:
	var clock := GameClock.new()
	_expect(clock.get_index() == 0 and clock.get_slot_name() == "早晨", "clock should start on day one morning")
	clock.advance(5)
	_expect(clock.day == 2 and clock.slot == 0, "five slots should advance to next morning")
	clock.set_from_index(34)
	_expect(clock.day == 7 and clock.slot == 4, "index 34 should be day seven late night")
	clock.advance()
	_expect(clock.is_finished(), "clock should finish after thirty-five slots")


func _test_session_and_clamping() -> void:
	var study_session := GameSession.new()
	study_session.reset("测试玩家", "study")
	_expect(study_session.stats.study == 25, "study trait should add ten study")
	var social_session := GameSession.new()
	social_session.reset("测试玩家", "social")
	_expect(social_session.relationships.roommate == 45 and social_session.relationships.monitor == 45, "social trait should add five to every relationship")
	social_session.change_stat("energy", 999)
	social_session.change_stat("stress", -999)
	_expect(social_session.stats.energy == 100 and social_session.stats.stress == 0, "stats should clamp to zero and one hundred")


func _test_difficulty_rules() -> void:
	var engine := EventEngine.new()
	var action := {"effects": [
		{"type": "stat", "target": "study", "amount": 10},
		{"type": "task", "target": "exam", "amount": 10},
		{"type": "stat", "target": "stress", "amount": 8},
		{"type": "stat", "target": "energy", "amount": -10},
	]}
	var easy := GameSession.new()
	easy.reset("简易", "study", "easy")
	var medium := GameSession.new()
	medium.reset("中等", "study", "medium")
	var hard := GameSession.new()
	hard.reset("困难", "study", "hard")
	engine.apply_fallback_action(action, easy)
	engine.apply_fallback_action(action, medium)
	engine.apply_fallback_action(action, hard)
	_expect(easy.stats.study == 36 and medium.stats.study == 34 and hard.stats.study == 31, "academic gains should shrink as difficulty rises while honoring the study route")
	_expect(easy.tasks.exam == 11 and medium.tasks.exam == 9 and hard.tasks.exam == 6, "task gains should shrink as difficulty rises while honoring the study route")
	_expect(easy.stats.stress == 28 and medium.stats.stress == 31 and hard.stats.stress == 35, "stress gains and ambient pressure should grow as difficulty rises")
	_expect(easy.stats.energy == 70 and medium.stats.energy == 68 and hard.stats.energy == 66, "energy costs should grow as difficulty rises")
	_expect(DifficultyRules.get_crisis_threshold("easy") > DifficultyRules.get_crisis_threshold("medium") and DifficultyRules.get_crisis_threshold("medium") > DifficultyRules.get_crisis_threshold("hard"), "stress crisis thresholds should fall as difficulty rises")
	engine.apply_fallback_action(action, hard)
	engine.apply_fallback_action(action, hard)
	_expect(hard.stats.stress >= DifficultyRules.get_crisis_threshold("hard"), "repeating a stressful plan on hard should reach the disorientation threshold")
	hard.clock.day = 6
	hard.stats.energy = 20
	hard.flags.exam_completed = true
	hard.tasks.presentation = 20
	_expect(DifficultyRules.get_action_pressure(hard) == 6, "hard pressure should react to low energy and an unprepared deadline")
	var legacy_data := medium.to_dict()
	legacy_data.erase("difficulty_id")
	var legacy_session := GameSession.new()
	_expect(legacy_session.from_dict(legacy_data) and legacy_session.difficulty_id == "easy", "old saves should continue under easy rules")


func _test_route_rules() -> void:
	_expect(RouteRulesScript.get_all().size() == 3, "three strategy routes should be available")
	for route in RouteRulesScript.get_all():
		_expect(route.has_all(["id", "name", "core", "advantage", "shortcoming", "recommendation", "tendency"]), "route dossiers should explain every promised gameplay dimension")
	_expect(RouteRulesScript.adjust_effect_amount("stat", "study", 10, "study") == 11, "study route should improve study gains")
	_expect(RouteRulesScript.adjust_effect_amount("task", "presentation", 25, "study") == 24, "study route should slightly slow presentation gains")
	_expect(RouteRulesScript.adjust_effect_amount("stat", "project", 10, "project") == 11, "project route should improve project gains")
	_expect(RouteRulesScript.adjust_effect_amount("task", "exam", 25, "project") == 24, "project route should slightly slow exam gains")
	_expect(RouteRulesScript.adjust_effect_amount("relationship", "roommate", 8, "social") == 10, "social route should improve positive relationship gains")
	_expect(RouteRulesScript.adjust_effect_amount("stat", "study", 20, "social") == 19, "social route should slightly slow single-track academic gains")
	_expect(RouteRulesScript.adjust_action_pressure(1, "project") == 2, "project route should add one point of ambient action pressure")
	var study_event := {"kind": "location", "trigger": {"location": "library"}}
	var project_event := {"kind": "location", "trigger": {"location": "lab"}}
	var npc_event := {"kind": "npc", "trigger": {"location": "dorm"}}
	_expect(RouteRulesScript.get_event_priority_bonus(study_event, "study") == 35, "study route should prioritize academic location events")
	_expect(RouteRulesScript.get_event_priority_bonus(project_event, "project") == 35, "project route should prioritize project location events")
	_expect(RouteRulesScript.get_event_priority_bonus(npc_event, "social") == 30, "social route should prioritize eligible NPC events")


func _test_event_conditions_and_delays() -> void:
	var session := GameSession.new()
	var engine := EventEngine.new()
	_expect(engine.condition_matches({"type": "stat_min", "target": "energy", "value": 70}, session), "stat minimum condition should match")
	_expect(not engine.condition_matches({"type": "relationship_min", "target": "roommate", "value": 80}, session), "relationship minimum condition should reject")
	_expect(not engine.condition_matches({"type": "average_relationship_min", "value": 48}, session), "average relationship conditions should distinguish an untouched social network")
	_expect(engine.condition_matches({"type": "route", "value": "study"}, session), "route conditions should match the saved strategy route")
	var repository := ContentRepository.new()
	repository.load_all()
	var targeted_engine := EventEngine.new(repository)
	var targeted_event := targeted_engine.get_npc_event("scholar", "library", session)
	_expect(targeted_event.get("id") == "npc_scholar_exchange", "actively visiting a companion should resolve that companion's eligible event before unrelated AI events")
	var event := {"id": "test_event"}
	var choice := {
		"id": "test_choice",
		"effects": [{"type": "stat", "target": "study", "amount": 5}],
		"delayed": [{"after_slots": 2, "title": "测试后果", "message": "到期", "effects": [{"type": "stat", "target": "energy", "amount": -10}]}],
	}
	engine.apply_choice(event, choice, session)
	_expect(session.stats.study == 30 and session.pending_consequences.size() == 1, "choice should apply immediate and queue delayed effects")
	session.clock.advance(1)
	_expect(engine.process_due_consequences(session).is_empty(), "delayed consequence should not resolve early")
	session.clock.advance(1)
	var resolved := engine.process_due_consequences(session)
	_expect(resolved.size() == 1 and session.stats.energy == 70, "delayed consequence should resolve on its due slot")


func _test_ai_determinism() -> void:
	var repository := ContentRepository.new()
	repository.load_all()
	var advisor := AIAdvisor.new(repository.ai_advice)
	var session := GameSession.new()
	var first := advisor.choose_advice(session)
	var second := advisor.choose_advice(session)
	_expect(first.get("id") == second.get("id"), "AI advice should be deterministic for the same saved state")


func _test_audio_foundation() -> void:
	var expected_buses := [&"Master", &"Music", &"SFX", &"UI", &"Event", &"Stress", &"Ambience"]
	for bus_name in expected_buses:
		_expect(AudioServer.get_bus_index(bus_name) >= 0, "audio bus %s should exist" % bus_name)
	var master_bus := AudioServer.get_bus_index(&"Master")
	_expect(master_bus >= 0 and AudioServer.get_bus_effect_count(master_bus) == 1, "master bus should contain the safety limiter")
	if master_bus >= 0 and AudioServer.get_bus_effect_count(master_bus) == 1:
		_expect(AudioServer.get_bus_effect(master_bus, 0) is AudioEffectLimiter, "master bus effect should be a limiter")
	_expect(AudioDirector.CUE_PROFILES.size() >= 14, "semantic audio library should expose the planned interaction cues")
	_expect(AudioDirector.CUE_PROFILES.has(&"choice") and AudioDirector.CUE_PROFILES.has(&"location_enter"), "choices and location travel should have distinct cues")

	var settings_service := SaveService.new("user://unused_audio_save.json", "user://campus_audio_settings_test.json")
	settings_service.delete_settings()
	var defaults := settings_service.load_settings()
	_expect(defaults.has_all(["master_volume", "music_volume", "sfx_volume", "ambience_volume", "pressure_audio"]), "settings should expose the full audio mix")
	settings_service.save_settings({
		"master_volume": 1.4,
		"music_volume": -0.2,
		"sfx_volume": 0.55,
		"ambience_volume": 0.45,
		"pressure_audio": false,
	})
	var restored := settings_service.load_settings()
	_expect(restored.master_volume == 1.0 and restored.music_volume == 0.0, "loaded audio volumes should clamp to safe bounds")
	_expect(is_equal_approx(float(restored.sfx_volume), 0.55) and not bool(restored.pressure_audio), "audio settings should round-trip independently")
	settings_service.delete_settings()


func _test_ambience_contract() -> void:
	_expect(AmbientSoundControllerScript.CONTEXTS.size() == 9, "ambient system should cover menu, campus, road, and six locations")
	for location_id in [&"dorm", &"library", &"teaching", &"lab", &"canteen", &"field"]:
		_expect(AmbientSoundControllerScript.CONTEXTS.has(location_id), "ambient system should cover location %s" % location_id)
	_expect(AmbientSoundControllerScript.period_from_slot(0) == &"day", "morning should use the day soundscape")
	_expect(AmbientSoundControllerScript.period_from_slot(3) == &"evening", "evening should use the transitional soundscape")
	_expect(AmbientSoundControllerScript.period_from_slot(4) == &"night", "late night should use the night soundscape")


func _test_runtime_loading_surface() -> void:
	_expect(not FileAccess.file_exists("res://scenes/system/loading_screen.tscn"), "the retired project loading screen should not remain in the runtime project")
	_expect(not FileAccess.file_exists("res://scenes/system/scene_loader.tscn"), "the unused scene-loader autoload scene should be removed")
	_expect(not FileAccess.file_exists("res://addons/maaacks_game_template/base/loading_screen.gd"), "the retired loading-screen plugin script should not be packaged")
	_expect(not FileAccess.file_exists("res://addons/maaacks_game_template/base/scene_loader.gd"), "the retired scene-loader plugin script should not be packaged")
	var project_source := FileAccess.get_file_as_string("res://project.godot")
	var main_source := FileAccess.get_file_as_string("res://scripts/ui/main.gd")
	_expect(not project_source.contains("SceneLoader=\"*res://"), "the retired SceneLoader should not be registered as an autoload")
	_expect(not main_source.contains("_show_scene_preparation") and not main_source.contains("event_loading") and not main_source.contains("stress_crisis_loading"), "fixed events and stress crises should not retain a second loading-page branch")


func _test_save_round_trip() -> void:
	var service := SaveService.new("user://campus_test_autosave.json", "user://campus_test_settings.json")
	service.delete_save()
	var session := GameSession.new()
	session.reset("存档测试", "project")
	session.difficulty_id = "hard"
	session.clock.advance(7)
	session.change_relationship("teammate", 13)
	var catalog := BackgroundCatalog.new()
	catalog.load_all()
	catalog.choose_location_background("lab", session)
	catalog.choose_road_background(session)
	var save_error := service.save_game(session)
	_expect(save_error == OK, "autosave should succeed")
	var restored := service.load_game()
	_expect(restored != null, "autosave should load")
	if restored != null:
		_expect(restored.player_name == "存档测试" and restored.clock.get_index() == 7, "save should preserve identity and time")
		_expect(restored.relationships.teammate == 53 and restored.trait_id == "project", "save should preserve relationships and trait")
		_expect(restored.difficulty_id == "hard", "save should preserve difficulty")
		_expect(restored.current_location_id == "lab" and not restored.current_background_path.is_empty(), "save should preserve the active scene background")
		_expect(restored.background_choice_counter == 2 and not restored.last_road_background.is_empty(), "save should preserve reproducible background history")
	service.delete_save()


func _test_endings_reachable() -> void:
	var repository := ContentRepository.new()
	repository.load_all()
	var evaluator := EndingEvaluator.new()
	var scenarios := {
		"pressure_breakdown": {"stress": 95},
		"ai_overdependence": {"ai_dependence": 80},
		"all_round": {"study": 70, "project": 70, "energy": 50, "stress": 30, "relationships": 50},
		"ai_partner": {"study": 60, "project": 60, "ai_dependence": 40, "verified_ai": true},
		"study_master": {"study": 80},
		"tech_builder": {"project": 80},
		"warm_campus": {"relationships": 50},
	}
	for ending_id in scenarios:
		var session := GameSession.new()
		var scenario: Dictionary = scenarios[ending_id]
		for stat_id in ["study", "project", "energy", "stress", "ai_dependence"]:
			if scenario.has(stat_id):
				session.stats[stat_id] = scenario[stat_id]
		if scenario.has("relationships"):
			for npc_id in session.relationships:
				session.relationships[npc_id] = scenario.relationships
		if scenario.get("verified_ai", false):
			session.flags.verified_ai = true
		var result := evaluator.evaluate(session, repository.endings)
		_expect(result.get("id") == ending_id, "ending %s should be reachable, got %s" % [ending_id, result.get("id")])
