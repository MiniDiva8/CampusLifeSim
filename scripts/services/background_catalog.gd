class_name BackgroundCatalog
extends RefCounted

const MANIFEST_PATH := "res://data/backgrounds.json"

var menu: Array = []
var locations: Dictionary = {}
var scenes: Dictionary = {}
var orientations: Dictionary = {}
var roads: Dictionary = {}
var effects: Dictionary = {}
var errors: Array[String] = []


func load_all() -> bool:
	errors.clear()
	menu.clear()
	locations.clear()
	scenes.clear()
	orientations.clear()
	roads.clear()
	effects.clear()
	var data = _read_json(MANIFEST_PATH)
	if not data is Dictionary:
		errors.append("Background manifest is missing or invalid: %s" % MANIFEST_PATH)
		return false
	menu = _validated_paths(data.get("menu", []), "menu")
	var raw_locations = data.get("locations", {})
	if raw_locations is Dictionary:
		for location_id in raw_locations:
			locations[str(location_id)] = _validated_paths(raw_locations[location_id], "location:%s" % location_id)
	var raw_scenes = data.get("scenes", {})
	if raw_scenes is Dictionary:
		for scene_path_value in raw_scenes:
			var scene_path := str(scene_path_value)
			var metadata = raw_scenes[scene_path_value]
			if not ResourceLoader.exists(scene_path):
				errors.append("Scene metadata references a missing background: %s" % scene_path)
			elif not metadata is Dictionary:
				errors.append("Scene metadata must be an object: %s" % scene_path)
			elif str(metadata.get("display_name", "")).is_empty() or str(metadata.get("arrival_text", "")).is_empty():
				errors.append("Scene metadata needs display_name and arrival_text: %s" % scene_path)
			else:
				scenes[scene_path] = metadata.duplicate(true)
	var raw_orientations = data.get("orientations", {})
	if raw_orientations is Dictionary:
		for orientation_path_value in raw_orientations:
			var orientation_path := str(orientation_path_value)
			var orientation := int(raw_orientations[orientation_path_value])
			if not ResourceLoader.exists(orientation_path):
				errors.append("Orientation metadata references a missing background: %s" % orientation_path)
			elif orientation not in [1, 3, 6, 8]:
				errors.append("Unsupported EXIF orientation %d for: %s" % [orientation, orientation_path])
			else:
				orientations[orientation_path] = orientation
	var raw_roads = data.get("roads", {})
	if raw_roads is Dictionary:
		for period in raw_roads:
			roads[str(period)] = _validated_paths(raw_roads[period], "roads:%s" % period)
	var raw_effects = data.get("effects", {})
	if raw_effects is Dictionary:
		for effect_id in raw_effects:
			effects[str(effect_id)] = _validated_paths(raw_effects[effect_id], "effects:%s" % effect_id)
	for location_id in ["dorm", "library", "teaching", "lab", "canteen", "field"]:
		if not locations.has(location_id) or locations[location_id].is_empty():
			errors.append("No backgrounds configured for location: %s" % location_id)
	for period in ["day", "night"]:
		if not roads.has(period) or roads[period].is_empty():
			errors.append("No travel backgrounds configured for: %s" % period)
	if menu.is_empty():
		errors.append("No menu background configured")
	if not effects.has("stress_overload") or effects.stress_overload.is_empty():
		errors.append("No stress overload background configured")
	return errors.is_empty()


func get_menu_background() -> String:
	return str(menu[0]) if not menu.is_empty() else ""


func get_stress_background() -> String:
	var options: Array = effects.get("stress_overload", [])
	return str(options[0]) if not options.is_empty() else ""


func get_photo_orientation(background_path: String) -> int:
	return int(orientations.get(background_path, 1))


func get_scene_context(background_path: String, location_id: String) -> Dictionary:
	var context := _default_scene_context(location_id, background_path)
	if scenes.has(background_path):
		context.merge(scenes[background_path], true)
	return context


func get_active_scene_context(session: GameSession) -> Dictionary:
	if session == null:
		return {}
	return get_scene_context(session.current_background_path, session.current_location_id)


func choose_location_background(location_id: String, session: GameSession) -> String:
	var options: Array = locations.get(location_id, [])
	var previous := str(session.last_location_backgrounds.get(location_id, ""))
	var selected := _choose(options, previous, session.run_seed, session.background_choice_counter, location_id)
	session.background_choice_counter += 1
	session.current_location_id = location_id
	session.current_background_path = selected
	if not selected.is_empty():
		session.last_location_backgrounds[location_id] = selected
	return selected


func choose_road_background(session: GameSession) -> String:
	var period := "night" if session.clock.slot >= 3 else "day"
	var options: Array = roads.get(period, [])
	var selected := _choose(options, session.last_road_background, session.run_seed, session.background_choice_counter, "roads:%s" % period)
	session.background_choice_counter += 1
	if not selected.is_empty():
		session.last_road_background = selected
	return selected


func _choose(options: Array, previous: String, seed_value: int, counter: int, category: String) -> String:
	if options.is_empty():
		return ""
	var candidates := options.duplicate()
	if candidates.size() > 1 and candidates.has(previous):
		candidates.erase(previous)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ category.hash() ^ (counter * 104729)
	return str(candidates[rng.randi_range(0, candidates.size() - 1)])


func _default_scene_context(location_id: String, background_path: String) -> Dictionary:
	var display_name := "校园一角"
	var arrival_text := "你来到校园里的一处空间，准备安排这个时段。"
	var activity_text := "处理眼前的安排"
	var activity_label := ""
	match location_id:
		"dorm":
			display_name = "海风宿舍"
			arrival_text = "你回到海风宿舍，准备在自己的生活空间里安排这个时段。"
		"library":
			display_name = "星海图书馆"
			arrival_text = "你来到星海图书馆，准备在安静的阅览空间里推进复习。"
		"teaching":
			display_name = "教学楼"
			arrival_text = "你来到教学区，准备处理课程、答疑或复习安排。"
		"lab":
			display_name = "启智实验室"
			arrival_text = "你来到启智实验室，显示器和项目进度都在等你。"
		"canteen":
			display_name = "齐园食堂"
			arrival_text = "你来到齐园食堂，准备用一顿饭给身体和情绪补充能量。"
			if background_path.contains("/水果/"):
				display_name = "齐园食堂 · 水果区"
				arrival_text = "你来到齐园食堂的水果区，准备挑些水果补充能量。"
			elif background_path.contains("/早餐/"):
				display_name = "齐园食堂 · 早餐"
				arrival_text = "你来到齐园食堂吃早餐，先让新的一天有足够的能量。"
			elif background_path.contains("/正餐/"):
				display_name = "齐园食堂 · 正餐"
				arrival_text = "你来到齐园食堂，准备认真吃一顿正餐，暂停脑内的倒计时。"
		"field":
			display_name = "青春操场"
			arrival_text = "你来到运动区，准备活动身体，让紧绷的思绪换个节奏。"
			activity_text = "运动"
			activity_label = "认真运动一会儿"
	return {
		"display_name": display_name,
		"arrival_text": arrival_text,
		"activity_text": activity_text,
		"activity_label": activity_label,
	}


func _validated_paths(value, label: String) -> Array:
	var valid: Array = []
	if not value is Array:
		errors.append("Background group must be an array: %s" % label)
		return valid
	for item in value:
		var path := str(item)
		if not ResourceLoader.exists(path):
			errors.append("Background resource does not exist: %s" % path)
		else:
			valid.append(path)
	return valid


func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())
