# StateMachineTest.gd
# 狀態機系統測試腳本（優化版 - 移除拖放狀態機）

extends Node

# 測試標記
var tests_completed: int = 0
var tests_total: int = 6  # 減少到6個測試（移除拖放狀態機測試）
var all_tests_passed: bool = true

func _ready():
	print("========== 狀態機系統測試開始 ==========")
	
	# 等待一幀確保所有AutoLoad初始化完成
	await get_tree().process_frame
	
	# 執行測試
	test_base_state_machine()
	test_game_scene_state_machine() 
	test_battle_state_machine()
	test_drag_drop_integration()  # 測試與現有DragDropManager的整合
	test_event_bus_integration()
	test_state_manager()
	
	# 打印測試結果
	print_test_results()

func test_base_state_machine():
	print("\n--- 測試 BaseStateMachine ---")
	
	var state_machine = BaseStateMachine.new()
	var test_state = TestState.new("test_state")
	
	# 測試添加狀態
	var success = state_machine.add_state(test_state)
	assert_test(success, "添加狀態成功")
	
	# 測試狀態轉換
	success = state_machine.transition_to("test_state")
	assert_test(success, "狀態轉換成功")
	
	# 測試當前狀態
	var current_state = state_machine.get_current_state_id()
	assert_test(current_state == "test_state", "當前狀態正確")
	
	state_machine.queue_free()
	complete_test("BaseStateMachine 測試")

func test_game_scene_state_machine():
	print("\n--- 測試 GameSceneStateMachine ---")
	
	# 檢查StateManager中的場景狀態機
	var scene_sm = StateManager.get_state_machine("game_scene")
	assert_test(scene_sm != null, "場景狀態機存在")
	
	if scene_sm:
		# 測試場景狀態
		var current_state = scene_sm.get_current_state_id()
		assert_test(current_state != "", "場景狀態機有當前狀態")
		
		# 測試狀態列表
		var state_ids = scene_sm.get_all_state_ids()
		assert_test(state_ids.size() > 0, "場景狀態機有可用狀態")
		print("可用場景狀態: ", state_ids)
	
	complete_test("GameSceneStateMachine 測試")

func test_battle_state_machine():
	print("\n--- 測試 BattleStateMachine ---")
	
	# 創建戰鬥狀態機
	var battle_sm = StateManager.create_battle_state_machine()
	assert_test(battle_sm != null, "戰鬥狀態機創建成功")
	
	if battle_sm:
		# 測試戰鬥狀態
		var state_ids = battle_sm.get_all_state_ids()
		assert_test(state_ids.size() > 0, "戰鬥狀態機有可用狀態")
		print("可用戰鬥狀態: ", state_ids)
		
		# 測試開始戰鬥
		var test_level_data = {
			"level_id": "test_level",
			"enemies": [{"id": "enemy_1", "hp": 100}],
			"player_hp": 100
		}
		battle_sm.start_battle(test_level_data)
		
		# 等待狀態轉換
		await get_tree().process_frame
		
		var current_state = battle_sm.get_current_state_id()
		assert_test(current_state != "", "戰鬥開始後有當前狀態")
	
	# 清理戰鬥狀態機
	StateManager.destroy_battle_state_machine()
	
	complete_test("BattleStateMachine 測試")

func test_drag_drop_integration():
	print("\n--- 測試 DragDropManager 整合 ---")
	
	# 測試DragDropManager是否存在
	assert_test(DragDropManager != null, "DragDropManager AutoLoad存在")
	
	if DragDropManager:
		# 測試DragDropManager信號
		var has_drag_signals = DragDropManager.has_signal("tile_drag_started") and \
								DragDropManager.has_signal("tile_drag_ended") and \
								DragDropManager.has_signal("navigation_requested")
		assert_test(has_drag_signals, "DragDropManager包含必要信號")
		
		# 測試StateManager的拖放狀態獲取
		var drag_state = StateManager.get_current_drag_drop_state()
		assert_test(drag_state == "idle", "拖放狀態正確獲取（idle）")
		
		# 測試拖放方法委託
		var has_drag_method = StateManager.has_method("start_drag")
		assert_test(has_drag_method, "StateManager提供拖放方法委託")
		
		print("DragDropManager當前狀態: 無拖拽物件" if DragDropManager.current_dragging_tile == null else "有拖拽物件")
	
	complete_test("DragDropManager 整合測試")

func test_event_bus_integration():
	print("\n--- 測試 EventBus 整合 ---")
	
	# 測試事件信號存在
	var has_state_signals = EventBus.has_signal("state_changed") and EventBus.has_signal("transition_failed")
	assert_test(has_state_signals, "EventBus包含狀態機事件")
	
	var has_scene_signals = EventBus.has_signal("scene_transition_requested") and EventBus.has_signal("scene_entered")
	assert_test(has_scene_signals, "EventBus包含場景切換事件")
	
	# 拖放事件現在由DragDropManager處理，不再在EventBus中
	print("注意: 拖放事件現在由DragDropManager直接管理")
	
	var has_battle_signals = EventBus.has_signal("player_turn_submit") and EventBus.has_signal("damage_calculated")
	assert_test(has_battle_signals, "EventBus包含戰鬥事件")
	
	complete_test("EventBus 整合測試")

func test_state_manager():
	print("\n--- 測試 StateManager ---")
	
	# 測試StateManager是否正確初始化
	assert_test(StateManager != null, "StateManager存在")
	
	# 測試狀態機註冊
	var state_machine_names = StateManager.get_state_machine_names()
	assert_test(state_machine_names.size() > 0, "StateManager有註冊的狀態機")
	print("已註冊的狀態機: ", state_machine_names)
	
	# 測試便利方法
	var current_scene_state = StateManager.get_current_scene_state()
	assert_test(current_scene_state != "", "可以獲取當前場景狀態")
	
	var current_drag_state = StateManager.get_current_drag_drop_state()
	assert_test(current_drag_state != "", "可以獲取當前拖放狀態")
	
	complete_test("StateManager 測試")

func test_state_transitions():
	print("\n--- 測試狀態轉換 ---")
	
	# 測試場景切換
	var scene_sm = StateManager.get_state_machine("game_scene")
	if scene_sm:
		var initial_state = scene_sm.get_current_state_id()
		
		# 嘗試切換到設定畫面
		var success = scene_sm.transition_to("settings")
		assert_test(success, "可以切換到設定狀態")
		
		if success:
			await get_tree().process_frame
			var new_state = scene_sm.get_current_state_id()
			assert_test(new_state == "settings", "成功切換到設定狀態")
			
			# 切換回原狀態
			scene_sm.transition_to(initial_state)
	
	complete_test("狀態轉換測試")

func test_error_handling():
	print("\n--- 測試錯誤處理 ---")
	
	var test_sm = BaseStateMachine.new()
	
	# 測試轉換到不存在的狀態
	var success = test_sm.transition_to("nonexistent_state")
	assert_test(not success, "轉換到不存在的狀態失敗")
	
	# 測試添加空狀態
	var null_state = BaseState.new("")
	success = test_sm.add_state(null_state)
	assert_test(not success, "添加空狀態失敗")
	
	test_sm.queue_free()
	
	complete_test("錯誤處理測試")

# 測試輔助方法
func assert_test(condition: bool, description: String):
	if condition:
		print("✓ ", description)
	else:
		print("✗ ", description)
		all_tests_passed = false

func complete_test(test_name: String):
	tests_completed += 1
	print("完成測試: ", test_name, " (", tests_completed, "/", tests_total, ")")

func print_test_results():
	print("\n========== 測試結果 ==========")
	print("完成測試數量: ", tests_completed, "/", tests_total)
	print("測試結果: ", "通過" if all_tests_passed else "失敗")
	
	if all_tests_passed:
		print("🎉 所有狀態機測試通過！")
		print("狀態機系統可以正常使用。")
	else:
		print("❌ 部分測試失敗，請檢查錯誤信息。")
	
	print("========== 測試結束 ==========")
	
	# 打印調試信息
	StateManager.print_debug_info()

# 測試用狀態類
class TestState extends BaseState:
	func _init(id: String):
		super._init(id)
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		print("TestState entered: ", state_id)
	
	func exit(next_state: BaseState = null):
		super.exit(next_state)
		print("TestState exited: ", state_id)