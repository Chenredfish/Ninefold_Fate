# LevelSelection.gd - 關卡選擇場景
# 使用拖放機制進行關卡選擇，不切換整個場景，而是在同一場景內切換UI面板
class_name LevelSelection
extends Control

# === 訊號 ===
signal level_selected(level_data: Dictionary)
signal back_to_main_menu

# === 節點引用 ===
var main_info_area: Control
var chapter_title: Label
var progress_bar: ProgressBar
var level_detail_panel: Panel
var unified_confirm_grid: Control
var options_area: Control
var level_tile_container: ScrollContainer
var back_button: Button

# === 狀態變數 ===
var current_chapter_index: int = 0
var all_level_ids: Array = []
var chapter_level_groups: Dictionary = {}  # 將關卡按章節分組
var selected_level_data: Dictionary = {}
var level_tiles: Array[LevelTile] = []

# === 模擬進度資料（實際遊戲中應該從存檔載入）===
var player_progress_data = {
	"level_001": {"status": "completed", "stars": 3},
	"level_002": {"status": "completed", "stars": 2}, 
	"level_003": {"status": "available", "stars": 0},
	# 其他關卡預設為鎖定狀態
}

func _ready():
	print("=== 關卡選擇場景初始化 ===")
	
	# 檢查ResourceManager
	if not ResourceManager:
		push_error("ResourceManager未找到！關卡選擇系統需要ResourceManager")
		return
	
	# 載入關卡資料
	load_levels_from_resource_manager()
	
	# 建立UI結構
	create_ui_structure()
	
	# 載入當前章節資料
	load_current_chapter_data()
	
	# 連接訊號
	connect_signals()
	
	print("✅ 關卡選擇場景已就緒")

# === UI 建構 ===

# 創建UI結構
func create_ui_structure():
	print("--- 建立關卡選擇UI ---")
	
	# 設置場景基本屬性
	size = Vector2(1080, 1920)
	
	# 創建背景
	create_background()
	
	# 創建上層主要資訊區
	create_main_info_area()
	
	# 創建中層統一確認區
	create_unified_confirm_grid()
	
	# 創建下層選項區
	create_options_area()

# 創建背景
func create_background():
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0.1, 0.1, 0.15, 1.0)  # 深藍色背景
	add_child(bg)

# 創建上層主要資訊區 (0, 0) - (1080, 1000)
func create_main_info_area():
	main_info_area = Control.new()
	main_info_area.name = "MainInfoArea"
	main_info_area.size = Vector2(1080, 1000)
	main_info_area.position = Vector2(0, 0)
	add_child(main_info_area)
	
	# 標題區
	create_title_section()
	
	# 章節進度區
	create_progress_section()
	
	# 關卡詳細資訊面板
	create_level_detail_panel()
	
	# 章節導航按鈕
	create_chapter_navigation()

# 創建標題區
func create_title_section():
	chapter_title = Label.new()
	chapter_title.name = "ChapterTitle"
	chapter_title.text = "第一章：火焰試煉"
	chapter_title.position = Vector2(540, 50)
	chapter_title.size = Vector2(500, 80)
	chapter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chapter_title.add_theme_font_size_override("font_size", 24)
	chapter_title.add_theme_color_override("font_color", Color.WHITE)
	main_info_area.add_child(chapter_title)

# 創建進度區
func create_progress_section():
	# 進度條背景
	var progress_bg = Panel.new()
	progress_bg.position = Vector2(240, 150)
	progress_bg.size = Vector2(600, 40)
	
	var progress_style = StyleBoxFlat.new()
	progress_style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	progress_style.corner_radius_top_left = 20
	progress_style.corner_radius_top_right = 20
	progress_style.corner_radius_bottom_left = 20
	progress_style.corner_radius_bottom_right = 20
	progress_bg.add_theme_stylebox_override("panel", progress_style)
	main_info_area.add_child(progress_bg)
	
	# 進度條
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.position = Vector2(260, 160)
	progress_bar.size = Vector2(560, 20)
	progress_bar.value = 40  # 測試值：40% 完成度
	progress_bar.max_value = 100
	main_info_area.add_child(progress_bar)
	
	# 進度文字
	var progress_label = Label.new()
	progress_label.text = "關卡進度: 2/5 完成"
	progress_label.position = Vector2(540, 200)
	progress_label.size = Vector2(300, 30)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", Color.YELLOW)
	main_info_area.add_child(progress_label)

# 創建關卡詳細資訊面板
func create_level_detail_panel():
	level_detail_panel = Panel.new()
	level_detail_panel.name = "LevelDetailPanel"
	level_detail_panel.position = Vector2(190, 280)
	level_detail_panel.size = Vector2(700, 400)
	
	# 面板樣式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.4, 0.4, 0.6, 1.0)
	level_detail_panel.add_theme_stylebox_override("panel", panel_style)
	main_info_area.add_child(level_detail_panel)
	
	# 預設內容
	create_default_level_info()

# 創建預設關卡資訊
func create_default_level_info():
	var default_label = Label.new()
	default_label.text = "請選擇一個關卡查看詳細資訊\n\n拖拽關卡圖塊到下方確認區域來開始遊戲"
	default_label.position = Vector2(50, 50)
	default_label.size = Vector2(600, 300)
	default_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	default_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	default_label.add_theme_font_size_override("font_size", 18)
	default_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	default_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_detail_panel.add_child(default_label)

# 創建章節導航
func create_chapter_navigation():
	# 上一章按鈕
	var prev_button = Button.new()
	prev_button.text = "◀ 上一章"
	prev_button.position = Vector2(50, 720)
	prev_button.size = Vector2(120, 60)
	prev_button.pressed.connect(_on_prev_chapter_pressed)
	main_info_area.add_child(prev_button)
	
	# 下一章按鈕
	var next_button = Button.new()
	next_button.text = "下一章 ▶"
	next_button.position = Vector2(910, 720)
	next_button.size = Vector2(120, 60)
	next_button.pressed.connect(_on_next_chapter_pressed)
	main_info_area.add_child(next_button)

# 創建中層統一確認區 (240, 1000) - (840, 1600)
func create_unified_confirm_grid():
	unified_confirm_grid = Control.new()
	unified_confirm_grid.name = "UnifiedConfirmGrid" 
	unified_confirm_grid.position = Vector2(240, 1000)
	unified_confirm_grid.size = Vector2(600, 600)
	add_child(unified_confirm_grid)
	
	# 創建3×3網格背景
	var grid_bg = Panel.new()
	grid_bg.size = Vector2(600, 600)
	
	var grid_style = StyleBoxFlat.new()
	grid_style.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	grid_style.corner_radius_top_left = 20
	grid_style.corner_radius_top_right = 20
	grid_style.corner_radius_bottom_left = 20
	grid_style.corner_radius_bottom_right = 20
	grid_style.border_width_left = 3
	grid_style.border_width_right = 3
	grid_style.border_width_top = 3
	grid_style.border_width_bottom = 3
	grid_style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	grid_bg.add_theme_stylebox_override("panel", grid_style)
	unified_confirm_grid.add_child(grid_bg)
	
	# 創建3×3網格容器
	var grid_container = GridContainer.new()
	grid_container.name = "GridContainer"
	grid_container.columns = 3
	grid_container.size = Vector2(600, 600)
	unified_confirm_grid.add_child(grid_container)
	
	# 添加9個格子
	for i in range(9):
		var cell = Panel.new()
		cell.custom_minimum_size = Vector2(200, 200)
		
		# 中央格子特殊樣式（確認區域）
		if i == 4:  # 中央格子
			var center_style = StyleBoxFlat.new()
			center_style.bg_color = Color(1.0, 0.8, 0.2, 0.3)  # 金色半透明
			center_style.border_width_left = 2
			center_style.border_width_right = 2
			center_style.border_width_top = 2
			center_style.border_width_bottom = 2
			center_style.border_color = Color.GOLD
			cell.add_theme_stylebox_override("panel", center_style)
			
			# 添加提示文字
			var hint_label = Label.new()
			hint_label.text = "拖放關卡\n到此處"
			hint_label.size = Vector2(200, 200)
			hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hint_label.add_theme_font_size_override("font_size", 16)
			hint_label.add_theme_color_override("font_color", Color.GOLD)
			hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(hint_label)
		else:
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color(0.2, 0.2, 0.2, 0.3)
			normal_style.border_width_left = 1
			normal_style.border_width_right = 1
			normal_style.border_width_top = 1
			normal_style.border_width_bottom = 1
			normal_style.border_color = Color(0.3, 0.3, 0.3, 1.0)
			cell.add_theme_stylebox_override("panel", normal_style)
		
		grid_container.add_child(cell)
	
	# 創建投放區域（DropZone）
	var drop_zone = DropZone.new()
	drop_zone.name = "LevelDropZone"
	drop_zone.size = Vector2(200, 200)
	drop_zone.position = Vector2(200, 200)  # 中央格子位置
	drop_zone.zone_type = "level_confirmation"
	drop_zone.set_accepted_types(["level"])
	drop_zone.tile_dropped.connect(_on_level_dropped)
	unified_confirm_grid.add_child(drop_zone)

# 創建下層選項區 (0, 1600) - (1080, 320)
func create_options_area():
	options_area = Control.new()
	options_area.name = "OptionsArea"
	options_area.position = Vector2(0, 1600)
	options_area.size = Vector2(1080, 320)
	add_child(options_area)
	
	# 創建背景
	var options_bg = ColorRect.new()
	options_bg.size = Vector2(1080, 320)
	options_bg.color = Color(0.15, 0.15, 0.2, 1.0)
	options_area.add_child(options_bg)
	
	# 創建關卡圖塊滾動容器
	create_level_scroll_container()
	
	# 創建返回按鈕
	create_back_button()

# 創建關卡圖塊滾動容器
func create_level_scroll_container():
	level_tile_container = ScrollContainer.new()
	level_tile_container.name = "LevelTileContainer"
	level_tile_container.position = Vector2(20, 20)
	level_tile_container.size = Vector2(1040, 220)
	level_tile_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	level_tile_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	options_area.add_child(level_tile_container)
	
	# 水平容器
	var h_container = HBoxContainer.new()
	h_container.name = "LevelHContainer"
	level_tile_container.add_child(h_container)

# 創建返回按鈕
func create_back_button():
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "返回主選單"
	back_button.position = Vector2(20, 250)
	back_button.size = Vector2(150, 50)
	back_button.pressed.connect(_on_back_button_pressed)
	options_area.add_child(back_button)

# === 資料載入 ===

# 從ResourceManager載入關卡資料
func load_levels_from_resource_manager():
	print("--- 從ResourceManager載入關卡資料 ---")
	
	# 獲取所有關卡ID
	all_level_ids = ResourceManager.get_all_level_ids()
	print("找到關卡數量：", all_level_ids.size())
	
	# 按章節分組（簡單的按ID前綴分組）
	chapter_level_groups = {}
	for level_id in all_level_ids:
		var chapter_key = get_chapter_key_from_level_id(level_id)
		if not chapter_level_groups.has(chapter_key):
			chapter_level_groups[chapter_key] = []
		chapter_level_groups[chapter_key].append(level_id)
	
	print("章節分組：", chapter_level_groups.keys())

# 從關卡ID提取章節信息
func get_chapter_key_from_level_id(level_id: String) -> String:
	# 假設格式是 "level_001", "level_002" 等
	# 我們根據編號分組（每5個關卡為一章）
	var level_num = level_id.replace("level_", "").to_int()
	var chapter_num = ((level_num - 1) / 5) + 1
	return "chapter_%02d" % chapter_num

# 獲取章節標題
func get_chapter_title(chapter_key: String) -> String:
	match chapter_key:
		"chapter_01":
			return "第一章：初始試煉"
		"chapter_02": 
			return "第二章：進階挑戰"
		"chapter_03":
			return "第三章：高級考驗"
		_:
			return "第%s章：未知領域" % chapter_key.replace("chapter_", "")

# 載入當前章節資料
func load_current_chapter_data():
	var chapter_keys = chapter_level_groups.keys()
	if chapter_keys.size() == 0:
		print("警告：沒有找到任何章節資料")
		return
	
	# 確保索引有效
	if current_chapter_index >= chapter_keys.size():
		current_chapter_index = 0
	
	var current_chapter_key = chapter_keys[current_chapter_index]
	print("--- 載入章節資料：", current_chapter_key, " ---")
	
	# 更新章節標題
	chapter_title.text = get_chapter_title(current_chapter_key)
	
	# 載入關卡圖塊
	load_level_tiles()
	
	# 更新進度條
	update_progress_display()

# 載入關卡圖塊
func load_level_tiles():
	# 清除現有圖塊
	clear_level_tiles()
	
	var chapter_keys = chapter_level_groups.keys()
	if current_chapter_index >= chapter_keys.size():
		return
		
	var current_chapter_key = chapter_keys[current_chapter_index]
	var level_ids_in_chapter = chapter_level_groups.get(current_chapter_key, [])
	
	var h_container = level_tile_container.get_node("LevelHContainer")
	
	# 創建新的關卡圖塊
	for level_id in level_ids_in_chapter:
		# 從ResourceManager獲取關卡資料
		var level_data = ResourceManager.get_level_data(level_id)
		if level_data.size() == 0:
			print("警告：無法載入關卡資料：", level_id)
			continue
		
		# 獲取玩家進度
		var progress = player_progress_data.get(level_id, {"status": "locked", "stars": 0})
		
		var tile: LevelTile
		match progress.status:
			"completed":
				tile = LevelTile.create_completed_level(current_chapter_key, level_id, progress.stars)
			"available":
				tile = LevelTile.create_available_level(current_chapter_key, level_id)
			_:  # "locked" 或其他
				tile = LevelTile.create_locked_level(current_chapter_key, level_id)
		
		# 使用ResourceManager的關卡資料
		tile.level_data = level_data.duplicate()
		
		# 添加到容器
		h_container.add_child(tile)
		level_tiles.append(tile)
		
		var level_name = level_data.get("name", {}).get("zh", level_id)
		print("✅ 創建關卡圖塊：", level_name, " 狀態：", progress.status)

# 清除關卡圖塊
func clear_level_tiles():
	var h_container = level_tile_container.get_node("LevelHContainer")
	for child in h_container.get_children():
		child.queue_free()
	level_tiles.clear()

# 更新進度顯示
func update_progress_display():
	var chapter_keys = chapter_level_groups.keys()
	if current_chapter_index >= chapter_keys.size():
		return
		
	var current_chapter_key = chapter_keys[current_chapter_index]
	var level_ids_in_chapter = chapter_level_groups.get(current_chapter_key, [])
	
	var total_levels = level_ids_in_chapter.size()
	var completed_levels = 0
	
	for level_id in level_ids_in_chapter:
		var progress = player_progress_data.get(level_id, {"status": "locked"})
		if progress.status == "completed":
			completed_levels += 1
	
	# 更新進度條
	if total_levels > 0:
		progress_bar.value = (float(completed_levels) / float(total_levels)) * 100
	
	# 更新進度文字
	var progress_label = main_info_area.get_node_or_null("ProgressLabel")
	if not progress_label:
		progress_label = Label.new()
		progress_label.name = "ProgressLabel"
		progress_label.position = Vector2(540, 200)
		progress_label.size = Vector2(300, 30)
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		progress_label.add_theme_font_size_override("font_size", 16)
		progress_label.add_theme_color_override("font_color", Color.YELLOW)
		main_info_area.add_child(progress_label)
	
	progress_label.text = "關卡進度: %d/%d 完成" % [completed_levels, total_levels]

# === 訊號連接 ===

func connect_signals():
	print("--- 連接關卡選擇訊號 ---")
	
	# 連接 DragDropManager 訊號（如果存在）
	if DragDropManager:
		if not DragDropManager.tile_drag_started.is_connected(_on_tile_drag_started):
			DragDropManager.tile_drag_started.connect(_on_tile_drag_started)
		if not DragDropManager.tile_drag_ended.is_connected(_on_tile_drag_ended):
			DragDropManager.tile_drag_ended.connect(_on_tile_drag_ended)
		print("✅ DragDropManager 訊號已連接")

# === 訊號處理 ===

func _on_tile_drag_started(tile_data: Dictionary, source_scene: String):
	if tile_data.get("type") == "level":
		print("[關卡選擇] 開始拖拽關卡：", tile_data.get("level_id", "unknown"))

func _on_tile_drag_ended(tile_data: Dictionary, drop_zone, success: bool):
	if tile_data.get("type") == "level":
		print("[關卡選擇] 拖拽結束：", tile_data.get("level_id", "unknown"), " 成功：", success)

func _on_level_dropped(tile_data: Dictionary):
	print("[關卡選擇] 關卡投放到確認區域：", tile_data)
	
	# 保存選中的關卡資料
	selected_level_data = tile_data
	
	# 更新關卡詳細資訊面板
	update_level_detail_panel(tile_data)
	
	# 顯示確認按鈕
	show_confirmation_buttons()

# 更新關卡詳細資訊面板
func update_level_detail_panel(tile_data: Dictionary):
	# 清除舊內容
	for child in level_detail_panel.get_children():
		child.queue_free()
	
	# 創建新的詳細資訊
	var info_container = VBoxContainer.new()
	info_container.position = Vector2(20, 20)
	info_container.size = Vector2(660, 360)
	level_detail_panel.add_child(info_container)
	
	var level_data = tile_data.get("level_data", {})
	
	# 關卡標題（支持多語言）
	var title_label = Label.new()
	var level_name = level_data.get("name", {})
	if level_name is Dictionary:
		title_label.text = level_name.get("zh", level_data.get("id", "未知關卡"))
	else:
		title_label.text = str(level_name)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(title_label)
	
	# 關卡描述（支持多語言）
	var desc_label = Label.new()
	var description = level_data.get("description", {})
	if description is Dictionary:
		desc_label.text = description.get("zh", "這是一個挑戰關卡")
	else:
		desc_label.text = str(description)
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(desc_label)
	
	# 難度與星級
	var status_label = Label.new()
	var status_text = "關卡ID: %s | 狀態: %s" % [
		level_data.get("id", "unknown"),
		tile_data.get("unlock_status", "unknown")
	]
	if tile_data.get("star_rating", 0) > 0:
		status_text += " | 星級: %d/3" % tile_data.get("star_rating", 0)
	status_label.text = status_text
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color.YELLOW)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(status_label)
	
	# 敵人資訊
	var enemies = level_data.get("enemies", [])
	if enemies.size() > 0:
		var enemy_label = Label.new()
		var enemy_names = []
		for enemy in enemies:
			enemy_names.append(enemy.get("id", "未知敵人"))
		enemy_label.text = "敵人: " + ", ".join(enemy_names)
		enemy_label.add_theme_font_size_override("font_size", 14)
		enemy_label.add_theme_color_override("font_color", Color.ORANGE_RED)
		enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_container.add_child(enemy_label)
	
	# 英雄資訊
	var hero_id = level_data.get("hero_id", "")
	if hero_id != "":
		var hero_label = Label.new()
		hero_label.text = "推薦英雄: " + hero_id
		hero_label.add_theme_font_size_override("font_size", 14)
		hero_label.add_theme_color_override("font_color", Color.CYAN)
		hero_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_container.add_child(hero_label)
	
	# 獎勵資訊
	var rewards = level_data.get("rewards", [])
	if rewards.size() > 0:
		var reward_label = Label.new()
		reward_label.text = "獎勵: " + str(rewards.size()) + " 項獎品"
		reward_label.add_theme_font_size_override("font_size", 14)
		reward_label.add_theme_color_override("font_color", Color.GREEN)
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_container.add_child(reward_label)

# 顯示確認按鈕
func show_confirmation_buttons():
	# 移除舊按鈕
	var old_confirm = unified_confirm_grid.get_node_or_null("ConfirmButton")
	var old_cancel = unified_confirm_grid.get_node_or_null("CancelButton")
	if old_confirm:
		old_confirm.queue_free()
	if old_cancel:
		old_cancel.queue_free()
	
	# 創建確認按鈕
	var confirm_button = Button.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.text = "開始遊戲"
	confirm_button.position = Vector2(150, 620)
	confirm_button.size = Vector2(180, 60)
	confirm_button.pressed.connect(_on_confirm_level_pressed)
	unified_confirm_grid.add_child(confirm_button)
	
	# 創建取消按鈕
	var cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.text = "取消"
	cancel_button.position = Vector2(360, 620)
	cancel_button.size = Vector2(120, 60)
	cancel_button.pressed.connect(_on_cancel_level_pressed)
	unified_confirm_grid.add_child(cancel_button)

# === 按鈕事件 ===

func _on_prev_chapter_pressed():
	if current_chapter_index > 0:
		current_chapter_index -= 1
		load_current_chapter_data()
		print("[關卡選擇] 切換到上一章，索引：", current_chapter_index)

func _on_next_chapter_pressed():
	var chapter_keys = chapter_level_groups.keys()
	if current_chapter_index < chapter_keys.size() - 1:
		current_chapter_index += 1
		load_current_chapter_data()
		print("[關卡選擇] 切換到下一章，索引：", current_chapter_index)

func _on_back_button_pressed():
	print("[關卡選擇] 返回主選單")
	back_to_main_menu.emit()

func _on_confirm_level_pressed():
	if selected_level_data.size() > 0:
		print("[關卡選擇] 確認開始關卡：", selected_level_data.get("level_id"))
		level_selected.emit(selected_level_data)
	else:
		print("[關卡選擇] 錯誤：沒有選中的關卡")

func _on_cancel_level_pressed():
	print("[關卡選擇] 取消關卡選擇")
	selected_level_data = {}
	
	# 清除確認按鈕
	var confirm_button = unified_confirm_grid.get_node_or_null("ConfirmButton")
	var cancel_button = unified_confirm_grid.get_node_or_null("CancelButton")
	if confirm_button:
		confirm_button.queue_free()
	if cancel_button:
		cancel_button.queue_free()
	
	# 恢復預設資訊面板
	for child in level_detail_panel.get_children():
		child.queue_free()
	create_default_level_info()

# === 輸入處理 ===

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC
		_on_back_button_pressed()

# === 公開介面 ===

# 設置章節（通過索引）
func set_chapter_index(index: int):
	var chapter_keys = chapter_level_groups.keys()
	if index >= 0 and index < chapter_keys.size():
		current_chapter_index = index
		load_current_chapter_data()

# 獲取當前章節Key
func get_current_chapter() -> String:
	var chapter_keys = chapter_level_groups.keys()
	if current_chapter_index < chapter_keys.size():
		return chapter_keys[current_chapter_index]
	return ""

# 獲取選中的關卡資料
func get_selected_level() -> Dictionary:
	return selected_level_data