class_name BackgroundCatalog
extends RefCounted

const MANIFEST_PATH := "res://data/backgrounds.json"

var menu: Array = []
var locations: Dictionary = {}
var roads: Dictionary = {}
var effects: Dictionary = {}
var errors: Array[String] = []


func load_all() -> bool:
	errors.clear()
	menu.clear()
	locations.clear()
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
