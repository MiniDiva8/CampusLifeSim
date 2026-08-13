class_name DecisionRules
extends RefCounted

const ACTION_COST := 2
const EXPLORATION_COST := 3
const COMMITMENT_GOAL := 8
const COMMITMENT_DAYS := [1, 3, 5, 6]
const DEBT_KEYS := ["sleep", "technical", "social", "ai_risk"]

const COMMITMENTS := {
	"exam": {
		"title": "守住核心课",
		"description": "今天至少完成一次有效复习、答疑或考试准备。",
		"risk": "没有兑现会增加临考焦虑。",
		"color": "#4E8977",
	},
	"project": {
		"title": "留下可复现成果",
		"description": "今天推进项目或展示准备，并避免只追求表面进度。",
		"risk": "没有兑现会积累技术债。",
		"color": "#4B82A7",
	},
	"social": {
		"title": "回应一位同伴",
		"description": "今天认真处理一次关系、协作或已经答应的请求。",
		"risk": "没有兑现会积累人情债。",
		"color": "#A06D8B",
	},
	"recovery": {
		"title": "给身体留出余量",
		"description": "今天通过休息、吃饭或运动恢复精力、降低压力。",
		"risk": "没有兑现会继续累积睡眠债。",
		"color": "#B78335",
	},
	"verification": {
		"title": "核验一项 AI 结论",
		"description": "今天留下真实来源、可运行代码或能亲自解释的证据。",
		"risk": "没有兑现会提高 AI 风险。",
		"color": "#477DA6",
	},
}


static func needs_commitment(session: GameSession) -> bool:
	if session == null or session.clock.is_finished():
		return false
	if not COMMITMENT_DAYS.has(session.clock.day):
		return false
	return int(session.commitment_day) != session.clock.day


static func get_commitment_options(session: GameSession) -> Array:
	var ids := ["exam", "project", "social", "recovery"]
	if session.clock.day >= 3:
		ids = ["exam", "project", "social", "verification"]
	if session.clock.day >= 5:
		ids = ["project", "social", "recovery", "verification"]
	var result: Array = []
	for commitment_id in ids:
		var option: Dictionary = COMMITMENTS[commitment_id].duplicate(true)
		option["id"] = commitment_id
		result.append(option)
	return result


static func event_time_cost(event: Dictionary, choice: Dictionary = {}) -> int:
	if choice.has("time_cost"):
		return maxi(1, int(choice.get("time_cost", ACTION_COST)))
	if event.has("time_cost"):
		return maxi(1, int(event.get("time_cost", ACTION_COST)))
	return ACTION_COST if str(event.get("kind", "fixed")) == "fixed" else EXPLORATION_COST


static func begin_commitment(session: GameSession, commitment_id: String) -> void:
	if not COMMITMENTS.has(commitment_id):
		return
	session.active_commitment = commitment_id
	session.commitment_day = session.clock.day
	session.commitment_progress = 0
	session.decision_count += 1


static func register_effect(session: GameSession, effect_type: String, target: String, amount: int, value = null) -> void:
	if session.active_commitment.is_empty() or session.commitment_day != session.clock.day:
		return
	var progress := 0
	match session.active_commitment:
		"exam":
			if amount > 0 and ((effect_type == "stat" and target == "study") or (effect_type == "task" and target == "exam")):
				progress = amount
		"project":
			if amount > 0 and ((effect_type == "stat" and target == "project") or (effect_type == "task" and target == "presentation")):
				progress = amount
		"social":
			if effect_type == "relationship" and amount > 0:
				progress = amount
		"recovery":
			if (effect_type == "stat" and target == "energy" and amount > 0) or (effect_type == "stat" and target == "stress" and amount < 0):
				progress = absi(amount)
		"verification":
			if effect_type == "flag" and bool(value) and target in ["verified_ai", "environment_documented", "team_understanding", "peer_review"]:
				progress = COMMITMENT_GOAL
			elif effect_type == "debt" and target in ["technical", "ai_risk"] and amount < 0:
				progress = absi(amount) * 4
	session.commitment_progress = mini(COMMITMENT_GOAL, session.commitment_progress + progress)


static func settle_commitment(session: GameSession, completed_day: int) -> Dictionary:
	if session.commitment_day != completed_day or session.active_commitment.is_empty():
		return {}
	var commitment_id := session.active_commitment
	var commitment: Dictionary = COMMITMENTS.get(commitment_id, {})
	var success := session.commitment_progress >= COMMITMENT_GOAL
	var effects: Array[String] = []
	if success:
		var relief: int = int({"easy": 4, "medium": 3, "hard": 2}.get(session.difficulty_id, 3))
		var stress_change := session.change_stat("stress", -relief)
		effects.append("兑现承诺：压力 %s%d" % ["+" if stress_change >= 0 else "", stress_change])
		var debt_id := _commitment_debt(commitment_id)
		if int(session.debts.get(debt_id, 0)) > 0:
			var debt_change := session.change_debt(debt_id, -1)
			effects.append("%s %s%d" % [debt_display_name(debt_id), "+" if debt_change >= 0 else "", debt_change])
	else:
		var stress_cost: int = int({"easy": 3, "medium": 5, "hard": 7}.get(session.difficulty_id, 5))
		var debt_cost := 2 if session.difficulty_id == "hard" else 1
		var stress_change := session.change_stat("stress", stress_cost)
		var debt_id := _commitment_debt(commitment_id)
		var debt_change := session.change_debt(debt_id, debt_cost)
		effects.append("承诺落空：压力 +%d" % stress_change)
		effects.append("%s +%d" % [debt_display_name(debt_id), debt_change])
	session.commitments_history.append({
		"day": completed_day,
		"id": commitment_id,
		"progress": session.commitment_progress,
		"success": success,
	})
	session.active_commitment = ""
	session.commitment_progress = 0
	return {
		"title": "第 %d 天的承诺%s" % [completed_day, "已兑现" if success else "没有兑现"],
		"message": "%s：%s" % [str(commitment.get("title", "今日承诺")), "你用行动守住了这件事。" if success else "计划没有消失，它变成了之后需要偿还的代价。"],
		"effects": effects,
		"source_day": completed_day,
	}


static func settle_sleep_debt(session: GameSession, completed_day: int) -> Dictionary:
	var debt := int(session.debts.get("sleep", 0))
	if debt <= 0:
		return {}
	var energy_change := session.change_stat("energy", -mini(12, debt * 3))
	var stress_change := session.change_stat("stress", mini(8, debt * 2))
	session.change_debt("sleep", -1)
	return {
		"title": "睡眠债在清晨追了上来",
		"message": "第 %d 天积累的疲劳没有被进度条抵消。你醒来时，比计划中更难集中注意力。" % completed_day,
		"effects": [
			"精力 %s%d" % ["+" if energy_change >= 0 else "", energy_change],
			"压力 +%d" % stress_change,
			"睡眠债 -1",
		],
		"source_day": completed_day,
	}


static func resolve_milestone(event_id: String, choice_id: String, session: GameSession) -> Array[String]:
	var messages: Array[String] = []
	if event_id == "fixed_exam":
		var score := roundi(
			float(session.stats.study) * 0.45
			+ float(session.tasks.exam) * 0.35
			+ float(session.stats.energy) * 0.20
			- float(session.debts.sleep) * 7.0
			- float(session.debts.ai_risk) * 5.0
		)
		if choice_id == "reasoning":
			score += 8
		elif choice_id == "memorized":
			score -= 6
		elif choice_id == "calm":
			score += 3
		if bool(session.flags.get("verified_ai", false)):
			score += 4
		session.flags["exam_score"] = clampi(score, 0, 100)
		session.flags["exam_outcome"] = "strong" if score >= 72 else ("pass" if score >= 55 else "weak")
		messages.append("考试判断：%s（理解、准备、状态与既往风险共同结算）" % _outcome_name(str(session.flags.exam_outcome)))
	elif event_id == "fixed_presentation":
		var score := roundi(
			float(session.stats.project) * 0.40
			+ float(session.tasks.presentation) * 0.25
			+ float(session.relationships.teammate) * 0.15
			+ float(session.stats.energy) * 0.20
			- float(session.debts.technical) * 8.0
			- float(session.debts.ai_risk) * 6.0
			- float(session.debts.social) * 3.0
		)
		if bool(session.flags.get("environment_documented", false)):
			score += 7
		if bool(session.flags.get("team_understanding", false)):
			score += 7
		if bool(session.flags.get("verified_ai", false)):
			score += 5
		if choice_id == "explain":
			score += 5 if bool(session.flags.get("verified_ai", false)) else -5
		elif choice_id == "team":
			score += 5 if int(session.relationships.teammate) >= 50 else -4
		elif choice_id == "polish" and (int(session.debts.technical) > 0 or int(session.debts.ai_risk) > 0):
			score -= 8
		session.flags["presentation_score"] = clampi(score, 0, 100)
		session.flags["presentation_outcome"] = "strong" if score >= 72 else ("pass" if score >= 55 else "weak")
		messages.append("展示判断：%s（完成度、复现、协作与风险共同结算）" % _outcome_name(str(session.flags.presentation_outcome)))
	return messages


static func debt_display_name(debt_id: String) -> String:
	return {
		"sleep": "睡眠债",
		"technical": "技术债",
		"social": "人情债",
		"ai_risk": "AI 风险",
	}.get(debt_id, debt_id)


static func debt_risk_summary(session: GameSession) -> String:
	var parts: Array[String] = []
	for debt_id in DEBT_KEYS:
		var value := int(session.debts.get(debt_id, 0))
		if value > 0:
			parts.append("%s %d" % [debt_display_name(debt_id), value])
	return "暂无跨日债务" if parts.is_empty() else " · ".join(parts)


static func commitment_title(commitment_id: String) -> String:
	return str(COMMITMENTS.get(commitment_id, {}).get("title", "尚未登记阶段承诺"))


static func commitment_debt_id(commitment_id: String) -> String:
	return _commitment_debt(commitment_id)


static func _commitment_debt(commitment_id: String) -> String:
	return {
		"exam": "sleep",
		"project": "technical",
		"social": "social",
		"recovery": "sleep",
		"verification": "ai_risk",
	}.get(commitment_id, "sleep")


static func _outcome_name(outcome: String) -> String:
	return {"strong": "准备扎实", "pass": "勉强守住", "weak": "关键短板暴露"}.get(outcome, outcome)
