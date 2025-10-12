extends Node2D

func _ready():
	print("EventBus 可用: ", EventBus != null)
	print("ResourceManager 可用: ", ResourceManager != null)
	print("DebugManager 可用: ", DebugManager != null)
	print("DragDropManager 可用: ", DragDropManager != null)
	
	# 等待一幀後啟動拖放測試
	await get_tree().process_frame
	print("\n按 F1 鍵啟動拖放系統測試")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				print("啟動拖放測試場景...")
				get_tree().change_scene_to_file("res://test_scenes/DragDropTestScene.tscn")
			KEY_F2:
				print("啟動SimpleTest場景...")
				get_tree().change_scene_to_file("res://test_scenes/SimpleTestScene.tscn")
			_:
				pass
