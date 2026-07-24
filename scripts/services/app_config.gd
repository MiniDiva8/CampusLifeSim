extends Node

## Project-owned replacement for the Maaack example AppConfig scene.
## It deliberately has no dependency on upstream example state or paths.

const MAIN_SCENE := "res://scenes/main.tscn"
const LOADING_SCENE := "res://scenes/system/loading_screen.tscn"
const SAVE_SCHEMA_VERSION := 1
const TARGET_GODOT_VERSION := "4.7.1"

var game_title := "惊魂期末周"
var version := "0.5.0-demo"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
