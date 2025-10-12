# SimpleLevelSelection.gd - Simple Level Selection System
class_name SimpleLevelSelection
extends Control

signal level_selected(level_data: Dictionary)

var available_levels: Array[String] = []

func _ready():
	print("=== Simple Level Selection Init ===")
	
	# Check ResourceManager
	if ResourceManager:
		var level_ids = ResourceManager.get_all_level_ids()
		available_levels.assign(level_ids)  # Safely assign Array to Array[String]
		print("Found levels:", available_levels)
	else:
		print("Warning: ResourceManager not found")
	
	# Create simple UI
	create_simple_ui()

func create_simple_ui():
	# Set background
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0.1, 0.1, 0.2, 1.0)
	add_child(bg)
	
	# Title
	var title = Label.new()
	title.text = "Simple Level Selection"
	title.position = Vector2(340, 200)
	title.size = Vector2(400, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)
	
	# Level buttons
	var y_offset = 400
	for i in range(min(available_levels.size(), 5)):
		var level_id = available_levels[i]
		var button = Button.new()
		button.text = "Level: " + level_id
		button.position = Vector2(440, y_offset + i * 80)
		button.size = Vector2(200, 60)
		
		# Connect button signal
		button.pressed.connect(_on_level_button_pressed.bind(level_id))
		add_child(button)
	
	# Back button
	var back_button = Button.new()
	back_button.text = "Back to Main"
	back_button.position = Vector2(440, 800)
	back_button.size = Vector2(200, 60)
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

func _on_level_button_pressed(level_id: String):
	print("Selected Level: ", level_id)
	
	var level_data = {}
	if ResourceManager:
		level_data = ResourceManager.get_level_data(level_id)
	
	level_selected.emit(level_data)

func _on_back_pressed():
	print("Back to Main Menu")
	# Can send signal or switch scene directly
	get_tree().change_scene_to_file("res://main.tscn")
