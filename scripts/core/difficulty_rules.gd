class_name DifficultyRules
extends RefCounted

const DEFAULT_NEW_GAME := "medium"
const LEGACY_DIFFICULTY := "easy"
const ORDER := ["easy", "medium", "hard"]
const CONFIGS := {
	"easy": {
		"name": "简易",
		"subtitle": "熟悉校园与事件",
		"description": "沿用原本节奏，数值收支最宽松。",
		"color": "#55C2A3",
		"stress_gain": 1.0,
		"stress_relief": 1.0,
		"academic_gain": 1.0,
		"energy_cost": 1.0,
		"energy_recovery": 1.0,
		"crisis_threshold": 88,
		"crisis_relief": 14,
		"social_relief": 16,
		"focus_gain": 4,
		"focus_energy_cost": 7,
		"focus_stress_gain": 4,
	},
	"medium": {
		"name": "中等",
		"subtitle": "推荐的期末体验",
		"description": "压力增长 1.25 倍，学业收益约为 82%。",
		"color": "#F2B84B",
		"stress_gain": 1.25,
		"stress_relief": 0.85,
		"academic_gain": 0.82,
		"energy_cost": 1.15,
		"energy_recovery": 0.9,
		"crisis_threshold": 76,
		"crisis_relief": 10,
		"social_relief": 12,
		"focus_gain": 3,
		"focus_energy_cost": 10,
		"focus_stress_gain": 6,
	},
	"hard": {
		"name": "困难",
		"subtitle": "每个时段都要权衡",
		"description": "压力增长 1.65 倍，学业收益约为 60%。",
		"color": "#EF7E73",
		"stress_gain": 1.65,
		"stress_relief": 0.6,
		"academic_gain": 0.6,
		"energy_cost": 1.4,
		"energy_recovery": 0.7,
		"crisis_threshold": 64,
		"crisis_relief": 7,
		"social_relief": 9,
		"focus_gain": 2,
		"focus_energy_cost": 13,
		"focus_stress_gain": 9,
	},
}


static func normalize(difficulty_id: String) -> String:
	return difficulty_id if CONFIGS.has(difficulty_id) else LEGACY_DIFFICULTY


static func get_config(difficulty_id: String) -> Dictionary:
	return CONFIGS[normalize(difficulty_id)]


static func get_display_name(difficulty_id: String) -> String:
	return str(get_config(difficulty_id).get("name", "简易"))


static func get_crisis_threshold(difficulty_id: String) -> int:
	return int(get_config(difficulty_id).get("crisis_threshold", 88))


static func get_action_pressure(session: GameSession) -> int:
	var difficulty_id := normalize(session.difficulty_id)
	if difficulty_id == "easy":
		return 0
	var pressure := 1 if difficulty_id == "medium" else 2
	if int(session.stats.get("energy", 0)) < 35:
		pressure += 1 if difficulty_id == "medium" else 2
	if not bool(session.flags.get("exam_completed", false)) and session.clock.day >= 4 and int(session.tasks.get("exam", 0)) < 50:
		pressure += 1 if difficulty_id == "medium" else 2
	if not bool(session.flags.get("presentation_completed", false)) and session.clock.day >= 6 and int(session.tasks.get("presentation", 0)) < 60:
		pressure += 1 if difficulty_id == "medium" else 2
	return pressure


static func adjust_effect_amount(effect_type: String, target: String, amount: int, difficulty_id: String) -> int:
	if amount == 0:
		return 0
	var multiplier := 1.0
	var config := get_config(difficulty_id)
	if effect_type == "stat":
		if target in ["study", "project"] and amount > 0:
			multiplier = float(config.academic_gain)
		elif target == "stress":
			multiplier = float(config.stress_gain if amount > 0 else config.stress_relief)
		elif target == "energy":
			multiplier = float(config.energy_recovery if amount > 0 else config.energy_cost)
	elif effect_type == "task" and amount > 0 and target in ["exam", "presentation"]:
		multiplier = float(config.academic_gain)
	var adjusted := roundi(float(amount) * multiplier)
	if adjusted == 0:
		return 1 if amount > 0 else -1
	return adjusted
