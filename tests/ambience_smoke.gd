extends SceneTree

const AmbientSoundControllerScript = preload("res://scripts/services/ambient_sound_controller.gd")

var failures: Array[String] = []
var checks := 0
var transitions: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _run() -> void:
	var ambience := root.get_node_or_null("ProjectAmbientSoundController")
	_expect(ambience != null, "ambient sound controller should load as an autoload")
	if ambience == null:
		_finish()
		return
	ambience.soundscape_changed.connect(func(context: StringName, period: StringName): transitions.append("%s:%s" % [context, period]))
	_expect(ambience.get_supported_contexts().size() == 9, "soundscape service should expose menu, campus, road, and six locations")
	_expect(AmbientSoundControllerScript.period_from_slot(0) == &"day" and AmbientSoundControllerScript.period_from_slot(3) == &"evening" and AmbientSoundControllerScript.period_from_slot(4) == &"night", "five time slots should map to three audible periods")

	ambience.transition_to(&"menu", &"evening", 0.01, 20)
	await create_timer(0.04).timeout
	_expect(ambience.get_current_context() == &"menu" and ambience.get_current_period() == &"evening", "menu should receive its evening soundscape")
	ambience.transition_to(&"road", &"night", 0.02, 45)
	await create_timer(0.05).timeout
	_expect(ambience.get_current_context() == &"road" and transitions.has("road:night"), "travel should crossfade to a night road soundscape")
	var cached_before: int = ambience.get_cached_stream_count()
	ambience.prepare_context(&"library", &"night")
	_expect(ambience.get_cached_stream_count() == cached_before + 1, "destination soundscape should support prewarming during travel")
	ambience.transition_to(&"library", &"night", 0.02, 78)
	await create_timer(0.40).timeout
	_expect(ambience.get_current_context() == &"library", "destination should replace the road soundscape")
	_expect(ambience.get_stress_level() == 78 and ambience.is_stress_layer_playing(), "high stress should add the optional body-feedback layer")
	ambience.set_stress_level(30)
	await create_timer(0.40).timeout
	_expect(not ambience.is_stress_layer_playing(), "stress layer should fade out after recovery")
	_finish()


func _finish() -> void:
	var ambience := root.get_node_or_null("ProjectAmbientSoundController")
	if ambience != null:
		ambience.prepare_for_shutdown()
	var audio_director := root.get_node_or_null("ProjectUISoundController") as AudioDirector
	if audio_director != null:
		audio_director.prepare_for_shutdown()
	await process_frame
	await create_timer(0.25).timeout
	if failures.is_empty():
		print("[PASS] Ambience smoke: %d checks passed" % checks)
		quit(0)
	else:
		for failure in failures:
			printerr("[FAIL] %s" % failure)
		quit(1)
