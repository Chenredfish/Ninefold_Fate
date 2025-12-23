extends Control

# 主要UI區域
var main_info_area: Control
var chapter_title: Label
var progress_bar: ProgressBar
var level_detail_panel: Panel
var unified_confirm_grid: Control
var level_tile_container: ScrollContainer
var level_tile_scrolll: HScrollBar
var back_button: Button
var confirm_label: Label

# 數據變數
var current_chapter: String = "chapter1"
var available_levels: Array = []
var selected_level_id: String = ""

func _ready():
	print("[LevelSelection] 載入關卡選擇場景，主節點：", self, " parent：", get_parent())
	setup_ui()
	load_chapter_levels()

func setup_ui():
	#設置為全屏控制
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 先初始化 main_info_area 並加到場景
	main_info_area = Control.new()
	main_info_area.size = Vector2(1080, 1000)
	main_info_area.position = Vector2(0, 0)
	add_child(main_info_area)

	#創造三層結構遵循UI規範
	create_background_area()
	create_main_info_area()
	create_confirm_grid()
	create_level_tile_area()

func create_background_area():
	#背景
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1000)
	bg.color = Color(0.1, 0.1, 0.2, 1.0)
	main_info_area.add_child(bg)

func create_main_info_area():
	# 在已存在的 main_info_area 中添加UI元素
	
	#章節標題
	chapter_title = Label.new()
	chapter_title.text = "Chapter 1 - Tutorial"
	chapter_title.position = Vector2(540, 80)
	chapter_title.size = Vector2(400, 50)
	chapter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_title.add_theme_font_size_override("font_size", 32)
	chapter_title.add_theme_color_override("font_color", Color.WHITE)
	main_info_area.add_child(chapter_title)

	#進度條
	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(140, 150)
	progress_bar.size = Vector2(800, 30)
	progress_bar.value = 30  # 30% complete
	main_info_area.add_child(progress_bar)

	#等級詳情面板
	level_detail_panel = Panel.new()
	level_detail_panel.position = Vector2(90, 250)
	level_detail_panel.size = Vector2(900, 500)
	main_info_area.add_child(level_detail_panel)

	var detail_label = Label.new()
	detail_label.text = "Select a level to see details."
	detail_label.position = Vector2(450, 250)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.add_theme_font_size_override("font_size", 24)
	level_detail_panel.add_child(detail_label)

func create_confirm_grid():
	unified_confirm_grid = Control.new()
	unified_confirm_grid.position = Vector2(240, 1000)
	unified_confirm_grid.size = Vector2(600, 600)
	add_child(unified_confirm_grid)

	#九宮個自己的背景
	var grid_bg = ColorRect.new()
	grid_bg.size = Vector2(600, 600)
	grid_bg.color = Color(0.2, 0.2, 0.3, 1.0)
	unified_confirm_grid.add_child(grid_bg)

	for i in range(3):
		for j in range(3):
			var drop_zone = DropZone.new()
			drop_zone.position = Vector2(i * 200, j * 200)
			drop_zone.size = Vector2(200, 200)
			drop_zone.set_accepted_types(["level"])
			unified_confirm_grid.add_child(drop_zone)

			if i==1 and j==1:
				drop_zone.modulate = Color(1.2, 1.2, 1.0, 1.0)
				drop_zone.tile_dropped.connect(_on_level_tile_dropped)

	confirm_label = Label.new()
	confirm_label.text = "Drag level tile here to choose level"
	confirm_label.position = Vector2(300, 650)
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.add_theme_font_size_override("font_size", 20)
	confirm_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(confirm_label)

func create_level_tile_area():
	var bottom_bg = ColorRect.new()
	bottom_bg.position = Vector2(0, 1600)
	bottom_bg.size = Vector2(1080, 320)
	bottom_bg.color = Color(0.15, 0.15, 0.25, 1.0)
	add_child(bottom_bg)

	level_tile_container = ScrollContainer.new()
	level_tile_container.position = Vector2(40, 1620)
	level_tile_container.size = Vector2(1000, 240)
	level_tile_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	level_tile_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(level_tile_container)

	var tile_container = HBoxContainer.new()
	tile_container.add_theme_constant_override("separation", 20)
	level_tile_container.add_child(tile_container)

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
	print("[LevelSelection] Starting level: ", level_id)
	# 通過EventBus發送開始戰鬥請求
	EventBus.emit_signal("level_selected", level_id)

func _on_back_pressed():
	print("[LevelSelection] Back button pressed")
	# 返回主菜單
	EventBus.emit_signal("scene_transition_requested", "main_menu", {})
