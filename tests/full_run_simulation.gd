extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	var repository := ContentRepository.new()
	if not repository.load_all():
		_fail("content failed validation: %s" % "; ".join(repository.errors))
		_finish()
		return
	_run_campaign(repository, "balanced")
	_run_campaign(repository, "study")
	_run_campaign(repository, "ai")
	_test_debug_presets(repository)
	_finish()


func _run_campaign(repository: ContentRepository, strategy: String) -> void:
	var engine := EventEngine.new(repository)
	var session := GameSession.new()
	session.reset("模拟玩家", "study" if strategy != "ai" else "project")
	var locations := ["dorm", "library", "teaching", "lab", "canteen", "field"]
	var steps := 0
	while not bool(session.flags.get("presentation_completed", false)) and not session.clock.is_finished() and steps < 40:
		var event := engine.get_fixed_event(session)
		if event.is_empty():
			var location_id := _strategy_location(strategy, session.clock.get_index(), locations)
			event = engine.get_location_event(location_id, session)
			if event.is_empty():
				var location := repository.get_location(location_id)
				engine.apply_fallback_action(_strategy_action(strategy, location.get("actions", [])), session)
			else:
				engine.apply_choice(event, _strategy_choice(strategy, event), session)
		else:
			engine.apply_choice(event, _strategy_choice(strategy, event), session)
		var transition := session.clock.advance()
		if bool(transition.get("day_changed", false)):
			session.change_stat("energy", 7)
			session.change_stat("stress", -2)
		engine.process_due_consequences(session)
		steps += 1
	if steps >= 40:
		_fail("%s campaign exceeded the safe step count" % strategy)
	if not bool(session.flags.get("presentation_completed", false)):
		_fail("%s campaign did not reach the presentation" % strategy)
	if session.clock.day != 7:
		_fail("%s campaign should finish on day seven" % strategy)
	var ending := EndingEvaluator.new().evaluate(session, repository.endings)
	if str(ending.get("id", "")).is_empty():
		_fail("%s campaign should resolve an ending" % strategy)
	print("[SIM] %s: %d steps, ending=%s, study=%d, project=%d, stress=%d, ai=%d" % [strategy, steps, ending.get("id"), session.stats.study, session.stats.project, session.stats.stress, session.stats.ai_dependence])


func _strategy_location(strategy: String, index: int, locations: Array) -> String:
	match strategy:
		"study":
			return "library" if index % 2 == 0 else "teaching"
		"ai":
			var ai_route := ["library", "lab", "dorm", "lab", "field", "canteen"]
			return ai_route[index % ai_route.size()]
		_:
			return locations[index % locations.size()]


func _strategy_choice(strategy: String, event: Dictionary) -> Dictionary:
	var choices: Array = event.get("choices", [])
	if strategy == "ai":
		var preferred := ["ask_ai", "copy", "follow_numbers", "memorized", "polish", "trust", "paste", "obey", "use", "ai"]
		for choice in choices:
			if preferred.has(str(choice.get("id", ""))):
				return choice
	if strategy == "study":
		for choice in choices:
			if str(choice.get("id", "")) in ["plan", "record", "reason", "reasoning", "focus", "questions", "solve", "compare", "verify"]:
				return choice
	return choices[0]


func _strategy_action(strategy: String, actions: Array) -> Dictionary:
	if strategy == "study":
		for action in actions:
			if str(action.get("id", "")) in ["review", "organize", "self_study", "ask_teacher"]:
				return action
	return actions[0]


func _test_debug_presets(repository: ContentRepository) -> void:
	for preset_id in DebugPresets.AVAILABLE:
		var session := GameSession.new()
		if not DebugPresets.apply(session, preset_id):
			_fail("debug preset %s should apply" % preset_id)
		if session.clock.day != 7 or session.clock.slot != 2:
			_fail("debug preset %s should target the presentation slot" % preset_id)
		var presentation := EventEngine.new(repository).get_fixed_event(session)
		if presentation.get("id") != "fixed_presentation":
			_fail("debug preset %s should open the presentation" % preset_id)


func _fail(message: String) -> void:
	failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("[PASS] full campaign simulations completed")
		quit(0)
	else:
		for failure in failures:
			printerr("[FAIL] %s" % failure)
		quit(1)
