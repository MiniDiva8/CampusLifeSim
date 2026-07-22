class_name DebugPresets
extends RefCounted
## Hidden command-line presets for repeatable judging and capture.
## Usage: CampusLifeSim.exe -- --demo-preset=balanced

const AVAILABLE := ["balanced", "study", "project", "ai", "pressure", "presentation"]


static func apply(session: GameSession, preset_id: String) -> bool:
	if not AVAILABLE.has(preset_id):
		return false
	session.reset("演示同学", "study")
	session.clock.day = 7
	session.clock.slot = 2
	session.stats.energy = 55
	session.stats.stress = 45
	session.stats.study = 55
	session.stats.project = 55
	session.tasks.exam = 75
	session.tasks.presentation = 72
	match preset_id:
		"balanced":
			session.stats.study = 70
			session.stats.project = 70
			session.stats.stress = 35
			for npc_id in session.relationships:
				session.relationships[npc_id] = 58
		"study":
			session.stats.study = 86
			session.stats.project = 48
		"project":
			session.stats.study = 48
			session.stats.project = 88
		"ai":
			session.stats.study = 62
			session.stats.project = 70
			session.stats.ai_dependence = 78
		"pressure":
			session.stats.energy = 12
			session.stats.stress = 94
		"presentation":
			session.flags.verified_ai = true
			session.stats.ai_dependence = 42
	return true
