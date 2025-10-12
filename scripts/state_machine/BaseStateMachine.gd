# BaseStateMachine.gd
# 通用狀態機基類，管理狀態轉換和生命週期

class_name BaseStateMachine
extends Node

# 信號定義
signal state_changed(previous_state_id: String, current_state_id: String)
signal transition_failed(from_state_id: String, to_state_id: String, reason: String)

# 狀態管理
var current_state: BaseState = null
var previous_state: BaseState = null
var states: Dictionary = {}
var state_history: Array[String] = []

# 狀態機配置
var max_history_size: int = 10
var debug_enabled: bool = true
var auto_process: bool = true
var auto_physics_process: bool = false

func _init():
	# 設置處理模式
	set_process(auto_process)
	set_physics_process(auto_physics_process)

func _ready():
	if debug_enabled:
		print("[StateMachine] ", name, " initialized with ", states.size(), " states")

func _process(delta):
	if current_state and auto_process:
		current_state.update(delta)

func _physics_process(delta):
	if current_state and auto_physics_process:
		current_state.physics_update(delta)

func _input(event):
	if current_state:
		current_state.handle_input(event)

# 添加狀態到狀態機
func add_state(state: BaseState) -> bool:
	if not state or state.state_id.is_empty():
		print("[StateMachine] Error: Invalid state or empty state_id")
		return false
	
	if states.has(state.state_id):
		print("[StateMachine] Warning: State '", state.state_id, "' already exists, replacing...")
	
	state.state_machine = self
	states[state.state_id] = state
	
	if debug_enabled:
		print("[StateMachine] Added state: ", state.state_id)
	
	return true

# 移除狀態
func remove_state(state_id: String) -> bool:
	if not states.has(state_id):
		print("[StateMachine] Error: State '", state_id, "' does not exist")
		return false
	
	# 如果要移除的是當前狀態，先轉換到null狀態
	if current_state and current_state.state_id == state_id:
		current_state.exit(null)
		current_state = null
	
	states.erase(state_id)
	
	if debug_enabled:
		print("[StateMachine] Removed state: ", state_id)
	
	return true

# 轉換到指定狀態
func transition_to(state_id: String, data: Dictionary = {}) -> bool:
	if not states.has(state_id):
		var reason = "State '" + state_id + "' does not exist"
		print("[StateMachine] Transition failed: ", reason)
		transition_failed.emit(
			current_state.state_id if current_state else "",
			state_id,
			reason
		)
		return false
	
	var next_state = states[state_id]
	
	# 檢查當前狀態是否允許轉換
	if current_state and not current_state.can_transition_to(state_id):
		var reason = "Current state '" + current_state.state_id + "' does not allow transition to '" + state_id + "'"
		print("[StateMachine] Transition failed: ", reason)
		transition_failed.emit(current_state.state_id, state_id, reason)
		return false
	
	# 執行狀態轉換
	var previous_state_id = current_state.state_id if current_state else ""
	
	# 退出當前狀態
	if current_state:
		current_state.exit(next_state)
		previous_state = current_state
	
	# 進入新狀態
	current_state = next_state
	current_state.enter(previous_state, data)
	
	# 更新歷史記錄
	_update_history(state_id)
	
	# 發送信號
	state_changed.emit(previous_state_id, state_id)
	
	if debug_enabled:
		print("[StateMachine] Transitioned: ", previous_state_id, " -> ", state_id)
	
	return true

# 獲取當前狀態ID
func get_current_state_id() -> String:
	return current_state.state_id if current_state else ""

# 獲取上一個狀態ID
func get_previous_state_id() -> String:
	return previous_state.state_id if previous_state else ""

# 檢查是否在指定狀態
func is_in_state(state_id: String) -> bool:
	return current_state != null and current_state.state_id == state_id

# 檢查狀態是否存在
func has_state(state_id: String) -> bool:
	return states.has(state_id)

# 回到上一個狀態
func go_back(data: Dictionary = {}) -> bool:
	if state_history.size() <= 1:  # 當前狀態也在歷史中，所以需要至少2個
		print("[StateMachine] Cannot go back: No previous state in history")
		return false
	
	# 獲取倒數第二個狀態（因為最後一個是當前狀態）
	var previous_state_id = state_history[state_history.size() - 2]
	
	# 從歷史中移除最後兩個狀態（避免重複添加）
	state_history = state_history.slice(0, state_history.size() - 2)
	
	return transition_to(previous_state_id, data)

# 獲取所有狀態ID列表
func get_all_state_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in states.keys():
		ids.append(id)
	return ids

# 獲取狀態機調試信息
func get_debug_info() -> Dictionary:
	return {
		"current_state": current_state.state_id if current_state else "null",
		"previous_state": previous_state.state_id if previous_state else "null",
		"total_states": states.size(),
		"state_history": state_history.duplicate(),
		"available_states": get_all_state_ids()
	}

# 清空狀態歷史
func clear_history():
	state_history.clear()
	if current_state:
		state_history.append(current_state.state_id)

# 設置調試模式
func set_debug_enabled(enabled: bool):
	debug_enabled = enabled

# EventBus 事件處理
func on_event(event_name: String, event_data: Dictionary = {}):
	if current_state:
		current_state.on_event(event_name, event_data)

# 私有方法：更新狀態歷史
func _update_history(state_id: String):
	state_history.append(state_id)
	
	# 限制歷史記錄大小
	if state_history.size() > max_history_size:
		state_history = state_history.slice(state_history.size() - max_history_size)

# 設置處理模式
func set_auto_process(enabled: bool):
	auto_process = enabled
	set_process(enabled)

func set_auto_physics_process(enabled: bool):
	auto_physics_process = enabled
	set_physics_process(enabled)