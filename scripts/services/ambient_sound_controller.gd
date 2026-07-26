class_name AmbientSoundController
extends Node
## Procedural, offline campus soundscapes with semantic context switching.
##
## Each context is generated from deterministic tones and filtered noise. The
## public context API remains stable when field recordings replace these loops.

signal soundscape_changed(context: StringName, period: StringName)

const MIX_RATE := 22050
const LOOP_SECONDS := 8.0
const STRESS_LOOP_SECONDS := 4.0
const SILENT_DB := -60.0
const PERIODIC_PITCHED_CUES_ENABLED := false
const CONTEXTS: Array[StringName] = [
	&"menu",
	&"campus",
	&"road",
	&"dorm",
	&"library",
	&"teaching",
	&"lab",
	&"canteen",
	&"field",
]
const BASE_VOLUME_DB := {
	&"menu": -10.0,
	&"campus": -8.0,
	&"road": -6.0,
	&"dorm": -9.0,
	&"library": -12.0,
	&"teaching": -10.0,
	&"lab": -10.0,
	&"canteen": -11.0,
	&"field": -8.0,
}

var _players: Array[AudioStreamPlayer] = []
var _active_player_index := 0
var _current_context: StringName = &""
var _current_period: StringName = &""
var _stream_cache: Dictionary = {}
var _crossfade_tween: Tween
var _stress_player: AudioStreamPlayer
var _stress_tween: Tween
var _stress_level := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in 2:
		var player := AudioStreamPlayer.new()
		player.name = "AmbientLayer%d" % index
		player.bus = &"Ambience"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)
	_stress_player = AudioStreamPlayer.new()
	_stress_player.name = "StressBodyLayer"
	_stress_player.bus = &"Stress"
	_stress_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_stress_player.volume_db = SILENT_DB
	add_child(_stress_player)


static func period_from_slot(slot: int) -> StringName:
	if slot <= 2:
		return &"day"
	if slot == 3:
		return &"evening"
	return &"night"


func transition_to(context: StringName, period: StringName = &"day", fade_seconds: float = 0.65, stress_level: int = 0) -> void:
	var safe_context := context if CONTEXTS.has(context) else &"campus"
	var safe_period := period if period in [&"day", &"evening", &"night"] else &"day"
	set_stress_level(stress_level)
	if safe_context == _current_context and safe_period == _current_period:
		return
	var stream := _get_or_build_stream(safe_context, safe_period)
	var next_index := 1 - _active_player_index
	var next_player := _players[next_index]
	var previous_player := _players[_active_player_index]
	next_player.stop()
	next_player.stream = stream
	next_player.bus = &"Ambience"
	next_player.volume_db = SILENT_DB
	next_player.pitch_scale = _period_pitch(safe_period)
	next_player.play()
	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	var target_db := float(BASE_VOLUME_DB.get(safe_context, -9.0)) + _period_volume_offset(safe_context, safe_period)
	var duration := maxf(fade_seconds, 0.0)
	if duration <= 0.0:
		next_player.volume_db = target_db
		previous_player.stop()
		previous_player.stream = null
	else:
		_crossfade_tween = create_tween().set_parallel(true)
		_crossfade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_crossfade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_crossfade_tween.tween_property(next_player, "volume_db", target_db, duration)
		if previous_player.playing:
			_crossfade_tween.tween_property(previous_player, "volume_db", SILENT_DB, duration)
		_crossfade_tween.chain().tween_callback(_finish_crossfade.bind(_active_player_index, safe_context, safe_period))
	_active_player_index = next_index
	_current_context = safe_context
	_current_period = safe_period
	soundscape_changed.emit(safe_context, safe_period)


func set_stress_level(value: int) -> void:
	_stress_level = clampi(value, 0, 100)
	if _stress_tween != null and _stress_tween.is_valid():
		_stress_tween.kill()
	if _stress_level < 60:
		if _stress_player.playing:
			_stress_tween = create_tween()
			_stress_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			_stress_tween.tween_property(_stress_player, "volume_db", SILENT_DB, 0.35)
			_stress_tween.tween_callback(_stop_stress_layer)
		return
	if _stress_player.stream == null:
		_stress_player.stream = _build_stress_stream()
	if not _stress_player.playing:
		_stress_player.volume_db = SILENT_DB
		_stress_player.play()
	var intensity := clampf(float(_stress_level - 60) / 40.0, 0.0, 1.0)
	var target_db := lerpf(-25.0, -9.0, intensity)
	_stress_player.pitch_scale = lerpf(0.86, 1.18, intensity)
	_stress_tween = create_tween()
	_stress_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_stress_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_stress_tween.tween_property(_stress_player, "volume_db", target_db, 0.35)


func get_current_context() -> StringName:
	return _current_context


func get_current_period() -> StringName:
	return _current_period


func get_stress_level() -> int:
	return _stress_level


func is_stress_layer_playing() -> bool:
	return is_instance_valid(_stress_player) and _stress_player.playing


func get_cached_stream_count() -> int:
	return _stream_cache.size()


func get_supported_contexts() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(CONTEXTS)
	return result


func prepare_context(context: StringName, period: StringName) -> void:
	var safe_context := context if CONTEXTS.has(context) else &"campus"
	var safe_period := period if period in [&"day", &"evening", &"night"] else &"day"
	_get_or_build_stream(safe_context, safe_period)


func prepare_for_shutdown() -> void:
	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	if _stress_tween != null and _stress_tween.is_valid():
		_stress_tween.kill()
	for player in _players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			player.free()
	_players.clear()
	if is_instance_valid(_stress_player):
		_stress_player.stop()
		_stress_player.stream = null
		_stress_player.free()
	_stream_cache.clear()


func _finish_crossfade(previous_index: int, expected_context: StringName, expected_period: StringName) -> void:
	if _current_context != expected_context or _current_period != expected_period:
		return
	if previous_index >= 0 and previous_index < _players.size() and previous_index != _active_player_index:
		var previous_player := _players[previous_index]
		previous_player.stop()
		previous_player.stream = null


func _stop_stress_layer() -> void:
	if _stress_level >= 60:
		return
	_stress_player.stop()
	_stress_player.stream = null


func _get_or_build_stream(context: StringName, period: StringName) -> AudioStreamWAV:
	var key := "%s:%s" % [context, period]
	if not _stream_cache.has(key):
		_stream_cache[key] = _build_ambient_stream(context, period)
	return _stream_cache[key]


func _build_ambient_stream(context: StringName, period: StringName) -> AudioStreamWAV:
	var sample_count := int(MIX_RATE * LOOP_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 4)
	var random := RandomNumberGenerator.new()
	random.seed = 20260722 ^ String(context).hash() ^ (String(period).hash() * 31)
	var slow_left := 0.0
	var slow_right := 0.0
	var fast_left := 0.0
	var fast_right := 0.0
	var activity := _activity_density(period)
	var night := _night_density(period)
	for index in sample_count:
		var time := float(index) / float(MIX_RATE)
		slow_left = lerpf(slow_left, random.randf_range(-1.0, 1.0), 0.0035)
		slow_right = lerpf(slow_right, random.randf_range(-1.0, 1.0), 0.0035)
		fast_left = lerpf(fast_left, random.randf_range(-1.0, 1.0), 0.075)
		fast_right = lerpf(fast_right, random.randf_range(-1.0, 1.0), 0.075)
		var pair := _sample_context(context, time, slow_left, slow_right, fast_left, fast_right, activity, night)
		var seam := _loop_edge_envelope(time, LOOP_SECONDS)
		var left_sample := int(clampf(pair.x * seam, -1.0, 1.0) * 32767.0)
		var right_sample := int(clampf(pair.y * seam, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(index * 4, left_sample)
		bytes.encode_s16(index * 4 + 2, right_sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = true
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = bytes
	return stream


func _sample_context(context: StringName, time: float, slow_left: float, slow_right: float, fast_left: float, fast_right: float, activity: float, night: float) -> Vector2:
	var left := 0.0
	var right := 0.0
	match context:
		&"menu":
			left = slow_left * 0.09 + fast_left * 0.012 + sin(TAU * 55.0 * time) * 0.008
			right = slow_right * 0.09 + fast_right * 0.012 + sin(TAU * 55.0 * time + 0.4) * 0.008
		&"campus":
			left = slow_left * 0.20 + fast_left * 0.022
			right = slow_right * 0.20 + fast_right * 0.022
			var steps := _footstep_train(time, 0.63, 0.72, 0.060 * activity)
			left += steps
			right += _footstep_train(time, 0.63, 1.035, 0.054 * activity)
			left += _night_insects(time, night) * 0.7
			right += _night_insects(time + 0.11, night)
		&"road":
			var wind_left := slow_left * (0.23 + 0.08 * sin(TAU * 0.12 * time))
			var wind_right := slow_right * (0.23 + 0.08 * sin(TAU * 0.10 * time + 1.1))
			left = wind_left + fast_left * 0.028
			right = wind_right + fast_right * 0.028
			left += _footstep_train(time, 0.51, 0.18, 0.085 * activity)
			right += _footstep_train(time, 0.51, 0.435, 0.080 * activity)
			left += _night_insects(time, night) * 0.75
			right += _night_insects(time + 0.16, night) * 0.9
		&"dorm":
			var fan_left := sin(TAU * 82.0 * time) * 0.018 + sin(TAU * 164.0 * time) * 0.008
			var fan_right := sin(TAU * 81.4 * time + 0.5) * 0.018 + sin(TAU * 162.8 * time) * 0.008
			left = slow_left * 0.10 + fast_left * 0.018 + fan_left
			right = slow_right * 0.10 + fast_right * 0.018 + fan_right
			var keyboard := _keyboard_cluster(time, activity + night * 0.25, fast_left)
			left += keyboard
			right += _keyboard_cluster(time + 0.025, activity + night * 0.25, fast_right) * 0.76
			var door := _decay_tone(time, 6.65, 105.0, 0.38, 0.052 * activity)
			left += door * 0.65
			right += door
		&"library":
			left = slow_left * 0.055 + fast_left * 0.008 + sin(TAU * 48.0 * time) * 0.004
			right = slow_right * 0.055 + fast_right * 0.008 + sin(TAU * 48.2 * time) * 0.004
			var page_left := _noise_burst(time, 2.05, 0.28, fast_left, 0.10 * activity)
			page_left += _noise_burst(time, 5.72, 0.34, fast_left, 0.085 * activity)
			var page_right := _noise_burst(time, 3.55, 0.30, fast_right, 0.080 * activity)
			left += page_left + _keyboard_cluster(time + 0.3, activity * 0.45, fast_left) * 0.42
			right += page_right + _keyboard_cluster(time + 0.5, activity * 0.45, fast_right) * 0.36
		&"teaching":
			left = slow_left * 0.085 + fast_left * 0.015 + sin(TAU * 52.0 * time) * 0.005
			right = slow_right * 0.085 + fast_right * 0.015 + sin(TAU * 51.7 * time) * 0.005
			left += _footstep_train(time, 0.72, 1.15, 0.065 * activity)
			right += _footstep_train(time, 0.72, 1.51, 0.060 * activity)
		&"lab":
			var machine_left := sin(TAU * 94.0 * time) * 0.020 + sin(TAU * 188.0 * time) * 0.009
			var machine_right := sin(TAU * 96.0 * time + 0.6) * 0.020 + sin(TAU * 192.0 * time) * 0.009
			left = slow_left * 0.115 + fast_left * 0.022 + machine_left
			right = slow_right * 0.115 + fast_right * 0.022 + machine_right
			left += _keyboard_cluster(time, 0.78 + activity * 0.30, fast_left)
			right += _keyboard_cluster(time + 0.04, 0.72 + activity * 0.28, fast_right) * 0.82
		&"canteen":
			var murmur_left := sin(TAU * 142.0 * time + sin(TAU * 0.35 * time)) * 0.020
			murmur_left += sin(TAU * 214.0 * time + sin(TAU * 0.27 * time)) * 0.014
			var murmur_right := sin(TAU * 158.0 * time + sin(TAU * 0.31 * time)) * 0.020
			murmur_right += sin(TAU * 238.0 * time + sin(TAU * 0.22 * time)) * 0.013
			left = slow_left * 0.15 + fast_left * 0.032 + murmur_left * activity
			right = slow_right * 0.15 + fast_right * 0.032 + murmur_right * activity
			left += _noise_burst(time, 1.72, 0.12, fast_left, 0.022 * activity)
			left += _noise_burst(time, 4.46, 0.14, fast_left, 0.018 * activity)
			right += _noise_burst(time, 3.08, 0.12, fast_right, 0.020 * activity)
			right += _noise_burst(time, 6.52, 0.14, fast_right, 0.016 * activity)
		&"field":
			left = slow_left * 0.24 + fast_left * 0.025
			right = slow_right * 0.24 + fast_right * 0.025
			var bounce_left := _ball_bounce(time, 1.55, 0.095 * activity) + _ball_bounce(time, 4.18, 0.085 * activity)
			var bounce_right := _ball_bounce(time, 2.92, 0.090 * activity) + _ball_bounce(time, 5.36, 0.080 * activity)
			left += bounce_left
			right += bounce_right
			left += _night_insects(time, night) * 0.75
			right += _night_insects(time + 0.13, night)
	return Vector2(left, right)


func _build_stress_stream() -> AudioStreamWAV:
	var sample_count := int(MIX_RATE * STRESS_LOOP_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var time := float(index) / float(MIX_RATE)
		var beat_time := fmod(time, 1.0)
		var first_beat := _local_decay_tone(beat_time, 0.0, 63.0, 0.24, 0.34)
		var second_beat := _local_decay_tone(beat_time, 0.23, 52.0, 0.22, 0.24)
		var rumble := sin(TAU * 31.0 * time) * 0.035 + sin(TAU * 37.0 * time + 0.7) * 0.025
		var sample := clampf(first_beat + second_beat + rumble, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = bytes
	return stream


func _keyboard_cluster(time: float, density: float, noise: float) -> float:
	var result := 0.0
	for start in [0.86, 1.02, 1.19, 3.28, 3.41, 3.62, 5.18, 5.31, 7.02]:
		result += _noise_burst(time, float(start), 0.035, noise, 0.050 * density)
	return result


func _footstep_train(time: float, spacing: float, offset: float, gain: float) -> float:
	if time < offset:
		return 0.0
	var local_time := fmod(time - offset, spacing)
	return _local_decay_tone(local_time, 0.0, 92.0, 0.17, gain)


func _ball_bounce(time: float, start: float, gain: float) -> float:
	return _decay_tone(time, start, 128.0, 0.30, gain) + _decay_tone(time, start + 0.07, 82.0, 0.22, gain * 0.45)


func _decay_tone(time: float, start: float, frequency: float, duration: float, gain: float) -> float:
	return _local_decay_tone(time, start, frequency, duration, gain)


func _local_decay_tone(time: float, start: float, frequency: float, duration: float, gain: float) -> float:
	var local_time := time - start
	if local_time < 0.0 or local_time >= duration:
		return 0.0
	var envelope := exp(-5.0 * local_time / maxf(duration, 0.0001))
	return sin(TAU * frequency * local_time) * envelope * gain


func _noise_burst(time: float, start: float, duration: float, noise: float, gain: float) -> float:
	var local_time := time - start
	if local_time < 0.0 or local_time >= duration:
		return 0.0
	var progress := local_time / duration
	return noise * sin(PI * progress) * gain


func _night_insects(time: float, night_density: float) -> float:
	if night_density <= 0.0:
		return 0.0
	var pulse := pow(maxf(sin(TAU * 3.6 * time), 0.0), 5.0)
	return sin(TAU * 3650.0 * time) * pulse * 0.018 * night_density


func _loop_edge_envelope(time: float, duration: float) -> float:
	const EDGE_SECONDS := 0.045
	var fade_in := sin(PI * 0.5 * clampf(time / EDGE_SECONDS, 0.0, 1.0))
	var fade_out := sin(PI * 0.5 * clampf((duration - time) / EDGE_SECONDS, 0.0, 1.0))
	return fade_in * fade_out


func _activity_density(period: StringName) -> float:
	match period:
		&"evening":
			return 0.72
		&"night":
			return 0.38
		_:
			return 1.0


func _night_density(period: StringName) -> float:
	match period:
		&"evening":
			return 0.35
		&"night":
			return 1.0
		_:
			return 0.0


func _period_pitch(period: StringName) -> float:
	match period:
		&"evening":
			return 0.985
		&"night":
			return 0.96
		_:
			return 1.0


func _period_volume_offset(context: StringName, period: StringName) -> float:
	if context in [&"dorm", &"lab"]:
		return -0.5 if period == &"night" else 0.0
	match period:
		&"evening":
			return -1.5
		&"night":
			return -3.0
		_:
			return 0.0


func _exit_tree() -> void:
	prepare_for_shutdown()
