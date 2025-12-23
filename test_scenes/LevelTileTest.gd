# LevelTileTest.gd - Complete Level Selection System Test
# Based on UI_Interface_Specification.md - 三層架構的關卡選擇系統
extends Control

# UI Components
var main_info_area: Control
var chapter_title: Label
var progress_bar: ProgressBar
var level_detail_panel: Panel
var unified_confirm_grid: Control
var confirm_label: Label
var level_tile_container: ScrollContainer
var level_tile_scroll: HScrollBar
var back_button: Button

# State
var current_chapter: String = "chapter_01"
var available_levels: Array = []
var selected_level_id: String = ""

func _ready():
	print("=== Level Selection System Test ===")
	setup_ui()
	load_chapter_levels()

func setup_ui():
	# Set up as fullscreen control
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create three-layer architecture following UI specification
	create_main_info_area()     # Top layer (0-1000px)
	create_confirm_grid()       # Middle layer (1000-1600px) 
	create_level_tile_area()    # Bottom layer (1600-1920px)

func create_main_info_area():
	# Upper area - Chapter info and level details (0, 0) - (1080, 1000)
	main_info_area = Control.new()
	main_info_area.size = Vector2(1080, 1000)
	main_info_area.position = Vector2(0, 0)
	add_child(main_info_area)
	
	# Background
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1000)
	bg.color = Color(0.1, 0.1, 0.2, 1.0)
	main_info_area.add_child(bg)
	
	# Chapter title
	chapter_title = Label.new()
	chapter_title.text = "Chapter 1 - Tutorial"
	chapter_title.position = Vector2(540, 80)
	chapter_title.size = Vector2(400, 50)
	chapter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_title.add_theme_font_size_override("font_size", 32)
	chapter_title.add_theme_color_override("font_color", Color.WHITE)
	main_info_area.add_child(chapter_title)
	
	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(140, 150)
	progress_bar.size = Vector2(800, 30)
	progress_bar.value = 30  # 30% complete
	main_info_area.add_child(progress_bar)
	
	# Level detail panel
	level_detail_panel = Panel.new()
	level_detail_panel.position = Vector2(90, 250)
	level_detail_panel.size = Vector2(900, 500)
	main_info_area.add_child(level_detail_panel)
	
	var detail_label = Label.new()
	detail_label.text = "Select a level tile to see details"
	detail_label.position = Vector2(450, 250)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.add_theme_font_size_override("font_size", 24)
	level_detail_panel.add_child(detail_label)

func create_confirm_grid():
	# Middle area - 3x3 confirmation grid (240, 1000) - (840, 1600)
	unified_confirm_grid = Control.new()
	unified_confirm_grid.position = Vector2(240, 1000)
	unified_confirm_grid.size = Vector2(600, 600)
	add_child(unified_confirm_grid)
	
	# Background
	var grid_bg = ColorRect.new()
	grid_bg.size = Vector2(600, 600)
	grid_bg.color = Color(0.2, 0.2, 0.3, 1.0)
	unified_confirm_grid.add_child(grid_bg)
	
	# Create 3x3 grid with drop zones
	for i in range(3):
		for j in range(3):
			var drop_zone = DropZone.new()
			drop_zone.position = Vector2(j * 200, i * 200)
			drop_zone.size = Vector2(200, 200)
			drop_zone.set_accepted_types(["level"])
			unified_confirm_grid.add_child(drop_zone)
			
			# Highlight center tile
			if i == 1 and j == 1:
				drop_zone.modulate = Color(1.2, 1.2, 1.0, 1.0)
				# Connect center drop zone
				drop_zone.tile_dropped.connect(_on_level_tile_dropped)
	
	# Instruction label
	confirm_label = Label.new()
	confirm_label.text = "Drag level tile here to start"
	confirm_label.position = Vector2(300, 650)
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.add_theme_font_size_override("font_size", 20)
	confirm_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(confirm_label)

func create_level_tile_area():
	# Bottom area - Level tiles scroll area (0, 1600) - (1080, 1920)
	var bottom_bg = ColorRect.new()
	bottom_bg.position = Vector2(0, 1600)
	bottom_bg.size = Vector2(1080, 320)
	bottom_bg.color = Color(0.15, 0.15, 0.25, 1.0)
	add_child(bottom_bg)
	
	# Scroll container for level tiles
	level_tile_container = ScrollContainer.new()
	level_tile_container.position = Vector2(40, 1620)
	level_tile_container.size = Vector2(1000, 240)
	level_tile_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	level_tile_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(level_tile_container)
	
	# Container for tiles
	var tile_container = HBoxContainer.new()
	tile_container.add_theme_constant_override("separation", 20)
	level_tile_container.add_child(tile_container)
	
	# Back button
	back_button = Button.new()
	back_button.text = "Back"
	back_button.position = Vector2(80, 1860)
	back_button.size = Vector2(150, 60)
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

func load_chapter_levels():
	if not ResourceManager:
		print("ResourceManager not available")
		return
	
	available_levels = ResourceManager.get_all_level_ids()
	print("Loading levels: ", available_levels)
	
	# Create level tiles
	var tile_container = level_tile_container.get_child(0)
	for level_id in available_levels:
		var level_tile = LevelTile.create_from_level_id(current_chapter, level_id)
		if level_tile:
			tile_container.add_child(level_tile)
			# Connect tile selection signal  
			level_tile.gui_input.connect(_on_level_tile_input.bind(level_tile))


func _on_level_tile_input(event: InputEvent, tile: LevelTile):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_level_id = tile.level_data.get("id", "")
		update_level_details(tile.level_data)
		print("Selected level: ", selected_level_id)

func update_level_details(level_data: Dictionary):
	# Update the detail panel with level information
	var detail_text = "Level: " + level_data.get("id", "Unknown") + "\n"
	detail_text += "Difficulty: " + str(level_data.get("difficulty", 1)) + "\n"
	detail_text += "Enemies: " + str(level_data.get("enemies", []).size()) + "\n"
	
	var label = level_detail_panel.get_child(0)
	label.text = detail_text

func _on_level_tile_dropped(tile_data: Dictionary):
	print("Level tile dropped in center: ", tile_data)
	var level_id = tile_data.get("level_id", "")
	if level_id != "":
		start_level(level_id)

func start_level(level_id: String):
	print("Starting level: ", level_id)
	# Here would normally transition to battle scene
	# For test, just show message and return
	await get_tree().create_timer(2.0).timeout
	print("Level completed! Returning to main menu...")
	get_tree().change_scene_to_file("res://main.tscn")

func _on_back_pressed():
	print("Returning to main menu")
	get_tree().change_scene_to_file("res://main.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		_on_back_pressed()
