# TestSingletonsScene.gd - 測試單例的場景腳本
extends Node2D

func _ready():
	print("=== 測試單例系統 ===")
	
	# 等待一幀確保所有 AutoLoad 都已載入
	await get_tree().process_frame
	
	test_event_bus()
	test_resource_manager()
	
	print("=== 測試完成 ===")

func test_event_bus():
	print("\n--- 測試 EventBus ---")
	
	# 連接一些事件監聽器
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.resource_loaded.connect(_on_resource_loaded)
	
	# 發送測試事件
	EventBus.battle_started.emit({"level_id": "test_level", "test_mode": true})
	EventBus.resource_loaded.emit("hero", "test_hero_001")
	
	print("EventBus 測試完成")

func test_resource_manager():
	print("\n--- 測試 ResourceManager ---")
	
	# 測試創建物件
	var test_hero = ResourceManager.create_hero("hero_001")
	var test_enemy = ResourceManager.create_enemy("enemy_001")
	var test_block = ResourceManager.create_block("block_001")
	
	# 將它們添加到場景中進行視覺化測試
	if test_hero:
		add_child(test_hero)
		test_hero.position = Vector2(200, 200)
		print("英雄創建成功，位置: ", test_hero.position)
	
	if test_enemy:
		add_child(test_enemy)
		test_enemy.position = Vector2(400, 200)
		print("敵人創建成功，位置: ", test_enemy.position)
	
	if test_block:
		add_child(test_block)
		test_block.position = Vector2(300, 350)
		print("凸塊創建成功，位置: ", test_block.position)
	
	print("ResourceManager 測試完成")

# 事件處理函數
func _on_battle_started(level_data: Dictionary):
	print("[事件接收] 戰鬥開始: ", level_data)

func _on_resource_loaded(resource_type: String, resource_id: String):
	print("[事件接收] 資源載入: ", resource_type, " - ", resource_id)

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Enter 鍵
		print("按下 Enter - 重新測試")
		test_event_bus()
	
	if event.is_action_pressed("ui_cancel"):  # ESC 鍵
		print("按下 ESC - 退出測試")
		get_tree().quit()