# GameSceneStateMachine.gd
# 遊戲場景狀態機，管理不同場景間的轉換

class_name GameSceneStateMachine
extends BaseStateMachine

# 場景枚舉
enum SceneType {
	MAIN_MENU,
	LEVEL_SELECTION,
	BATTLE,
	RESULT,
	SETTINGS,
	DECK_BUILD  # 預留給構築系統
}

# 場景路徑配置
var scene_paths: Dictionary = {
	SceneType.MAIN_MENU: "res://scripts/scenes/main_menu.tscn",
	SceneType.LEVEL_SELECTION: "res://scripts/scenes/level_selection.tscn",
	SceneType.BATTLE: "res://scripts/scenes/battle.tscn",
	SceneType.RESULT: "res://scripts/scenes/result.tscn",
	SceneType.SETTINGS: "res://scripts/scenes/settings.tscn",
	SceneType.DECK_BUILD: "res://scripts/scenes/deck_build.tscn"
}

# 場景狀態映射
var scene_state_mapping: Dictionary = {
	SceneType.MAIN_MENU: "main_menu",
	SceneType.LEVEL_SELECTION: "level_selection", 
	SceneType.BATTLE: "battle",
	SceneType.RESULT: "result",
	SceneType.SETTINGS: "settings",
	SceneType.DECK_BUILD: "deck_build"
}

# 當前載入的場景
var current_scene: Node = null
var scene_loading: bool = false

func _init():
	super._init()
	name = "GameSceneStateMachine"
	
	# 初始化所有場景狀態
	_initialize_scene_states()
	
	# 連接EventBus事件
	_connect_event_bus()

func _initialize_scene_states():
	# 創建各個場景狀態
	add_state(MainMenuState.new())
	add_state(LevelSelectionState.new())
	add_state(BattleState.new())
	add_state(ResultState.new())
	add_state(SettingsState.new())
	add_state(DeckBuildState.new())

func _connect_event_bus():
	# 監聽場景切換事件
	if EventBus.has_signal("scene_transition_requested"):
		EventBus.scene_transition_requested.connect(_on_scene_transition_requested)
	
	# 監聽戰鬥相關事件
	if EventBus.has_signal("battle_ended"):
		EventBus.battle_ended.connect(_on_battle_ended)
	
	# 監聽關卡選擇事件
	if EventBus.has_signal("level_selected"):
		EventBus.level_selected.connect(_on_level_selected)

# 切換到指定場景
func change_scene_to(scene_type: SceneType, data: Dictionary = {}):
	if scene_loading:
		print("[GameSceneStateMachine] Scene loading in progress, ignoring request")
		return
	
	var state_id = scene_state_mapping.get(scene_type, "")
	if state_id.is_empty():
		print("[GameSceneStateMachine] Invalid scene type: ", scene_type)
		return
	
	transition_to(state_id, data)

# 載入場景文件
func load_scene(scene_type: SceneType) -> Node:
	var scene_path = scene_paths.get(scene_type, "")
	if scene_path.is_empty():
		print("[GameSceneStateMachine] No scene path for type: ", scene_type)
		return null
	
	scene_loading = true
	
	# 卸載當前場景
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	
	# 載入新場景
	var packed_scene = load(scene_path) as PackedScene
	if not packed_scene:
		print("[GameSceneStateMachine] Failed to load scene: ", scene_path)
		scene_loading = false
		return null
	
	var new_scene = packed_scene.instantiate()
	get_tree().root.add_child.call_deferred(new_scene)
	current_scene = new_scene
	
	scene_loading = false
	
	print("[GameSceneStateMachine] Loaded scene: ", scene_path)
	return new_scene

# 獲取當前場景
func get_current_scene() -> Node:
	return current_scene

# EventBus 事件處理
func _on_scene_transition_requested(target_scene: String, data: Dictionary = {}):
	# 根據場景名稱找到對應的枚舉值
	for scene_type in SceneType.values():
		if scene_state_mapping[scene_type] == target_scene:
			change_scene_to(scene_type, data)
			return
	
	print("[GameSceneStateMachine] Unknown scene requested: ", target_scene)

func _on_battle_ended(result: String, rewards: Array):
	# 戰鬥結束，切換到結算畫面
	change_scene_to(SceneType.RESULT, {
		"battle_result": result,
		"rewards": rewards
	})

func _on_level_selected(level_id: String):
	# 關卡選擇完成，載入戰鬥場景
	change_scene_to(SceneType.BATTLE, {
		"level_id": level_id
	})

# 場景狀態類定義

# 主選單狀態
class MainMenuState extends BaseState:
	func _init():
		super._init("main_menu")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		var scene = state_machine.load_scene(SceneType.MAIN_MENU)
		
		# 發送進入主選單事件
		EventBus.emit_signal("scene_entered", "main_menu")
	
	func can_transition_to(next_state_id: String) -> bool:
		# 主選單可以切換到任何場景
		return true

# 關卡選擇狀態
class LevelSelectionState extends BaseState:
	func _init():
		super._init("level_selection")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		var scene = state_machine.load_scene(SceneType.LEVEL_SELECTION)
		
		EventBus.emit_signal("scene_entered", "level_selection")
	
	func can_transition_to(next_state_id: String) -> bool:
		# 關卡選擇可以返回主選單或進入戰鬥
		return next_state_id in ["main_menu", "battle"]

# 戰鬥狀態
class BattleState extends BaseState:
	func _init():
		super._init("battle")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		var scene = state_machine.load_scene(SceneType.BATTLE)
		
		# 初始化戰鬥場景
		if scene and data.has("level_id"):
			if scene.has_method("initialize_battle"):
				scene.initialize_battle(data.level_id)
		
		EventBus.emit_signal("battle_started", data)
	
	func exit(next_state: BaseState = null):
		super.exit(next_state)
		# 清理戰鬥相關資源
		EventBus.emit_signal("battle_cleanup_requested")
	
	func can_transition_to(next_state_id: String) -> bool:
		# 戰鬥中只能切換到結算或返回選單
		return next_state_id in ["result", "main_menu", "level_selection"]

# 結算狀態
class ResultState extends BaseState:
	func _init():
		super._init("result")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		var scene = state_machine.load_scene(SceneType.RESULT)
		
		# 設置結算數據
		if scene and scene.has_method("set_result_data"):
			scene.set_result_data(data)
		
		EventBus.emit_signal("scene_entered", "result")
	
	func can_transition_to(next_state_id: String) -> bool:
		# 結算可以返回選單、重試戰鬥或繼續下一關
		return next_state_id in ["main_menu", "level_selection", "battle"]

# 設定狀態
class SettingsState extends BaseState:
	func _init():
		super._init("settings")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		var scene = state_machine.load_scene(SceneType.SETTINGS)
		
		EventBus.emit_signal("scene_entered", "settings")
	
	func can_transition_to(next_state_id: String) -> bool:
		# 設定可以返回任何場景
		return true

# 構築狀態（預留）
class DeckBuildState extends BaseState:
	func _init():
		super._init("deck_build")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		# MVP階段暫時顯示"敬請期待"
		print("[GameSceneStateMachine] 構築系統敬請期待")
		
		# 直接返回主選單
		state_machine.call_deferred("transition_to", "main_menu")
	
	func can_transition_to(next_state_id: String) -> bool:
		return next_state_id == "main_menu"
