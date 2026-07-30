class_name GameSession
extends RefCounted

const RouteRulesScript = preload("res://scripts/core/route_rules.gd")
const SCHEMA_VERSION := 2
const DEFAULT_SEED := 20260722
const STAT_KEYS := ["study", "project", "energy", "stress", "ai_dependence"]
const RELATIONSHIP_KEYS := ["roommate", "teammate", "scholar", "monitor"]

var player_name := "小山"
var trait_id := "study"
var difficulty_id := DifficultyRules.LEGACY_DIFFICULTY
var run_seed := DEFAULT_SEED
var clock := GameClock.new()
var stats: Dictionary = {}
var relationships: Dictionary = {}
var tasks: Dictionary = {}
var flags: Dictionary = {}
var fired_events: Array = []
var pending_consequences: Array = []
var event_history: Array = []
var current_location_id := ""
var current_background_path := ""
var last_location_backgrounds: Dictionary = {}
var last_road_background := ""
var background_choice_counter := 0
var debts: Dictionary = {}
var active_commitment := ""
var commitment_day := 0
var commitment_progress := 0
var commitments_history: Array = []
var decision_count := 0
var consequence_history: Array = []


func _init() -> void:
	reset()


func reset(name_value: String = "小山", selected_trait: String = "study", selected_difficulty: String = DifficultyRules.LEGACY_DIFFICULTY) -> void:
	player_name = name_value.strip_edges() if not name_value.strip_edges().is_empty() else "小山"
	trait_id = RouteRulesScript.normalize(selected_trait)
	difficulty_id = DifficultyRules.normalize(selected_difficulty)
	run_seed = DEFAULT_SEED
	clock.reset()
	stats = {
		"study": 15,
		"project": 10,
		"energy": 80,
		"stress": 20,
		"ai_dependence": 10,
	}
	relationships = {
		"roommate": 40,
		"teammate": 40,
		"scholar": 40,
		"monitor": 40,
	}
	tasks = {"exam": 0, "presentation": 0}
	flags = {"game_started": true}
	fired_events = []
	pending_consequences = []
	event_history = []
	current_location_id = ""
	current_background_path = ""
	last_location_backgrounds = {}
	last_road_background = ""
	background_choice_counter = 0
	debts = {"sleep": 0, "technical": 0, "social": 0, "ai_risk": 0}
	active_commitment = ""
	commitment_day = 0
	commitment_progress = 0
	commitments_history = []
	decision_count = 0
	consequence_history = []
	apply_trait(trait_id)


func apply_trait(selected_trait: String) -> void:
	trait_id = RouteRulesScript.normalize(selected_trait)
	match trait_id:
		"project":
			stats["project"] += 10
		"social":
			for relationship_id in RELATIONSHIP_KEYS:
				relationships[relationship_id] += 5
		_:
			stats["study"] += 10
	clamp_all()


func clamp_all() -> void:
	for key in STAT_KEYS:
		stats[key] = clampi(int(stats.get(key, 0)), 0, 100)
	for key in RELATIONSHIP_KEYS:
		relationships[key] = clampi(int(relationships.get(key, 0)), 0, 100)
	for key in tasks.keys():
		tasks[key] = clampi(int(tasks[key]), 0, 100)
	for key in debts.keys():
		debts[key] = clampi(int(debts[key]), 0, 9)


func change_stat(stat_id: String, amount: int) -> int:
	if not stats.has(stat_id):
		push_error("Unknown stat: %s" % stat_id)
		return 0
	var before := int(stats[stat_id])
	stats[stat_id] = clampi(before + amount, 0, 100)
	return int(stats[stat_id]) - before


func change_relationship(npc_id: String, amount: int) -> int:
	if not relationships.has(npc_id):
		push_error("Unknown relationship: %s" % npc_id)
		return 0
	var before := int(relationships[npc_id])
	relationships[npc_id] = clampi(before + amount, 0, 100)
	return int(relationships[npc_id]) - before


func change_task(task_id: String, amount: int) -> int:
	var before := int(tasks.get(task_id, 0))
	tasks[task_id] = clampi(before + amount, 0, 100)
	return int(tasks[task_id]) - before


func change_debt(debt_id: String, amount: int) -> int:
	var before := int(debts.get(debt_id, 0))
	debts[debt_id] = clampi(before + amount, 0, 9)
	return int(debts[debt_id]) - before


func average_relationship() -> float:
	var total := 0.0
	for value in relationships.values():
		total += float(value)
	return total / maxf(float(relationships.size()), 1.0)


func has_fired(event_id: String) -> bool:
	return fired_events.has(event_id)


func mark_event_fired(event_id: String, choice_id: String) -> void:
	if not fired_events.has(event_id):
		fired_events.append(event_id)
	event_history.append({
		"event_id": event_id,
		"choice_id": choice_id,
		"clock_index": clock.get_index(),
	})


func clear_current_background() -> void:
	current_location_id = ""
	current_background_path = ""


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"player_name": player_name,
		"trait_id": trait_id,
		"difficulty_id": difficulty_id,
		"run_seed": run_seed,
		"clock": clock.to_dict(),
		"stats": stats.duplicate(true),
		"relationships": relationships.duplicate(true),
		"tasks": tasks.duplicate(true),
		"flags": flags.duplicate(true),
		"fired_events": fired_events.duplicate(true),
		"pending_consequences": pending_consequences.duplicate(true),
		"event_history": event_history.duplicate(true),
		"current_location_id": current_location_id,
		"current_background_path": current_background_path,
		"last_location_backgrounds": last_location_backgrounds.duplicate(true),
		"last_road_background": last_road_background,
		"background_choice_counter": background_choice_counter,
		"debts": debts.duplicate(true),
		"active_commitment": active_commitment,
		"commitment_day": commitment_day,
		"commitment_progress": commitment_progress,
		"commitments_history": commitments_history.duplicate(true),
		"decision_count": decision_count,
		"consequence_history": consequence_history.duplicate(true),
	}


func from_dict(data: Dictionary) -> bool:
	var source_schema := int(data.get("schema_version", -1))
	if source_schema not in [1, SCHEMA_VERSION]:
		return false
	player_name = str(data.get("player_name", "小山"))
	trait_id = RouteRulesScript.normalize(str(data.get("trait_id", "study")))
	difficulty_id = DifficultyRules.normalize(str(data.get("difficulty_id", DifficultyRules.LEGACY_DIFFICULTY)))
	run_seed = int(data.get("run_seed", DEFAULT_SEED))
	clock.from_dict(data.get("clock", {}))
	stats = data.get("stats", {}).duplicate(true)
	relationships = data.get("relationships", {}).duplicate(true)
	tasks = data.get("tasks", {}).duplicate(true)
	flags = data.get("flags", {}).duplicate(true)
	fired_events = data.get("fired_events", []).duplicate(true)
	pending_consequences = data.get("pending_consequences", []).duplicate(true)
	event_history = data.get("event_history", []).duplicate(true)
	current_location_id = str(data.get("current_location_id", ""))
	current_background_path = str(data.get("current_background_path", ""))
	last_location_backgrounds = data.get("last_location_backgrounds", {}).duplicate(true)
	last_road_background = str(data.get("last_road_background", ""))
	background_choice_counter = maxi(int(data.get("background_choice_counter", 0)), 0)
	debts = data.get("debts", {"sleep": 0, "technical": 0, "social": 0, "ai_risk": 0}).duplicate(true)
	for debt_id in ["sleep", "technical", "social", "ai_risk"]:
		if not debts.has(debt_id):
			debts[debt_id] = 0
	active_commitment = str(data.get("active_commitment", ""))
	commitment_day = int(data.get("commitment_day", 0))
	commitment_progress = int(data.get("commitment_progress", 0))
	commitments_history = data.get("commitments_history", []).duplicate(true)
	decision_count = maxi(int(data.get("decision_count", 0)), 0)
	consequence_history = data.get("consequence_history", []).duplicate(true)
	for key in STAT_KEYS:
		if not stats.has(key):
			return false
	for key in RELATIONSHIP_KEYS:
		if not relationships.has(key):
			return false
	clamp_all()
	return true
