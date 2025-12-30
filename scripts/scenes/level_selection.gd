extends Control

# 主要UI區域
var main_info_area: Control
var chapter_title: Label
var progress_bar: ProgressBar
var level_detail_panel: Panel
var unified_confirm_grid: Control
var level_tile_container: ScrollContainer
var level_control_tile_container: ScrollContainer
var level_tile_scrolll: HScrollBar
var back_button: Button
var confirm_label: Label

# 數據變數
var current_chapter: String = "chapter1"
var available_levels: Array = []
var selected_level_id: String = ""
#備註:最上層的上一頁就是回到主選單，所以deep0是主選單
var chapter_tree: Dictionary = {
	"deep0": "main_menu",
} #紀錄目前的分枝處在哪裡，其中紀錄所有歷史選擇的關卡ID
#每一次進入到下一層關卡選擇時，都會加入一個新的deepX節點，紀錄上一層的關卡ID

#三個關卡操控的tile
var back_level_tile: NavigationTile
var main_menu_tile: NavigationTile
var confirm_level_control_tile: NavigationTile

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
	bg.size = Vector2(1080, 1920)
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
	"""
	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(140, 150)
	progress_bar.size = Vector2(800, 30)
	progress_bar.value = 30  # 30% complete
	main_info_area.add_child(progress_bar)
	"""

	#等級詳情面板
	level_detail_panel = Panel.new()
	level_detail_panel.position = Vector2(90, 250)
	level_detail_panel.size = Vector2(900, 500)
	main_info_area.add_child(level_detail_panel)

	var detail_label = Label.new()
	detail_label.text = "Select a level to see details."
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_label.scale = Vector2(2, 2)
	detail_label.add_theme_font_size_override("font_size", 24)
	level_detail_panel.add_child(detail_label)

func create_confirm_grid():
	unified_confirm_grid = Control.new()
	unified_confirm_grid.position = Vector2(240, 800)
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
			drop_zone.set_accepted_types(["level", "back_level", "main_menu", "confirm_level"])
			unified_confirm_grid.add_child(drop_zone)

			drop_zone.modulate = Color(1.2, 1.2, 1.0, 1.0)
			drop_zone.tile_dropped.connect(_on_tile_dropped)


func create_level_tile_area():
	"""
	var bottom_bg = ColorRect.new()
	bottom_bg.position = Vector2(0, 1600)
	bottom_bg.size = Vector2(1080, 320)
	bottom_bg.color = Color(0.15, 0.15, 0.25, 1.0)
	add_child(bottom_bg)
	"""

	# 關卡選擇的容器
	level_tile_container = ScrollContainer.new()
	level_tile_container.position = Vector2(40, 1420)
	level_tile_container.size = Vector2(1000, 240)
	level_tile_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	level_tile_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(level_tile_container)

	var tile_container = HBoxContainer.new()
	tile_container.add_theme_constant_override("separation", 20)
	level_tile_container.add_child(tile_container)

	# 關卡操作的選項的容器
	level_control_tile_container = ScrollContainer.new()
	level_control_tile_container.position = Vector2(40, 1660)
	level_control_tile_container.size = Vector2(1000, 240)
	level_control_tile_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	level_control_tile_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(level_control_tile_container)

	var control_tile_container = HBoxContainer.new()
	control_tile_container.add_theme_constant_override("separation", 20)
	level_control_tile_container.add_child(control_tile_container)

	#目前三個功能，上一頁(關卡選擇可能有多層)，主選單，確認
	#按下確認才會進入選擇的關卡或是下一層

	back_level_tile = NavigationTile.create_back_tile(chapter_tree)
	back_level_tile.size = Vector2(200, 200)
	back_level_tile.position = Vector2(0, 0)
	control_tile_container.add_child(back_level_tile)

	main_menu_tile = NavigationTile.create_main_menu_tile("res://scripts/scenes/main_menu.tscn")
	main_menu_tile.size = Vector2(200, 200)
	main_menu_tile.position = Vector2(500, 0)
	control_tile_container.add_child(main_menu_tile)

	confirm_level_control_tile = NavigationTile.create_confirm_tile()
	confirm_level_control_tile.size = Vector2(200, 200)
	confirm_level_control_tile.position = Vector2(700, 0)
	control_tile_container.add_child(confirm_level_control_tile)


	"""
	back_button = Button.new()
	back_button.text = "Back"
	back_button.position = Vector2(80, 1860)
	back_button.size = Vector2(150, 60)
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)
	"""

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
	#如果關卡鎖住(locked)就不顯示細節
	if level_data.get("unlock_status", "locked") == "locked":
		level_detail_panel.get_child(0).text = "關卡尚未解鎖。"
		return

	var detail_text = "關卡ID: " + level_data.get("id", "未知") + "\n"
	detail_text += "難度: " + str(level_data.get("difficulty", 1)) + "\n"
	detail_text += "敵人數量: " + str(level_data.get("enemies", []).size()) + "\n"
	#取得敵人ID列表，把他逐個對應的名字列出來
	var enemies_data = level_data.get("enemies")
	for enemy in enemies_data:
		var enemy_id = enemy.get("enemy_id", "")
		var enemy_info = ResourceManager.get_enemy_data(enemy_id)
		var enemy_name = enemy_info.get("name", "缺少名稱").get("zh", "找不到中文名稱")
		var enemy_element = enemy_info.get("element", "缺少屬性")
		detail_text += "敵人: " + str(enemy_name) + " (" + str(enemy_element) + ")\n"

	#如果是通過關卡就顯示星級評價
	if level_data.get("unlock_status", "locked") == "completed":
		detail_text += "星級評價: " + str(level_data.get("star_rating", 0)) + " 星\n"
	
	var label = level_detail_panel.get_child(0)
	label.text = detail_text

func _on_tile_dropped(tile_data: Dictionary):
	print("Level tile dropped in center: ", tile_data)
	#因為目前沒有d有深度的關卡，所以只實作接收到關卡，剩下的功能留待未來擴展
	match  tile_data.get("function", ""):
		"back_level":
			_on_back_tile_dropped()
		"main_menu":
			_on_main_menu_tile_dropped()
		"confirm_level":
			_on_confirm_level_tile_dropped()
		_: #因為關卡tile沒有特別的function欄位，所以預設就是關卡
			#這裡因為tile_data裡面只有tile這個物件，所以需要從tile物件裡面取得level_id
			var level_id = tile_data.get("__tile_instance").level_data.get("id", "")
			if level_id != "":
				start_level(level_id)
			else:
				print("[LevelSelection] 錯誤：投放的tile缺少 level_id 資料")

func start_level(level_id: String):
	print("[LevelSelection] Starting level: ", level_id)
	# 需要修改導航資料讓確認關卡tile知道要進入哪個關卡
	# 第一個資料是戰鬥要載入的場景路徑，第二個是功能名稱(改動狀態需要)，第三個是導航資料
	confirm_level_control_tile.set_navigation_data("res://scripts/scenes/battle.tscn", "confirm_level", {"level_id": level_id})
	print("[LevelSelection] 已更新確認關卡tile的導航資料：", confirm_level_control_tile.navigation_data)
	#EventBus.emit_signal("level_selected", level_id)

#因為目前沒有多層關卡選擇，所以這個功能先留著未來擴展
func _on_back_tile_dropped():
	print("[LevelSelection] 偵測到上一頁的tile被投放")
	pass

func _on_main_menu_tile_dropped():
	print("[LevelSelection] 偵測到主選單的tile被投放")
	# 返回主菜單
	#await main_menu_tile.drag_ended
	#EventBus.emit_signal("scene_transition_requested", "main_menu", {})

func _on_confirm_level_tile_dropped():
	print("[LevelSelection] 偵測到確認關卡的tile被投放")
	#因為NavigtionTile的確認關卡tile會進入戰鬥狀態，所以這邊不需要特別處理a
	#但是需要在關卡放入後，修改導航資料讓它知道要進入哪個關卡
	pass
