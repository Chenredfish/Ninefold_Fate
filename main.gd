extends Node2D

func _ready():
	print("EventBus available: ", EventBus != null)
	print("ResourceManager available: ", ResourceManager != null)
	print("DebugManager available: ", DebugManager != null)
	print("DragDropManager available: ", DragDropManager != null)
	
	# Wait a frame before starting drag-drop test
	await get_tree().process_frame
	print("\nPress F1 to start drag-drop system test")
	print("Press F2 to start SimpleTest")  
	print("Press F3 to start LevelTile test")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				print("Starting drag-drop test scene...")
				get_tree().change_scene_to_file("res://test_scenes/DragDropTestScene.tscn")
			KEY_F2:
				print("Starting SimpleTest scene...")
				get_tree().change_scene_to_file("res://test_scenes/SimpleTestScene.tscn")
			KEY_F3:
				print("Starting LevelTile test scene...")
				get_tree().change_scene_to_file("res://test_scenes/LevelTileTestScene.tscn")
			_:
				pass
