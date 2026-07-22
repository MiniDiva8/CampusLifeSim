class_name EventEngine
extends RefCounted

var repository: ContentRepository


func _init(content_repository: ContentRepository = null) -> void:
	repository = content_repository


func condition_matches(condition: Dictionary, session: GameSession) -> bool:
	var condition_type := str(condition.get("type", ""))
	var target := str(condition.get("target", ""))
	var expected = condition.get("value", 0)
	match condition_type:
		"stat_min":
			return int(session.stats.get(target, 0)) >= int(expected)
		"stat_max":
			return int(session.stats.get(target, 0)) <= int(expected)
		"relationship_min":
			return int(session.relationships.get(target, 0)) >= int(expected)
		"relationship_max":
			return int(session.relationships.get(target, 0)) <= int(expected)
		"task_min":
			return int(session.tasks.get(target, 0)) >= int(expected)
		"task_max":
			return int(session.tasks.get(target, 0)) <= int(expected)
		"flag":
			return session.flags.get(target, false) == expected
		"event_fired":
			return session.has_fired(target) == bool(expected)
		"day_min":
			return session.clock.day >= int(expected)
		"day_max":
			return session.clock.day <= int(expected)
		"slot":
			return session.clock.slot == int(expected)
		_:
			push_warning("Unknown condition type: %s" % condition_type)
			return false


func requirements_match(requirements, session: GameSession) -> bool:
	if not requirements is Array:
		return false
	for condition in requirements:
		if not condition_matches(condition, session):
			return false
	return true


func event_can_trigger(event: Dictionary, session: GameSession, location_id: String = "") -> bool:
	if bool(event.get("once", true)) and session.has_fired(str(event.get("id", ""))):
		return false
	if not requirements_match(event.get("requirements", []), session):
		return false
	var trigger: Dictionary = event.get("trigger", {})
	match str(trigger.get("type", "")):
		"fixed":
			return session.clock.day == int(trigger.get("day", -1)) and session.clock.slot == int(trigger.get("slot", -1))
		"location":
			if str(trigger.get("location", "")) != location_id:
				return false
			var days = trigger.get("days", [])
			var slots = trigger.get("slots", [])
			return (days.is_empty() or days.has(session.clock.day)) and (slots.is_empty() or slots.has(session.clock.slot))
		_:
			return false


func get_fixed_event(session: GameSession) -> Dictionary:
	for event in repository.events:
		if str(event.get("trigger", {}).get("type", "")) == "fixed" and event_can_trigger(event, session):
			return event
	return {}


func get_location_event(location_id: String, session: GameSession) -> Dictionary:
	var candidates: Array = []
	for event in repository.events:
		if str(event.get("trigger", {}).get("type", "")) == "location" and event_can_trigger(event, session, location_id):
			candidates.append(event)
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a, b): return int(a.get("priority", 0)) > int(b.get("priority", 0)))
	return candidates[0]


func apply_choice(event: Dictionary, choice: Dictionary, session: GameSession) -> Array[String]:
	var result: Array[String] = []
	for effect in choice.get("effects", []):
		result.append(_apply_effect(effect, session))
	for delayed in choice.get("delayed", []):
		var queued: Dictionary = delayed.duplicate(true)
		queued["due_index"] = session.clock.get_index() + int(delayed.get("after_slots", 1))
		session.pending_consequences.append(queued)
		result.append("一个后果将在之后显现")
	session.mark_event_fired(str(event.get("id", "")), str(choice.get("id", "")))
	session.clamp_all()
	return result


func apply_fallback_action(action: Dictionary, session: GameSession) -> Array[String]:
	var result: Array[String] = []
	for effect in action.get("effects", []):
		result.append(_apply_effect(effect, session))
	session.clamp_all()
	return result


func process_due_consequences(session: GameSession) -> Array[Dictionary]:
	var resolved: Array[Dictionary] = []
	var remaining: Array = []
	for consequence in session.pending_consequences:
		if int(consequence.get("due_index", 999)) <= session.clock.get_index():
			var messages: Array[String] = []
			for effect in consequence.get("effects", []):
				messages.append(_apply_effect(effect, session))
			resolved.append({
				"title": consequence.get("title", "延迟后果"),
				"message": consequence.get("message", "之前的选择产生了新的影响。"),
				"effects": messages,
			})
		else:
			remaining.append(consequence)
	session.pending_consequences = remaining
	session.clamp_all()
	return resolved


func _apply_effect(effect: Dictionary, session: GameSession) -> String:
	var effect_type := str(effect.get("type", ""))
	var target := str(effect.get("target", ""))
	var amount := int(effect.get("amount", 0))
	match effect_type:
		"stat":
			var changed := session.change_stat(target, amount)
			return "%s %s%d" % [_display_target(target), "+" if changed >= 0 else "", changed]
		"relationship":
			var changed := session.change_relationship(target, amount)
			return "%s关系 %s%d" % [_display_target(target), "+" if changed >= 0 else "", changed]
		"task":
			var changed := session.change_task(target, amount)
			return "%s %s%d" % [_display_target(target), "+" if changed >= 0 else "", changed]
		"flag":
			session.flags[target] = effect.get("value", true)
			return str(effect.get("message", "新的事件线索已记录"))
		_:
			push_error("Unknown effect type: %s" % effect_type)
			return "未知效果"


func _display_target(target: String) -> String:
	return {
		"study": "学习",
		"project": "项目",
		"energy": "精力",
		"stress": "压力",
		"ai_dependence": "AI依赖",
		"roommate": "室友",
		"teammate": "组员",
		"scholar": "学霸同学",
		"monitor": "班长",
		"exam": "考试准备",
		"presentation": "展示准备",
	}.get(target, target)
