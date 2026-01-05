extends Node2D

func _ready():
	# 等待一幀來確保所有autoload已初始化
	await get_tree().process_frame
	
	# 啟動主選單
	print("[Main] Initializing game...")
	if StateManager and StateManager.game_scene_state_machine:
		print("[Main] StateManager ready, switching to main menu")
		# StateManager 會自動切換到 main_menu 狀態
	else:
		print("[Main] StateManager not ready, using fallback")
		# 備用方案：直接載入主菜單場景
		get_tree().change_scene_to_file("res://scripts/scenes/main_menu.tscn")
	
	#print("\nPress F1 to start drag-drop system test")
	#print("Press F2 to start SimpleTest")  
	#print("Press F3 to start LevelTile test")
	#print("Press F4 to start Enemy test (獨立測試)")
