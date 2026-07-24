extends SceneTree

var failures: Array[String] = []
var checks := 0
var heard_cues: Array[StringName] = []


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _run() -> void:
	var director := root.get_node_or_null("ProjectUISoundController") as AudioDirector
	_expect(director != null, "semantic audio director should load as an autoload")
	if director == null:
		_finish()
		return
	director.cue_played.connect(func(cue: StringName): heard_cues.append(cue))
	await process_frame
	_expect(director.get_registered_cues().size() >= 14, "audio director should build the complete cue library")

	var choice_button := Button.new()
	choice_button.set_meta("audio_cue", &"choice")
	root.add_child(choice_button)
	await process_frame
	choice_button.pressed.emit()
	await process_frame
	_expect(heard_cues.has(&"choice"), "button metadata should select the choice cue")

	var toggle := CheckButton.new()
	toggle.button_pressed = true
	root.add_child(toggle)
	await process_frame
	toggle.pressed.emit()
	await process_frame
	_expect(heard_cues.has(&"toggle_on"), "check buttons should use state-aware toggle cues")

	director.play_cue(&"stat_up", true)
	_expect(heard_cues.has(&"stat_up"), "gameplay systems should be able to request a semantic cue directly")
	director.apply_mixer_settings({
		"master_volume": 0.7,
		"music_volume": 0.6,
		"sfx_volume": 0.0,
		"ambience_volume": 0.5,
		"pressure_audio": false,
	})
	_expect(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX")), "zero SFX volume should mute the SFX group")
	_expect(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Stress")), "pressure audio setting should mute the stress bus")
	director.fade_bus(&"Ambience", 0.25, 0.04)
	await create_timer(0.07).timeout
	var ambience_bus := AudioServer.get_bus_index(&"Ambience")
	_expect(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(ambience_bus)), 0.25), "bus fades should reach their requested target")
	director.fade_bus(&"Ambience", 0.0, 0.03)
	await create_timer(0.06).timeout
	_expect(AudioServer.is_bus_mute(ambience_bus), "a completed fade to silence should mute its bus")

	choice_button.queue_free()
	toggle.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	_finish()


func _finish() -> void:
	var director := root.get_node_or_null("ProjectUISoundController") as AudioDirector
	if director != null:
		director.prepare_for_shutdown()
	await process_frame
	if failures.is_empty():
		print("[PASS] Audio smoke: %d checks passed" % checks)
		quit(0)
	else:
		for failure in failures:
			printerr("[FAIL] %s" % failure)
		quit(1)
