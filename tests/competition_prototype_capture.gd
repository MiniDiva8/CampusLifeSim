extends SceneTree

var capture_failures := 0


func _initialize() -> void:
	_capture_all.call_deferred()


func _capture_all() -> void:
	var output_directory := ProjectSettings.globalize_path("res://reports/prototypes")
	DirAccess.make_dir_recursive_absolute(output_directory)
	var cases: Array[Dictionary] = [
		{
			"output": "res://reports/prototypes/01_tennis_portrait.png",
			"image_path": "res://assets/backgrounds/locations/field/网球.jpg",
			"orientation": 1,
			"media_width": 474,
			"scene_index": "01 / 03",
			"scene_name": "网球场",
			"activity": "正在打网球 · 体育馆运动区",
			"photo_shape": "竖版原图",
			"time": "第 3 天 · 周三 · 下午",
			"energy": 64,
			"stress": 46,
			"exam": 53,
			"section": "运动事件",
			"accent": "#63DDB8",
			"title": "再打一局，还是先看消息？",
			"body": "你刚在网球场找到节奏，项目群却连续弹出六条新消息。现在停下能及时处理，但这段难得的主动休息也会被打断。",
			"state_tags": [
				{"text": "精力尚可", "color": "#63DDB8"},
				{"text": "压力偏高", "color": "#FF8580"},
				{"text": "展示剩 4 天", "color": "#F4C45E"}
			],
			"question": "你准备怎样处理这段冲突？",
			"choices": [
				{"title": "继续打网球，完成这次休息", "detail": "先照顾状态，结束后再集中处理消息。", "effect": "压力 -12", "effect_color": "#63DDB8"},
				{"title": "到场边立即查看项目消息", "detail": "进度更及时，但休息会被切碎。", "effect": "项目 +6", "effect_color": "#7CB9E8"},
				{"title": "回复明确时间，稍后再处理", "detail": "建立协作边界，也让组员知道你的安排。", "effect": "关系 +3", "effect_color": "#F4C45E"}
			]
		},
		{
			"output": "res://reports/prototypes/02_teaching_landscape.png",
			"image_path": "res://assets/backgrounds/locations/teaching/理综楼.jpg",
			"orientation": 1,
			"media_width": 704,
			"scene_index": "02 / 03",
			"scene_name": "理综楼 · 空教室",
			"activity": "准备算法考试 · 自主复习",
			"photo_shape": "横版原图",
			"time": "第 4 天 · 周四 · 上午",
			"energy": 51,
			"stress": 61,
			"exam": 67,
			"section": "学习行动",
			"accent": "#7CB9E8",
			"title": "阳光很好，倒计时也还在",
			"title_size": 27,
			"body_height": 62,
			"body": "你在理综楼找到一间空教室。桌上的错题还没整理完，但连续学习已经让注意力开始漂移。",
			"state_tags": [
				{"text": "考试明天上午", "color": "#F4C45E"},
				{"text": "压力 61", "color": "#FF8580"}
			],
			"question": "这一小时怎样使用更稳妥？",
			"choices": [
				{"title": "专攻最薄弱的算法题", "detail": "收益高，但会继续累积压力。", "effect": "考试 +9", "effect_color": "#7CB9E8"},
				{"title": "整理错题并提前结束", "detail": "进度较慢，能避免状态进一步恶化。", "effect": "压力 -5", "effect_color": "#63DDB8"},
				{"title": "带着问题去找老师", "detail": "需要主动沟通，可能获得更准确的方向。", "effect": "理解 +7", "effect_color": "#F4C45E"}
			]
		},
		{
			"output": "res://reports/prototypes/03_canteen_action.png",
			"image_path": "res://assets/backgrounds/locations/canteen/早餐/f02efc55cdb9b357a2c89a3851c493ee.jpg",
			"orientation": 1,
			"media_width": 652,
			"scene_index": "03 / 03",
			"scene_name": "齐园食堂 · 早餐",
			"activity": "鸡蛋、牛奶与一份热早餐",
			"photo_shape": "横版近景",
			"time": "第 5 天 · 周五 · 早晨",
			"energy": 37,
			"stress": 74,
			"exam": 82,
			"section": "地点行动",
			"accent": "#F4C45E",
			"title": "考试前，先把早餐吃完",
			"title_size": 28,
			"body_height": 62,
			"body": "你来到齐园食堂。距离考试还有一个时段，身体需要能量，脑子却还在催你多看两页重点。",
			"state_tags": [
				{"text": "精力不足", "color": "#FF8580"},
				{"text": "即将考试", "color": "#F4C45E"}
			],
			"question": "早餐时间要怎么安排？",
			"choices": [
				{"title": "坐下来认真吃完", "detail": "恢复精力，让身体先回到可用状态。", "effect": "精力 +14", "effect_color": "#63DDB8"},
				{"title": "边吃边看最后一遍重点", "detail": "多一点准备，但大脑得不到真正休息。", "effect": "考试 +5", "effect_color": "#7CB9E8"},
				{"title": "和同学拼桌确认考试信息", "detail": "交换情报，也能缓解独自焦虑。", "effect": "关系 +3", "effect_color": "#F4C45E"}
			]
		}
	]

	for prototype_data in cases:
		var prototype := AdaptiveScenePrototypeView.new()
		root.add_child(prototype)
		prototype.configure(prototype_data)
		for _frame in 5:
			await process_frame
		_save_viewport(str(prototype_data.output))
		prototype.queue_free()
		await process_frame

	if capture_failures == 0:
		print("[PASS] competition UI prototypes written to reports/prototypes/")
		quit(0)
	else:
		printerr("[FAIL] %d competition UI prototypes could not be written" % capture_failures)
		quit(1)


func _save_viewport(path: String) -> void:
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		capture_failures += 1
		printerr("Viewport texture unavailable: %s" % path)
		return
	var image := viewport_texture.get_image()
	if image == null:
		capture_failures += 1
		printerr("Viewport image unavailable: %s" % path)
		return
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		capture_failures += 1
		printerr("Failed to save %s: %s" % [path, error_string(error)])
