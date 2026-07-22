class_name AIAdvisor
extends RefCounted

var advice_entries: Array = []


func _init(entries: Array = []) -> void:
	advice_entries = entries


func choose_advice(session: GameSession) -> Dictionary:
	var candidates: Array = []
	var engine := EventEngine.new()
	for entry in advice_entries:
		if engine.requirements_match(entry.get("requirements", []), session):
			candidates.append(entry)
	if candidates.is_empty():
		return {
			"id": "default",
			"title": "先看最紧迫的事",
			"message": "建议比较考试、项目和你的精力，再决定下一步。别忘了，建议不是命令。",
			"risk": "信息有限，请自行核对日程。",
		}
	var rng := RandomNumberGenerator.new()
	rng.seed = session.run_seed + session.clock.get_index() * 101 + int(session.stats.get("ai_dependence", 0)) * 17
	return candidates[rng.randi_range(0, candidates.size() - 1)]
