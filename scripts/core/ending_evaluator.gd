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
		"title": "惊险交卷",
		"tagline": "流程走完了，代价也没有凭空消失。",
		"description": "你完成了考试和展示，却有几处关键准备只做到勉强可用。那些没有兑现的承诺和没有偿还的债务，构成了这次期末周最真实的成绩单。",
	}
