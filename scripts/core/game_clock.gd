class_name GameClock
extends RefCounted

const DAYS := 7
const SLOTS_PER_DAY := 5
const SLOT_NAMES := ["早晨", "上午", "下午", "晚上", "深夜"]
const WEEKDAY_NAMES := ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

var day: int = 1
var slot: int = 0


func reset() -> void:
	day = 1
	slot = 0


func get_index() -> int:
	return (day - 1) * SLOTS_PER_DAY + slot


func set_from_index(index: int) -> void:
	var safe_index := clampi(index, 0, DAYS * SLOTS_PER_DAY)
	day = mini(safe_index / SLOTS_PER_DAY + 1, DAYS + 1)
	slot = safe_index % SLOTS_PER_DAY


func advance(steps: int = 1) -> Dictionary:
	var previous_day := day
	var previous_slot := slot
	set_from_index(get_index() + maxi(steps, 0))
	return {
		"previous_day": previous_day,
		"previous_slot": previous_slot,
		"day_changed": day != previous_day,
		"finished": is_finished(),
	}


func is_finished() -> bool:
	return day > DAYS


func get_slot_name() -> String:
	if is_finished():
		return "已结束"
	return SLOT_NAMES[slot]


func get_weekday_name() -> String:
	if is_finished():
		return ""
	return WEEKDAY_NAMES[day - 1]


func get_display_text() -> String:
	if is_finished():
		return "期末周结束"
	return "第 %d 天 · %s · %s" % [day, get_weekday_name(), get_slot_name()]


func to_dict() -> Dictionary:
	return {"day": day, "slot": slot}


func from_dict(data: Dictionary) -> void:
	day = clampi(int(data.get("day", 1)), 1, DAYS + 1)
	slot = clampi(int(data.get("slot", 0)), 0, SLOTS_PER_DAY - 1)
