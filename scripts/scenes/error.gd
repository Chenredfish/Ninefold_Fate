extends Control

func _ready():
	$VBoxContainer/BackButton.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed():
	# 返回主菜單
	var state_machine = StateManager.get_state_machine("game_scene")
	if state_machine:
		state_machine.transition_to("main_menu")
	else:
		get_tree().change_scene_to_file("res://scripts/scenes/main_menu.tscn")
