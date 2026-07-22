class_name MusicController
extends Node
## Lightweight cross-scene music persistence adapted from Maaack v1.4.7 (MIT).

@export var audio_bus: StringName = &"Music"
var current_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is AudioStreamPlayer and node.autoplay and node.bus == audio_bus:
		adopt_player.call_deferred(node)


func adopt_player(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player) or player == current_player:
		return
	if is_instance_valid(current_player):
		current_player.stop()
		current_player.queue_free()
	current_player = player
	if player.get_parent() != self:
		player.reparent(self)
	if not current_player.playing:
		current_player.play()


func stop() -> void:
	if is_instance_valid(current_player):
		current_player.stop()


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
