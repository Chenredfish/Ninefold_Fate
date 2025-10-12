extends Node2D

func _ready():
	print("EventBus 可用: ", EventBus != null)
	print("ResourceManager 可用: ", ResourceManager != null)
	print("DebugManager 可用: ", DebugManager != null)
	print("DragDropManager 可用: ", DragDropManager != null)
	
	# 等待一幀後啟動拖放測試
	await get_tree().process_frame
	print("\n按 T 鍵啟動拖放系統測試")

func _input(event):
	if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_T):
		print("啟動拖放測試場景...")
		get_tree().change_scene_to_file("res://test_scenes/DragDropTestScene.tscn")
