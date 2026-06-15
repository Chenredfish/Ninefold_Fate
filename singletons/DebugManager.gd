# DebugManager.gd - 開發調試功能集中管理
# 只在開發版本啟用，包含 F1~F4 快捷鍵和其他調試工具
extends Node

var debug_enabled: bool = OS.is_debug_build()

func _ready():
	if debug_enabled:
		print("[DebugManager] Debug shortcuts enabled (F1~F4 for test scenes)")
		print("[Global Shortcuts] F1:DragDropTest F2:SimpleTest F3:LevelTileTest F4:EnemyTest")
	add_to_group("autoload_debugmanager")

func _input(event: InputEvent):
	if not debug_enabled:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				print("[Debug] F1: Loading DragDrop test...")
				get_tree().change_scene_to_file("res://test_scenes/DragDropTestScene.tscn")
				get_tree().root.set_input_as_handled()
			KEY_F2:
				print("[Debug] F2: Loading Simple test...")
				get_tree().change_scene_to_file("res://test_scenes/SimpleTestScene.tscn")
				get_tree().root.set_input_as_handled()
			KEY_F3:
				print("[Debug] F3: Loading LevelTile test...")
				get_tree().change_scene_to_file("res://test_scenes/LevelTileTestScene.tscn")
				get_tree().root.set_input_as_handled()
			KEY_F4:
				print("[Debug] F4: Loading Enemy test...")
				get_tree().change_scene_to_file("res://test_scenes/EnemyTestScene.tscn")
				get_tree().root.set_input_as_handled()
