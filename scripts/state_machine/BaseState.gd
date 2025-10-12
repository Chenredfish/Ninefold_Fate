# BaseState.gd
# 狀態機的基礎狀態類，所有具體狀態都應該繼承此類

class_name BaseState
extends RefCounted

# 狀態的唯一標識符
var state_id: String = ""
# 狀態所屬的狀態機引用
var state_machine: BaseStateMachine = null
# 狀態的額外數據
var state_data: Dictionary = {}

# 狀態生命週期函數
func _init(id: String = ""):
	state_id = id

# 進入狀態時調用
func enter(previous_state: BaseState = null, data: Dictionary = {}):
	state_data = data
	print("[StateManager] Entering state: ", state_id)

# 離開狀態時調用
func exit(next_state: BaseState = null):
	print("[StateManager] Exiting state: ", state_id)

# 狀態更新，每幀調用（如果需要）
func update(delta: float):
	pass

# 物理更新，每物理幀調用（如果需要）
func physics_update(delta: float):
	pass

# 處理輸入事件
func handle_input(event: InputEvent):
	pass

# 檢查是否可以轉換到指定狀態
func can_transition_to(next_state_id: String) -> bool:
	return true

# 獲取狀態信息（用於調試）
func get_state_info() -> Dictionary:
	return {
		"id": state_id,
		"class": get_script().get_global_name() if get_script() else "BaseState",
		"data": state_data
	}

# 事件處理（用於與EventBus整合）
func on_event(event_name: String, event_data: Dictionary = {}):
	# 子類可以重寫此方法來處理特定事件
	pass