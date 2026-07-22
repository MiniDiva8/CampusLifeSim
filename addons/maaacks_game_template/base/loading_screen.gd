class_name LoadingScreen
extends CanvasLayer
## Project presentation adapted from the Maaack loading-screen contract (MIT).

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var progress_label: Label = %ProgressLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SceneLoader.scene_loaded.connect(_on_scene_loaded)
	SceneLoader.scene_load_failed.connect(_on_scene_failed)


func _process(_delta: float) -> void:
	var progress := SceneLoader.get_progress()
	progress_bar.value = progress * 100.0
	progress_label.text = "正在整理校园日程… %d%%" % int(progress * 100.0)


func _on_scene_loaded() -> void:
	progress_bar.value = 100
	progress_label.text = "准备完成"


func _on_scene_failed(_path: String) -> void:
	progress_label.text = "加载失败，请重新启动游戏。"
	set_process(false)
