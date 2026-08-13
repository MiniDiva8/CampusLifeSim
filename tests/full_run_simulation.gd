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
	_run_campaign(repository, "balanced", "medium")
	_run_campaign(repository, "balanced", "hard")
	_run_campaign(repository, "careless", "medium")
	_test_debug_presets(repository)
	_finish()


func _run_campaign(repository: ContentRepository, strategy: String, difficulty_id: String = "easy") -> void:
	var engine := EventEngine.new(repository)
	var session := GameSession.new()
	session.reset("模拟玩家", "study" if strategy != "ai" else "project", difficulty_id)
	var locations := ["dorm", "library", "teaching", "lab", "canteen", "field"]
	var time_decisions := 0
	while not bool(session.flags.get("presentation_completed", false)) and not session.clock.is_finished() and time_decisions < 28:
		var event := engine.get_fixed_event(session)
		var time_cost := DecisionRules.ACTION_COST
		if not event.is_empty():
			var fixed_choice := _strategy_choice(strategy, event)
			engine.apply_choice(event, fixed_choice, session)
			time_cost = DecisionRules.event_time_cost(event, fixed_choice)
		elif DecisionRules.needs_commitment(session):
			DecisionRules.begin_commitment(session, _strategy_commitment(strategy, session))
			continue
		else:
			var location_id := _strategy_location(strategy, session.clock.get_index(), locations)
			event = engine.get_location_event(location_id, session)
			if event.is_empty():
				var location := repository.get_location(location_id)
				var fallback_action := _strategy_action(strategy, location.get("actions", []))
				engine.apply_fallback_action(fallback_action, session)
				time_cost = int(fallback_action.get("time_cost", DecisionRules.EXPLORATION_COST))
			else:
				var location_choice := _strategy_choice(strategy, event)
				engine.apply_choice(event, location_choice, session)
				time_cost = DecisionRules.event_time_cost(event, location_choice)
		_advance_campaign(engine, session, time_cost)
		time_decisions += 1

	if time_decisions >= 28:
		_fail("%s campaign exceeded the compressed-decision limit" % strategy)
	if time_decisions > 21:
		_fail("%s campaign should use at most twenty-one time-consuming decisions, got %d" % [strategy, time_decisions])
	if session.decision_count < time_decisions:
		_fail("%s campaign should record every meaningful decision" % strategy)
	if not session.flags.has("exam_outcome") or not session.flags.has("presentation_outcome"):
		_fail("%s campaign should settle both milestone quality outcomes" % strategy)
	if not bool(session.flags.get("presentation_completed", false)):
		_fail("%s campaign did not reach the presentation" % strategy)
	if session.clock.day != 7:
		_fail("%s campaign should finish on day seven" % strategy)
	var ending := EndingEvaluator.new().evaluate(session, repository.endings)
	if str(ending.get("id", "")).is_empty():
		_fail("%s campaign should resolve an ending" % strategy)
	if strategy == "ai" and ending.get("id") != "ai_overdependence":
		_fail("blind-AI campaign should end in AI overdependence, got %s" % ending.get("id"))
	if strategy == "careless" and ending.get("id") in ["all_round", "ai_partner"]:
		_fail("careless campaign should not earn a high-quality ending, got %s" % ending.get("id"))
	print("[SIM] %s/%s: %d time choices, %d total decisions, ending=%s, exam=%s, presentation=%s, debt=%s" % [
		strategy,
		difficulty_id,
		time_decisions,
		session.decision_count,
		ending.get("id"),
		session.flags.get("exam_outcome", "missing"),
		session.flags.get("presentation_outcome", "missing"),
		DecisionRules.debt_risk_summary(session),
	])


func _advance_campaign(engine: EventEngine, session: GameSession, time_cost: int) -> void:
	var previous_day := session.clock.day
	var target_index := mini(GameClock.DAYS * GameClock.SLOTS_PER_DAY, session.clock.get_index() + maxi(time_cost, 1))
	var next_fixed_index := engine.get_next_fixed_index(session, target_index)
	if next_fixed_index >= 0:
		target_index = next_fixed_index
	var transition := session.clock.advance(target_index - session.clock.get_index())
	if bool(transition.get("day_changed", false)) and not session.clock.is_finished():
		DecisionRules.settle_commitment(session, previous_day)
		DecisionRules.settle_sleep_debt(session, previous_day)
		var energy_recovery := DifficultyRules.adjust_effect_amount("stat", "energy", 7, session.difficulty_id)
		var stress_relief := DifficultyRules.adjust_effect_amount("stat", "stress", -2, session.difficulty_id)
		session.change_stat("energy", energy_recovery)
		session.change_stat("stress", stress_relief)
		engine.process_due_consequences(session)
	else:
		engine.process_due_consequences(session)


func _strategy_location(strategy: String, index: int, locations: Array) -> String:
	match strategy:
		"study":
			return "library" if index % 2 == 0 else "teaching"
		"ai":
			var day := int(index / GameClock.SLOTS_PER_DAY) + 1
			if day <= 2:
				return "library"
			if day == 3:
				return "dorm" if index < 13 else "lab"
			if day == 4:
				return "dorm"
			return "lab"
		"careless":
			var careless_route := ["dorm", "lab", "lab", "dorm", "canteen", "lab"]
			return careless_route[index % careless_route.size()]
		_:
			return locations[index % locations.size()]


func _strategy_choice(strategy: String, event: Dictionary) -> Dictionary:
	var choices: Array = event.get("choices", [])
	if strategy == "ai":
		var preferred := ["ask_ai", "copy", "follow_numbers", "memorized", "polish", "trust", "paste", "obey", "use", "ai"]
		for choice in choices:
			if preferred.has(str(choice.get("id", ""))):
				return choice
	if strategy == "careless":
		var shortcuts := ["react", "more", "follow_numbers", "memorized", "fake", "polish", "copy_notes", "guess", "his_machine", "delegate", "decline", "trust", "paste", "obey", "use", "ai", "stay_up"]
		for choice in choices:
			if shortcuts.has(str(choice.get("id", ""))):
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
	if strategy in ["ai", "careless"]:
		for action in actions:
			if str(action.get("id", "")) in ["night_work", "rush", "copy"]:
				return action
	return actions[0]


func _strategy_commitment(strategy: String, session: GameSession) -> String:
	var preferred := "exam"
	match strategy:
		"study":
			preferred = "exam"
		"ai":
			preferred = "project"
		"careless":
			preferred = "recovery"
		_:
			preferred = ["exam", "project", "social", "verification"][session.clock.day % 4]
	var available: Array = DecisionRules.get_commitment_options(session)
	for option in available:
		if str(option.get("id", "")) == preferred:
			return preferred
	return str(available[0].get("id", "exam"))


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
