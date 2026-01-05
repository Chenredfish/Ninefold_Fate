# EnemyTestStandalone.gd - 獨立的敵人測試啟動器
# 這個場景可以設置為主場景來直接測試敵人系統
extends Node2D

func _ready():
	print("=== 獨立敵人測試環境 ===")
	print("正在初始化...")
	
	# 等待 AutoLoad 完全初始化
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 檢查系統狀態
	print("系統檢查:")
	print("  - EventBus: ", "✓" if EventBus else "✗")
	print("  - ResourceManager: ", "✓" if ResourceManager else "✗")
	
	# 載入敵人測試場景
	print("載入敵人測試場景...")
	var enemy_test_scene = preload("res://test_scenes/EnemyTestScene.tscn")
	var instance = enemy_test_scene.instantiate()
	get_tree().root.add_child(instance)
	
	# 移除自己
	queue_free()
	
	print("=== 敵人測試環境就緒 ===")
	print("控制說明:")
	print("  1 或 按鈕: 攻擊敵人")
	print("  2 或 按鈕: 手動倒數")  
	print("  R: 重新創建敵人")
	print("  F1: 顯示幫助")
	print("  ESC: 退出")
	print("===========================")