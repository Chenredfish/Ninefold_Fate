# DebugManager.gd - AutoLoad 單例
extends Node

var debug_enabled: bool = false
var debug_panel_visible: bool = false

func _ready():
	# 只在 Debug 模式下啟用
	debug_enabled = OS.is_debug_build()
	if debug_enabled:
		print("[DebugManager] 除錯系統已啟用")
		_setup_debug_input()
	else:
		print("[DebugManager] 發布模式 - 除錯功能已禁用")

func _setup_debug_input():
	# 設定除錯熱鍵
	print("[DebugManager] 按下 F1 開啟除錯資訊")

func _input(event):
	if not debug_enabled:
		return
		
	if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_F1):
		toggle_debug_info()

func toggle_debug_info():
	if not debug_enabled:
		return
		
	debug_panel_visible = !debug_panel_visible
	print("[DebugManager] 除錯資訊 ", "開啟" if debug_panel_visible else "關閉")
	
	if debug_panel_visible:
		show_debug_info()
	else:
		hide_debug_info()

func show_debug_info():
	print("=== 除錯資訊 ===")
	print("FPS: ", Engine.get_frames_per_second())
	print("記憶體使用: ", OS.get_static_memory_usage() / 1024.0 / 1024.0, " MB")
	
	# ResourceManager 狀態
	var rm = get_node_or_null("/root/ResourceManager")
	if rm:
		print("英雄數據庫: ", rm.hero_database.size(), " 項目")
		print("敵人數據庫: ", rm.enemy_database.size(), " 項目")
		print("凸塊數據庫: ", rm.block_database.size(), " 項目")
	else:
		print("ResourceManager 未載入")
	
	print("================")

func hide_debug_info():
	# 隱藏除錯面板的邏輯
	pass

func log_object_creation(object: Node):
	if debug_enabled:
		print("[DEBUG] 物件創建: ", object.name, " (", object.get_class(), ")")

func log_event_emission(event_name: String, data: Dictionary = {}):
	if debug_enabled:
		print("[DEBUG] 事件發送: ", event_name, " 數據: ", data)

func inspect_object(object: Node):
	if not debug_enabled:
		return
		
	print("=== 物件檢查器 ===")
	print("名稱: ", object.name)
	print("類型: ", object.get_class())
	print("位置: ", object.position if object.has_method("get_position") else "N/A")
	print("子節點數量: ", object.get_child_count())
	
	if object.get_child_count() > 0:
		print("子節點:")
		for child in object.get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
	
	print("==================")

# 測試各個單例的功能
func test_singletons():
	if not debug_enabled:
		return
		
	print("[DebugManager] 測試所有單例...")
	
	# 測試 EventBus
	print("測試 EventBus...")
	var eb = get_node_or_null("/root/EventBus")
	if eb:
		eb.test_events()
	else:
		print("EventBus 未找到!")
	
	# 測試 ResourceManager  
	print("測試 ResourceManager...")
	var rm = get_node_or_null("/root/ResourceManager")
	if rm:
		rm.test_resource_creation()
	else:
		print("ResourceManager 未找到!")
	
	print("[DebugManager] 單例測試完成")