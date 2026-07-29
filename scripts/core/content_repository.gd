class_name ContentRepository
extends RefCounted

const DATA_FILES := {
	"locations": "res://data/locations.json",
	"npcs": "res://data/npcs.json",
	"events": "res://data/events.json",
	"ai_advice": "res://data/ai_advice.json",
	"endings": "res://data/endings.json",
}
const EFFECT_TYPES := ["stat", "relationship", "task", "flag"]

var locations: Array = []
var npcs: Array = []
var events: Array = []
var ai_advice: Array = []
var endings: Array = []
var errors: Array[String] = []
var _events_by_id: Dictionary = {}


func load_all() -> bool:
	errors.clear()
	locations = _load_array(DATA_FILES.locations, "locations")
	npcs = _load_array(DATA_FILES.npcs, "npcs")
	events = _load_array(DATA_FILES.events, "events")
	ai_advice = _load_array(DATA_FILES.ai_advice, "ai_advice")
	endings = _load_array(DATA_FILES.endings, "endings")
	validate()
	return errors.is_empty()


func _load_array(path: String, label: String) -> Array:
	if not FileAccess.file_exists(path):
		errors.append("Missing data file: %s" % path)
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Cannot open data file: %s" % path)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		errors.append("%s must contain a JSON array" % label)
		return []
	return parsed


func validate() -> void:
	_validate_unique_ids(locations, "location")
	_validate_unique_ids(npcs, "npc")
	_validate_unique_ids(events, "event")
	_validate_unique_ids(ai_advice, "AI advice")
	_validate_unique_ids(endings, "ending")
	_events_by_id.clear()
	var location_ids := _id_set(locations)
	var npc_ids := _id_set(npcs)
	for npc in npcs:
		if not npc is Dictionary:
			continue
		var npc_id := str(npc.get("id", ""))
		if not location_ids.has(str(npc.get("location", ""))):
			errors.append("NPC %s references an unknown location" % npc_id)
		var contact = npc.get("contact", {})
		if not contact is Dictionary or str(contact.get("title", "")).is_empty() or str(contact.get("label", "")).is_empty():
			errors.append("NPC %s needs a data-driven contact action" % npc_id)
		else:
			_validate_effects(contact.get("effects", []), "NPC contact %s" % npc_id)
	for event in events:
		if not event is Dictionary:
			continue
		var event_id := str(event.get("id", ""))
		_events_by_id[event_id] = event
		if str(event.get("title", "")).is_empty():
			errors.append("Event %s has no title" % event_id)
		var trigger: Dictionary = event.get("trigger", {})
		if str(trigger.get("type", "")) == "location" and not location_ids.has(str(trigger.get("location", ""))):
			errors.append("Event %s references an unknown location" % event_id)
		if str(event.get("kind", "")) == "npc" and not npc_ids.has(str(event.get("npc_id", ""))):
			errors.append("Event %s references an unknown NPC" % event_id)
		var choices = event.get("choices", [])
		if not choices is Array or choices.is_empty():
			errors.append("Event %s has no choices" % event_id)
			continue
		for choice in choices:
			_validate_effects(choice.get("effects", []), event_id)
			for delayed in choice.get("delayed", []):
				_validate_effects(delayed.get("effects", []), event_id)
	for advice in ai_advice:
		_validate_effects(advice.get("effects", []), "AI advice %s" % advice.get("id", ""))
	if locations.size() != 6:
		errors.append("Demo requires exactly 6 locations")
	if events.size() != 32:
		errors.append("Demo requires exactly 32 events, found %d" % events.size())
	if endings.size() != 7:
		errors.append("Demo requires exactly 7 endings")


func _validate_unique_ids(items: Array, label: String) -> void:
	var seen := {}
	for item in items:
		if not item is Dictionary:
			errors.append("Invalid %s entry" % label)
			continue
		var item_id := str(item.get("id", ""))
		if item_id.is_empty():
			errors.append("%s entry has no id" % label.capitalize())
		elif seen.has(item_id):
			errors.append("Duplicate %s id: %s" % [label, item_id])
		seen[item_id] = true


func _validate_effects(effects, owner_id: String) -> void:
	if not effects is Array:
		errors.append("Effects for %s must be an array" % owner_id)
		return
	for effect in effects:
		if not effect is Dictionary or not EFFECT_TYPES.has(str(effect.get("type", ""))):
			errors.append("Invalid effect in %s" % owner_id)


func _id_set(items: Array) -> Dictionary:
	var result := {}
	for item in items:
		if item is Dictionary:
			result[str(item.get("id", ""))] = true
	return result


func get_event(event_id: String) -> Dictionary:
	return _events_by_id.get(event_id, {})


func get_location(location_id: String) -> Dictionary:
	for location in locations:
		if str(location.get("id", "")) == location_id:
			return location
	return {}


func get_npc(npc_id: String) -> Dictionary:
	for npc in npcs:
		if str(npc.get("id", "")) == npc_id:
			return npc
	return {}
