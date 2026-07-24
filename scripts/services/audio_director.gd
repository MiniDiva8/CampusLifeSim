class_name AudioDirector
extends Node
## CampusLifeSim's semantic audio foundation.
##
## Buttons opt into a cue with the `audio_cue` metadata key. Buttons without
## metadata still receive a restrained default sound. The temporary procedural
## sounds keep this stage self-contained and can later be replaced by licensed
## WAV files without changing UI code.

signal cue_played(cue: StringName)

const MIX_RATE := 44100
const MAX_VOICES := 8
const CONNECTED_META := &"_campus_audio_connected"
const DEFAULT_CUE := &"press"
const DEFAULT_HOVER_CUE := &"hover"
const PITCH_STEPS := [-0.018, 0.0, 0.012, -0.007, 0.019, 0.004]

const CUE_PROFILES := {
	&"hover": {
		"duration": 0.032,
		"bus": &"UI",
		"volume_db": -12.0,
		"cooldown_ms": 85,
		"pitch_variation": 0.45,
		"notes": [
			{"start": 0.0, "end": 0.032, "from": 930.0, "to": 1040.0, "gain": 0.22, "wave": "sine"},
		],
		"noise_gain": 0.018,
		"noise_duration": 0.009,
	},
	&"press": {
		"duration": 0.060,
		"bus": &"UI",
		"volume_db": -7.0,
		"cooldown_ms": 45,
		"pitch_variation": 0.75,
		"notes": [
			{"start": 0.0, "end": 0.060, "from": 540.0, "to": 410.0, "gain": 0.32, "wave": "triangle"},
			{"start": 0.0, "end": 0.034, "from": 1040.0, "to": 860.0, "gain": 0.09, "wave": "sine"},
		],
		"noise_gain": 0.11,
		"noise_duration": 0.012,
	},
	&"select": {
		"duration": 0.082,
		"bus": &"UI",
		"volume_db": -6.5,
		"cooldown_ms": 55,
		"pitch_variation": 0.55,
		"notes": [
			{"start": 0.0, "end": 0.052, "from": 520.0, "to": 670.0, "gain": 0.27, "wave": "triangle"},
			{"start": 0.034, "end": 0.082, "from": 760.0, "to": 820.0, "gain": 0.19, "wave": "sine"},
		],
		"noise_gain": 0.045,
		"noise_duration": 0.010,
	},
	&"confirm": {
		"duration": 0.145,
		"bus": &"Event",
		"volume_db": -5.0,
		"cooldown_ms": 90,
		"pitch_variation": 0.25,
		"notes": [
			{"start": 0.0, "end": 0.072, "from": 470.0, "to": 520.0, "gain": 0.26, "wave": "triangle"},
			{"start": 0.052, "end": 0.145, "from": 690.0, "to": 760.0, "gain": 0.25, "wave": "sine"},
			{"start": 0.070, "end": 0.145, "from": 1030.0, "to": 1030.0, "gain": 0.07, "wave": "sine"},
		],
		"noise_gain": 0.035,
		"noise_duration": 0.011,
	},
	&"back": {
		"duration": 0.105,
		"bus": &"UI",
		"volume_db": -7.0,
		"cooldown_ms": 70,
		"pitch_variation": 0.4,
		"notes": [
			{"start": 0.0, "end": 0.105, "from": 690.0, "to": 410.0, "gain": 0.27, "wave": "triangle"},
			{"start": 0.0, "end": 0.054, "from": 980.0, "to": 740.0, "gain": 0.08, "wave": "sine"},
		],
		"noise_gain": 0.035,
		"noise_duration": 0.012,
	},
	&"danger": {
		"duration": 0.160,
		"bus": &"Event",
		"volume_db": -6.0,
		"cooldown_ms": 110,
		"pitch_variation": 0.15,
		"notes": [
			{"start": 0.0, "end": 0.090, "from": 310.0, "to": 265.0, "gain": 0.33, "wave": "triangle"},
			{"start": 0.064, "end": 0.160, "from": 250.0, "to": 205.0, "gain": 0.29, "wave": "sine"},
		],
		"noise_gain": 0.055,
		"noise_duration": 0.018,
	},
	&"toggle_on": {
		"duration": 0.075,
		"bus": &"UI",
		"volume_db": -8.0,
		"cooldown_ms": 60,
		"pitch_variation": 0.45,
		"notes": [
			{"start": 0.0, "end": 0.075, "from": 620.0, "to": 820.0, "gain": 0.25, "wave": "sine"},
		],
		"noise_gain": 0.035,
		"noise_duration": 0.010,
	},
	&"toggle_off": {
		"duration": 0.075,
		"bus": &"UI",
		"volume_db": -8.0,
		"cooldown_ms": 60,
		"pitch_variation": 0.45,
		"notes": [
			{"start": 0.0, "end": 0.075, "from": 720.0, "to": 500.0, "gain": 0.23, "wave": "sine"},
		],
		"noise_gain": 0.035,
		"noise_duration": 0.010,
	},
	&"choice": {
		"duration": 0.126,
		"bus": &"Event",
		"volume_db": -5.5,
		"cooldown_ms": 80,
		"pitch_variation": 0.35,
		"notes": [
			{"start": 0.0, "end": 0.068, "from": 430.0, "to": 490.0, "gain": 0.27, "wave": "triangle"},
			{"start": 0.040, "end": 0.126, "from": 620.0, "to": 700.0, "gain": 0.24, "wave": "sine"},
		],
		"noise_gain": 0.050,
		"noise_duration": 0.012,
	},
	&"location_enter": {
		"duration": 0.180,
		"bus": &"Event",
		"volume_db": -7.0,
		"cooldown_ms": 120,
		"pitch_variation": 0.25,
		"notes": [
			{"start": 0.0, "end": 0.180, "from": 260.0, "to": 390.0, "gain": 0.18, "wave": "sine"},
			{"start": 0.070, "end": 0.180, "from": 540.0, "to": 610.0, "gain": 0.16, "wave": "triangle"},
		],
		"noise_gain": 0.085,
		"noise_duration": 0.115,
	},
	&"blocked": {
		"duration": 0.105,
		"bus": &"UI",
		"volume_db": -8.0,
		"cooldown_ms": 100,
		"pitch_variation": 0.15,
		"notes": [
			{"start": 0.0, "end": 0.105, "from": 220.0, "to": 155.0, "gain": 0.34, "wave": "triangle"},
		],
		"noise_gain": 0.075,
		"noise_duration": 0.020,
	},
	&"reveal": {
		"duration": 0.220,
		"bus": &"Event",
		"volume_db": -6.0,
		"cooldown_ms": 140,
		"pitch_variation": 0.15,
		"notes": [
			{"start": 0.0, "end": 0.105, "from": 410.0, "to": 520.0, "gain": 0.20, "wave": "sine"},
			{"start": 0.070, "end": 0.165, "from": 610.0, "to": 720.0, "gain": 0.20, "wave": "sine"},
			{"start": 0.135, "end": 0.220, "from": 820.0, "to": 930.0, "gain": 0.17, "wave": "sine"},
		],
		"noise_gain": 0.020,
		"noise_duration": 0.016,
	},
	&"stat_up": {
		"duration": 0.115,
		"bus": &"Event",
		"volume_db": -8.0,
		"cooldown_ms": 80,
		"pitch_variation": 0.3,
		"notes": [
			{"start": 0.0, "end": 0.115, "from": 540.0, "to": 880.0, "gain": 0.22, "wave": "sine"},
		],
		"noise_gain": 0.015,
		"noise_duration": 0.010,
	},
	&"stat_down": {
		"duration": 0.130,
		"bus": &"Event",
		"volume_db": -8.0,
		"cooldown_ms": 80,
		"pitch_variation": 0.3,
		"notes": [
			{"start": 0.0, "end": 0.130, "from": 560.0, "to": 270.0, "gain": 0.23, "wave": "triangle"},
		],
		"noise_gain": 0.025,
		"noise_duration": 0.014,
	},
	&"ai_prompt": {
		"duration": 0.205,
		"bus": &"Event",
		"volume_db": -7.0,
		"cooldown_ms": 150,
		"pitch_variation": 0.08,
		"notes": [
			{"start": 0.0, "end": 0.080, "from": 720.0, "to": 790.0, "gain": 0.17, "wave": "sine"},
			{"start": 0.062, "end": 0.142, "from": 810.0, "to": 880.0, "gain": 0.17, "wave": "sine"},
			{"start": 0.124, "end": 0.205, "from": 930.0, "to": 1010.0, "gain": 0.16, "wave": "sine"},
		],
		"noise_gain": 0.012,
		"noise_duration": 0.014,
	},
}

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _last_played_ms: Dictionary = {}
var _bus_fades: Dictionary = {}
var _pitch_step_index := 0
var _voice_cursor := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_stream_library()
	_build_voice_pool()
	get_tree().node_added.connect(_on_node_added)
	_connect_recursive(get_tree().root)


func apply_mixer_settings(settings: Dictionary) -> void:
	_set_bus_linear(&"Master", float(settings.get("master_volume", 0.8)))
	_set_bus_linear(&"Music", float(settings.get("music_volume", 0.65)))
	_set_bus_linear(&"SFX", float(settings.get("sfx_volume", 0.8)))
	_set_bus_linear(&"Ambience", float(settings.get("ambience_volume", 0.65)))
	var stress_bus := AudioServer.get_bus_index(&"Stress")
	if stress_bus >= 0:
		AudioServer.set_bus_mute(stress_bus, not bool(settings.get("pressure_audio", true)))


func play_cue(cue: StringName = DEFAULT_CUE, force: bool = false) -> void:
	if _streams.is_empty():
		return
	if not _streams.has(cue):
		cue = DEFAULT_CUE
	var profile: Dictionary = CUE_PROFILES[cue]
	var now := Time.get_ticks_msec()
	var cooldown_ms := int(profile.get("cooldown_ms", 45))
	if not force and _last_played_ms.has(cue) and now - int(_last_played_ms[cue]) < cooldown_ms:
		return
	_last_played_ms[cue] = now
	if _players.is_empty():
		return
	var player := _get_available_player()
	player.stop()
	player.stream = _streams[cue]
	player.bus = StringName(profile.get("bus", &"UI"))
	player.volume_db = float(profile.get("volume_db", -6.0))
	var variation := float(profile.get("pitch_variation", 0.0))
	player.pitch_scale = 1.0 + float(PITCH_STEPS[_pitch_step_index % PITCH_STEPS.size()]) * variation
	_pitch_step_index += 1
	player.play()
	cue_played.emit(cue)


func get_registered_cues() -> Array[StringName]:
	var result: Array[StringName] = []
	for cue in CUE_PROFILES:
		result.append(cue)
	return result


func fade_bus(bus_name: StringName, target_linear: float, duration: float = 0.3) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	if _bus_fades.has(bus_name):
		var active_tween: Tween = _bus_fades[bus_name]
		if active_tween != null and active_tween.is_valid():
			active_tween.kill()
		_bus_fades.erase(bus_name)
	var target := clampf(target_linear, 0.0, 1.0)
	if duration <= 0.0:
		_set_bus_linear(bus_name, target)
		return
	var current := 0.0 if AudioServer.is_bus_mute(bus_index) else db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	if target > 0.0001:
		AudioServer.set_bus_mute(bus_index, false)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(_set_bus_linear_from_tween.bind(bus_name), current, target, duration)
	tween.finished.connect(_on_bus_fade_finished.bind(bus_name, target))
	_bus_fades[bus_name] = tween


func prepare_for_shutdown() -> void:
	for tween_value in _bus_fades.values():
		var tween: Tween = tween_value
		if tween != null and tween.is_valid():
			tween.kill()
	_bus_fades.clear()
	for player in _players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			player.queue_free()
	_players.clear()
	_streams.clear()


func _set_bus_linear(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var level := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, level <= 0.0001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(level, 0.0001)))


func _set_bus_linear_from_tween(value: float, bus_name: StringName) -> void:
	_set_bus_linear(bus_name, value)


func _on_bus_fade_finished(bus_name: StringName, target_linear: float) -> void:
	if target_linear <= 0.0001:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index >= 0:
			AudioServer.set_bus_mute(bus_index, true)
	_bus_fades.erase(bus_name)


func _build_stream_library() -> void:
	var seed_offset := 0
	for cue in CUE_PROFILES:
		_streams[cue] = _build_stream(CUE_PROFILES[cue], 20260722 + seed_offset)
		seed_offset += 1


func _build_voice_pool() -> void:
	for index in MAX_VOICES:
		var player := AudioStreamPlayer.new()
		player.name = "SemanticVoice%02d" % index
		player.bus = &"UI"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players.append(player)


func _build_stream(profile: Dictionary, noise_seed: int) -> AudioStreamWAV:
	var duration := float(profile.get("duration", 0.08))
	var sample_count := maxi(1, int(MIX_RATE * duration))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = noise_seed
	var notes: Array = profile.get("notes", [])
	var noise_gain := float(profile.get("noise_gain", 0.0))
	var noise_duration := float(profile.get("noise_duration", duration))
	for index in sample_count:
		var time := float(index) / float(MIX_RATE)
		var global_envelope := _smooth_envelope(time, duration)
		var sample := 0.0
		for note_value in notes:
			var note: Dictionary = note_value
			var start := float(note.get("start", 0.0))
			var finish := float(note.get("end", duration))
			if time < start or time >= finish:
				continue
			var note_duration := maxf(finish - start, 0.0001)
			var local_time := time - start
			var progress := clampf(local_time / note_duration, 0.0, 1.0)
			var from_frequency := float(note.get("from", 440.0))
			var to_frequency := float(note.get("to", from_frequency))
			var phase_cycles := from_frequency * local_time
			phase_cycles += 0.5 * (to_frequency - from_frequency) * local_time * progress
			var oscillator := sin(TAU * phase_cycles)
			if str(note.get("wave", "sine")) == "triangle":
				oscillator = 2.0 / PI * asin(oscillator)
			var note_envelope := sin(PI * progress)
			sample += oscillator * float(note.get("gain", 0.2)) * note_envelope
		if time < noise_duration and noise_gain > 0.0:
			var noise_envelope := 1.0 - time / maxf(noise_duration, 0.0001)
			sample += random.randf_range(-1.0, 1.0) * noise_gain * noise_envelope
		var encoded_sample := int(clampf(sample * global_envelope, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(index * 2, encoded_sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _smooth_envelope(time: float, duration: float) -> float:
	var attack := minf(time / 0.006, 1.0)
	var release := pow(maxf(1.0 - time / maxf(duration, 0.0001), 0.0), 1.6)
	return attack * release


func _get_available_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	var fallback_player := _players[_voice_cursor % _players.size()]
	_voice_cursor += 1
	return fallback_player


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node)


func _connect_recursive(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node)
	for child in node.get_children():
		_connect_recursive(child)


func _connect_button(button: BaseButton) -> void:
	if bool(button.get_meta(CONNECTED_META, false)):
		return
	button.set_meta(CONNECTED_META, true)
	button.pressed.connect(_on_button_pressed.bind(button))
	button.mouse_entered.connect(_on_button_hovered.bind(button))
	button.focus_entered.connect(_on_button_hovered.bind(button))


func _on_button_pressed(button: BaseButton) -> void:
	if not is_instance_valid(button) or button.disabled:
		play_cue(&"blocked")
		return
	var cue := StringName(button.get_meta("audio_cue", DEFAULT_CUE))
	if button is CheckButton or button.toggle_mode:
		cue = &"toggle_on" if button.button_pressed else &"toggle_off"
	play_cue(cue)


func _on_button_hovered(button: BaseButton) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	if not bool(button.get_meta("audio_hover_enabled", true)):
		return
	play_cue(StringName(button.get_meta("audio_hover_cue", DEFAULT_HOVER_CUE)))


func _exit_tree() -> void:
	if get_tree() != null and get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	prepare_for_shutdown()
