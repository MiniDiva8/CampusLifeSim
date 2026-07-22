class_name SaveService
extends RefCounted

const DEFAULT_SAVE_PATH := "user://autosave.json"
const DEFAULT_SETTINGS_PATH := "user://settings.json"

var save_path: String
var settings_path: String


func _init(custom_save_path: String = DEFAULT_SAVE_PATH, custom_settings_path: String = DEFAULT_SETTINGS_PATH) -> void:
	save_path = custom_save_path
	settings_path = custom_settings_path


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game(session: GameSession) -> Error:
	return _write_json_atomic(save_path, session.to_dict())


func load_game() -> GameSession:
	var data = _read_json(save_path)
	if not data is Dictionary:
		return null
	var session := GameSession.new()
	if not session.from_dict(data):
		push_error("Save data uses an unsupported or invalid schema")
		return null
	return session


func delete_save() -> Error:
	if not has_save():
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func save_settings(settings: Dictionary) -> Error:
	return _write_json_atomic(settings_path, settings)


func load_settings() -> Dictionary:
	var defaults := {"master_volume": 0.8, "fullscreen": false, "reduced_motion": false}
	var data = _read_json(settings_path)
	if data is Dictionary:
		for key in defaults:
			if data.has(key):
				defaults[key] = data[key]
	return defaults


func _write_json_atomic(path: String, data: Dictionary) -> Error:
	var absolute_path := ProjectSettings.globalize_path(path)
	var temp_path := absolute_path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open temporary save file: %s" % temp_path)
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()
	if FileAccess.file_exists(absolute_path):
		var remove_error := DirAccess.remove_absolute(absolute_path)
		if remove_error != OK:
			return remove_error
	return DirAccess.rename_absolute(temp_path, absolute_path)


func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot read JSON file: %s" % path)
		return null
	return JSON.parse_string(file.get_as_text())
