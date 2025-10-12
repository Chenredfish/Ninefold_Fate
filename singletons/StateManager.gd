# StateManager.gd - AutoLoad 單例
# 狀態機管理器，統一管理遊戲中所有狀態機實例

extends Node

# 狀態機實例字典
var state_machines: Dictionary = {}

# 全域狀態機
var game_scene_state_machine: GameSceneStateMachine = null

# 戰鬥狀態機（動態創建）
var battle_state_machine: BattleStateMachine = null

# 調試配置
var debug_enabled: bool = true
var log_state_changes: bool = true

func _ready():
	add_to_group("autoload_statemanager")
	print("[StateManager] 狀態機管理器已初始化")
	
	# 初始化全域狀態機
	_initialize_global_state_machines()
	
	# 連接EventBus事件
	_connect_event_bus()

func _initialize_global_state_machines():
	# 創建遊戲場景狀態機
	game_scene_state_machine = GameSceneStateMachine.new()
	add_child(game_scene_state_machine)
	register_state_machine("game_scene", game_scene_state_machine)
	
	# 設置初始狀態
	game_scene_state_machine.transition_to("main_menu")
	
	print("[StateManager] 全域狀態機初始化完成")

func _connect_event_bus():
	# 監聽狀態機相關事件
	EventBus.state_changed.connect(_on_state_changed)
	EventBus.transition_failed.connect(_on_transition_failed)
	
	# 監聽戰鬥事件
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)

# 註冊狀態機
func register_state_machine(name: String, state_machine: BaseStateMachine) -> bool:
	if state_machines.has(name):
		print("[StateManager] Warning: State machine '", name, "' already exists, replacing...")
	
	state_machines[name] = state_machine
	
	# 連接狀態機信號
	if not state_machine.state_changed.is_connected(_on_state_machine_state_changed):
		state_machine.state_changed.connect(_on_state_machine_state_changed.bind(name))
	
	if not state_machine.transition_failed.is_connected(_on_state_machine_transition_failed):
		state_machine.transition_failed.connect(_on_state_machine_transition_failed.bind(name))
	
	# 通知EventBus
	EventBus.emit_signal("state_machine_created", name, state_machine)
	
	if debug_enabled:
		print("[StateManager] Registered state machine: ", name)
	
	return true

# 註銷狀態機
func unregister_state_machine(name: String) -> bool:
	if not state_machines.has(name):
		print("[StateManager] Error: State machine '", name, "' does not exist")
		return false
	
	var state_machine = state_machines[name]
	
	# 斷開信號連接
	if state_machine.state_changed.is_connected(_on_state_machine_state_changed):
		state_machine.state_changed.disconnect(_on_state_machine_state_changed)
	
	if state_machine.transition_failed.is_connected(_on_state_machine_transition_failed):
		state_machine.transition_failed.disconnect(_on_state_machine_transition_failed)
	
	state_machines.erase(name)
	
	if debug_enabled:
		print("[StateManager] Unregistered state machine: ", name)
	
	return true

# 獲取狀態機
func get_state_machine(name: String) -> BaseStateMachine:
	return state_machines.get(name, null)

# 獲取所有狀態機名稱
func get_state_machine_names() -> Array[String]:
	var names: Array[String] = []
	for name in state_machines.keys():
		names.append(name)
	return names

# 場景切換方法
func change_scene(scene_type, data: Dictionary = {}):
	if game_scene_state_machine:
		game_scene_state_machine.change_scene_to(scene_type, data)

# 拖拽操作（委託給DragDropManager）
func start_drag(object: Node, position: Vector2) -> bool:
	# 委託給現有的DragDropManager
	if DragDropManager.has_method("start_drag"):
		return DragDropManager.start_drag(object, position)
	return false

# 創建戰鬥狀態機
func create_battle_state_machine() -> BattleStateMachine:
	if battle_state_machine:
		# 清理舊的戰鬥狀態機
		destroy_battle_state_machine()
	
	battle_state_machine = BattleStateMachine.new()
	add_child(battle_state_machine)
	register_state_machine("battle", battle_state_machine)
	
	return battle_state_machine

# 銷毀戰鬥狀態機
func destroy_battle_state_machine():
	if battle_state_machine:
		unregister_state_machine("battle")
		battle_state_machine.queue_free()
		battle_state_machine = null

# 獲取當前場景狀態
func get_current_scene_state() -> String:
	if game_scene_state_machine:
		return game_scene_state_machine.get_current_state_id()
	return ""

# 獲取當前戰鬥狀態
func get_current_battle_state() -> String:
	if battle_state_machine:
		return battle_state_machine.get_current_state_id()
	return ""

# 獲取當前拖放狀態（從DragDropManager獲取）
func get_current_drag_drop_state() -> String:
	# 從DragDropManager獲取拖放狀態
	if DragDropManager.current_dragging_tile != null:
		return "dragging"
	return "idle"

# 暫停所有狀態機
func pause_all_state_machines():
	for state_machine in state_machines.values():
		if state_machine.has_method("set_auto_process"):
			state_machine.set_auto_process(false)
			state_machine.set_auto_physics_process(false)
	
	EventBus.emit_signal("game_paused")

# 恢復所有狀態機
func resume_all_state_machines():
	for state_machine in state_machines.values():
		if state_machine.has_method("set_auto_process"):
			state_machine.set_auto_process(true)
			# 物理處理根據需要設置
	
	EventBus.emit_signal("game_resumed")

# 獲取調試信息
func get_debug_info() -> Dictionary:
	var info = {
		"total_state_machines": state_machines.size(),
		"state_machines": {}
	}
	
	for name in state_machines:
		var state_machine = state_machines[name]
		if state_machine and state_machine.has_method("get_debug_info"):
			info.state_machines[name] = state_machine.get_debug_info()
	
	return info

# 打印調試信息
func print_debug_info():
	if not debug_enabled:
		return
	
	print("[StateManager] === 狀態機調試信息 ===")
	print("[StateManager] 總數: ", state_machines.size())
	
	for name in state_machines:
		var state_machine = state_machines[name]
		if state_machine:
			var current_state = state_machine.get_current_state_id()
			print("[StateManager] ", name, ": ", current_state)
	
	print("[StateManager] === 調試信息結束 ===")

# 設置調試模式
func set_debug_enabled(enabled: bool):
	debug_enabled = enabled
	log_state_changes = enabled
	
	# 設置所有狀態機的調試模式
	for state_machine in state_machines.values():
		if state_machine.has_method("set_debug_enabled"):
			state_machine.set_debug_enabled(enabled)

# EventBus 事件處理
func _on_state_changed(state_machine_name: String, previous_state: String, current_state: String):
	if log_state_changes:
		print("[StateManager] ", state_machine_name, ": ", previous_state, " -> ", current_state)

func _on_transition_failed(state_machine_name: String, from_state: String, to_state: String, reason: String):
	print("[StateManager] Transition failed in ", state_machine_name, ": ", from_state, " -> ", to_state, " (", reason, ")")

func _on_battle_started(level_data: Dictionary):
	# 創建戰鬥狀態機
	var battle_sm = create_battle_state_machine()
	if battle_sm:
		battle_sm.start_battle(level_data)

func _on_battle_ended(result: String, rewards: Array):
	# 銷毀戰鬥狀態機
	destroy_battle_state_machine()

# 狀態機信號處理（帶名稱綁定）
func _on_state_machine_state_changed(state_machine_name: String, previous_state_id: String, current_state_id: String):
	EventBus.emit_signal("state_changed", state_machine_name, previous_state_id, current_state_id)

func _on_state_machine_transition_failed(state_machine_name: String, from_state_id: String, to_state_id: String, reason: String):
	EventBus.emit_signal("transition_failed", state_machine_name, from_state_id, to_state_id, reason)

# 輸入處理（轉發給戰鬥狀態機，拖放由DragDropManager處理）
func _input(event: InputEvent):
	# 戰鬥狀態機處理輸入（拖放由DragDropManager自行處理）
	if battle_state_machine:
		battle_state_machine.handle_input(event)

# 便利方法：快速場景切換
func go_to_main_menu(data: Dictionary = {}):
	change_scene(GameSceneStateMachine.SceneType.MAIN_MENU, data)

func go_to_level_selection(data: Dictionary = {}):
	change_scene(GameSceneStateMachine.SceneType.LEVEL_SELECTION, data)

func go_to_battle(level_id: String):
	change_scene(GameSceneStateMachine.SceneType.BATTLE, {"level_id": level_id})

func go_to_result(result: String, rewards: Array = []):
	change_scene(GameSceneStateMachine.SceneType.RESULT, {
		"battle_result": result,
		"rewards": rewards
	})

func go_to_settings(data: Dictionary = {}):
	change_scene(GameSceneStateMachine.SceneType.SETTINGS, data)

# 便利方法：戰鬥控制
func submit_player_turn():
	if battle_state_machine and battle_state_machine.is_in_state("player_turn"):
		EventBus.emit_signal("player_turn_submit")

func end_battle_with_victory():
	if battle_state_machine:
		battle_state_machine.transition_to("victory")

func end_battle_with_defeat():
	if battle_state_machine:
		battle_state_machine.transition_to("defeat")