class_name EndingEvaluator
extends RefCounted


func evaluate(session: GameSession, endings: Array) -> Dictionary:
	var engine := EventEngine.new()
	var sorted_endings := endings.duplicate(true)
	sorted_endings.sort_custom(func(a, b): return int(a.get("priority", 0)) > int(b.get("priority", 0)))
	for ending in sorted_endings:
		if engine.requirements_match(ending.get("requirements", []), session):
			return ending
	return {
		"id": "balanced_default",
		"title": "继续前进的人",
		"description": "期末周没有完美答案，但你承担了自己的选择，也找到了下一步。",
	}
