class_name SceneLoaderClass
extends Node
## Adapted from Maaack/Godot-Game-Template v1.4.7 (MIT).
## Loads scenes in the background through a project-owned loading screen.

signal scene_loaded
signal scene_load_failed(path: String)

@export_file("*.tscn") var loading_screen_path := "res://scenes/system/loading_screen.tscn"

var _loading_screen: PackedScene
var _scene_path := ""
var _background_loading := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	if not loading_screen_path.is_empty():
		_loading_screen = load(loading_screen_path)


func load_scene(scene_path: String, in_background: bool = false) -> void:
	if scene_path.is_empty():
		push_error("SceneLoader received an empty path")
		return
	_scene_path = scene_path
	_background_loading = in_background
	var error := ResourceLoader.load_threaded_request(_scene_path)
	if error != OK:
		scene_load_failed.emit(_scene_path)
		push_error("Failed to request scene: %s" % _scene_path)
		return
	set_process(true)
	if not _background_loading and _loading_screen != null:
		get_tree().change_scene_to_packed(_loading_screen)


func get_progress() -> float:
	if _scene_path.is_empty():
		return 0.0
	var progress: Array = []
	ResourceLoader.load_threaded_get_status(_scene_path, progress)
	return float(progress[0]) if not progress.is_empty() else 0.0


func change_scene_to_loaded_resource() -> void:
	if _scene_path.is_empty():
		return
	var resource := ResourceLoader.load_threaded_get(_scene_path) as PackedScene
	if resource == null:
		scene_load_failed.emit(_scene_path)
		return
	var error := get_tree().change_scene_to_packed(resource)
	if error != OK:
		scene_load_failed.emit(_scene_path)


func reload_current_scene() -> void:
	get_tree().reload_current_scene()


func _process(_delta: float) -> void:
	var status := ResourceLoader.load_threaded_get_status(_scene_path)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			scene_loaded.emit()
			if not _background_loading:
				change_scene_to_loaded_resource()
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			set_process(false)
			scene_load_failed.emit(_scene_path)
