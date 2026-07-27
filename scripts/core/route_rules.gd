class_name RouteRules
extends RefCounted

const DEFAULT_ROUTE := "study"
const ORDER := ["study", "project", "social"]
const CONFIGS := {
	"study": {
		"index": "01",
		"name": "稳扎稳打",
		"subtitle": "先保住核心课，再处理项目",
		"core": "把有限时间优先交给知识基础与考试准备。",
		"advantage": "学习进度 +10；学习与考试收益提高约 8%。",
		"shortcoming": "项目与展示收益略低约 4%，成品出现得更晚。",
		"recommendation": "前期多去蒋震图书馆和教学区，先补齐核心课短板。",
		"tendency": "图书馆、教学区的基础学习事件更容易优先出现。",
		"accent": "#9E2A2F",
	},
	"project": {
		"index": "02",
		"name": "实干派",
		"subtitle": "先做出成果，再回头补课",
		"core": "用可运行的成果推动项目，把问题放进实践里解决。",
		"advantage": "项目进度 +10；项目与展示收益提高约 10%。",
		"shortcoming": "学习收益略低约 4%，每次行动会额外积累 1 点压力。",
		"recommendation": "尽早进入人工智能学院机房，先做出可复现的小闭环。",
		"tendency": "机房与宿舍的项目事件更容易优先出现。",
		"accent": "#A87932",
	},
	"social": {
		"index": "03",
		"name": "协调者",
		"subtitle": "先建立支持，再应对关键节点",
		"core": "把信息、人情与互助变成期末周的容错空间。",
		"advantage": "四名同伴关系各 +5；正向关系收益提高约 25%。",
		"shortcoming": "单项学习与项目收益略低约 3%，独自推进速度一般。",
		"recommendation": "留意同伴所在地点，在关键节点前主动交换信息与帮助。",
		"tendency": "满足条件的同伴支线会比普通地点事件更早出现。",
		"accent": "#4F7766",
	},
}


static func normalize(route_id: String) -> String:
	return route_id if CONFIGS.has(route_id) else DEFAULT_ROUTE


static func get_config(route_id: String) -> Dictionary:
	return CONFIGS[normalize(route_id)]


static func get_all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for route_id in ORDER:
		var route: Dictionary = CONFIGS[route_id].duplicate(true)
		route["id"] = route_id
		result.append(route)
	return result


static func adjust_effect_amount(effect_type: String, target: String, amount: int, route_id: String) -> int:
	if amount == 0:
		return 0
	var multiplier := 1.0
	match normalize(route_id):
		"study":
			if amount > 0 and ((effect_type == "stat" and target == "study") or (effect_type == "task" and target == "exam")):
				multiplier = 1.08
			elif amount > 0 and ((effect_type == "stat" and target == "project") or (effect_type == "task" and target == "presentation")):
				multiplier = 0.96
		"project":
			if amount > 0 and ((effect_type == "stat" and target == "project") or (effect_type == "task" and target == "presentation")):
				multiplier = 1.10
			elif amount > 0 and ((effect_type == "stat" and target == "study") or (effect_type == "task" and target == "exam")):
				multiplier = 0.96
			elif effect_type == "stat" and target == "stress" and amount > 0:
				multiplier = 1.10
		"social":
			if effect_type == "relationship" and amount > 0:
				multiplier = 1.25
			elif amount > 0 and ((effect_type == "stat" and target in ["study", "project"]) or (effect_type == "task" and target in ["exam", "presentation"])):
				multiplier = 0.97
			elif effect_type == "stat" and target == "stress" and amount < 0:
				multiplier = 1.08
	var adjusted := roundi(float(amount) * multiplier)
	if adjusted == 0:
		return 1 if amount > 0 else -1
	return adjusted


static func adjust_action_pressure(amount: int, route_id: String) -> int:
	if amount > 0 and normalize(route_id) == "project":
		return amount + 1
	return amount


static func get_event_priority_bonus(event: Dictionary, route_id: String) -> int:
	var trigger: Dictionary = event.get("trigger", {})
	var location_id := str(trigger.get("location", ""))
	var kind := str(event.get("kind", ""))
	match normalize(route_id):
		"study":
			if kind == "location" and location_id in ["library", "teaching"]:
				return 35
		"project":
			if kind == "location" and location_id in ["lab", "dorm"]:
				return 35
		"social":
			if kind == "npc":
				return 30
	return 0
