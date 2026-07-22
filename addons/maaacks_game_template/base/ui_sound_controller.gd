class_name UISoundController
extends Node
## Button discovery follows Maaack's UI sound controller design (MIT).
## This project uses a tiny generated tone so no external audio asset is needed.

const MIX_RATE := 22050.0
const TONE_SECONDS := 0.035

var player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	player.name = "GeneratedUISound"
	player.stream = _build_click_stream()
	player.bus = &"SFX"
	add_child(player)
	get_tree().node_added.connect(_on_node_added)
	_connect_recursive(get_tree().root)


func _on_node_added(node: Node) -> void:
	if node is Button:
		_connect_button(node)


func _connect_recursive(node: Node) -> void:
	if node is Button:
		_connect_button(node)
	for child in node.get_children():
		_connect_recursive(child)


func _connect_button(button: Button) -> void:
	if not button.pressed.is_connected(_play_click):
		button.pressed.connect(_play_click)


func _play_click() -> void:
	if not is_instance_valid(player):
		return
	player.play()


func _build_click_stream() -> AudioStreamWAV:
	var sample_count := int(MIX_RATE * TONE_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var fade := 1.0 - float(index) / float(sample_count)
		var sample := int(sin(TAU * 620.0 * float(index) / MIX_RATE) * 2600.0 * fade)
		bytes.encode_s16(index * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(MIX_RATE)
	stream.stereo = false
	stream.data = bytes
	return stream


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	if is_instance_valid(player):
		player.stop()
