# LevelTile.gd - 關卡選擇圖塊
# 用於關卡選擇的特化圖塊，類似導航圖塊但不切換整個場景
class_name LevelTile
extends DraggableTile

# === 導出屬性 ===
@export var level_id: String = ""  # 關卡ID
@export var chapter_id: String = ""  # 章節ID
@export var level_data: Dictionary = {}  # 關卡資料
@export var unlock_status: String = "locked"  # "locked", "available", "completed"
@export var star_rating: int = 0  # 星級評價 (0-3)
@export var difficulty: String = "normal"  # "normal", "hard", "hell"
@export var enemies: Array = []  # 關卡中的敵人列表

# === 內部節點 ===
var level_icon: TextureRect
var level_number_label: Label
var level_title_label: Label
var star_container: HBoxContainer
var lock_icon: TextureRect
var difficulty_indicator: ColorRect

# === 靜態創建方法 ===

# 從關卡ID創建
static func create_from_level_id(chapter: String, level_id: String) -> LevelTile:
	var tile = LevelTile.new()
	tile.chapter_id = chapter
	tile.level_id = level_id
	tile.tile_type = "level"
	tile.size = Vector2(200, 200)
	
	
	# 從 ResourceManager 載入關卡資料（如果可用）
	if ResourceManager:
		tile.level_data = ResourceManager.get_level_data(level_id)
	else:
		# 預設測試資料
		tile.level_data = {
			"id": level_id,
			"name": {"zh": "測試關卡 " + level_id},
			"description": {"zh": "這是一個測試關卡"},
			"enemies": [{"id": "E001"}],
			"rewards": []
		}
	return tile

# 創建可用關卡
static func create_available_level(chapter: String, level_id: String, title: String = "") -> LevelTile:
	var tile = create_from_level_id(chapter, level_id)

	if title != "":
		# 如果提供了標題，覆蓋原有標題
		if tile.level_data.has("name") and tile.level_data["name"] is Dictionary:
			tile.level_data["name"]["zh"] = title
		else:
			tile.level_data["name"] = {"zh": title}
	return tile


func _ready():
	# 設置基本屬性
	tile_type = "level"
	
	# 調用父類初始化
	super._ready()
	
	#資料取出
	setup_self_data()

	# 設置關卡圖塊的特殊樣式
	setup_level_tile_style()

# === 樣式設定 ===

# 設置關卡圖塊樣式
func setup_level_tile_style():
	var style_box = StyleBoxFlat.new()
	
	print("[LevelTile] 設置樣式，關卡ID：", level_id, " 解鎖狀態：", unlock_status, " 難度：", difficulty)
	# 根據解鎖狀態設定顏色
	match self.level_data.get("unlock_status", "locked"):
		"locked":
			style_box.bg_color = Color(0.3, 0.3, 0.3, 0.8)      # 灰色 - 鎖定
		"available":
			style_box.bg_color = Color(0.2, 0.6, 1.0, 0.9)      # 藍色 - 可挑戰
		"completed":
			style_box.bg_color = Color(0.2, 0.8, 0.2, 0.9)      # 綠色 - 已完成
		_:
			style_box.bg_color = Color(0.5, 0.5, 0.5, 0.8)      # 預設灰色
	
	# 根據難度調整邊框
	var border_width = 2
	var border_color = Color.WHITE
	match self.level_data.get("difficulty", "normal"):
		"normal":
			border_width = 2
			border_color = Color.WHITE
		"hard":
			border_width = 3
			border_color = Color.ORANGE
		"hell":
			border_width = 4
			border_color = Color.RED
	
	# 圓角設定
	style_box.corner_radius_top_left = 20
	style_box.corner_radius_top_right = 20
	style_box.corner_radius_bottom_left = 20
	style_box.corner_radius_bottom_right = 20
	
	# 邊框設定
	style_box.border_width_left = border_width
	style_box.border_width_right = border_width
	style_box.border_width_top = border_width
	style_box.border_width_bottom = border_width
	style_box.border_color = border_color
	
	add_theme_stylebox_override("panel", style_box)
	
	# 創建內容佈局
	create_level_content()

# 創建關卡圖塊內容
func create_level_content():
	# 清除舊內容
	for child in get_children():
		if child.name != "DragPreview":  # 保留拖拽預覽
			child.queue_free()
	
	# 創建主容器
	var main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.size = size
	main_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_container)
	
	# 上層：關卡編號和難度文字
	var top_row = HBoxContainer.new()
	top_row.custom_minimum_size = Vector2(0, 30)
	main_container.add_child(top_row)
	
	# 關卡編號
	level_number_label = Label.new()
	level_number_label.text = "Lv." + level_id.replace("level_", "").replace("_", "-")
	level_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	level_number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_number_label.add_theme_font_size_override("font_size", 14)
	level_number_label.add_theme_color_override("font_color", Color.WHITE)
	level_number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(level_number_label)
	
	# 彈性分隔符
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	
	# 難度文字標籤
	var difficulty_label = Label.new()
	difficulty_label.text = get_difficulty_text()
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	difficulty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	difficulty_label.add_theme_font_size_override("font_size", 12)
	difficulty_label.add_theme_color_override("font_color", get_difficulty_color())
	difficulty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(difficulty_label)
	
	# 中層：狀態和元素類型
	var middle_section = VBoxContainer.new()
	middle_section.custom_minimum_size = Vector2(0, 90)
	main_container.add_child(middle_section)
	
	# 狀態標籤
	var status_label = Label.new()
	status_label.text = get_status_text()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", get_status_color())
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle_section.add_child(status_label)
	
	# 元素類型標籤 (如果不是鎖定狀態)
	if unlock_status != "locked":
		var element_label = Label.new()
		element_label.text = get_element_text()
		element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		element_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		element_label.add_theme_font_size_override("font_size", 14)
		element_label.add_theme_color_override("font_color", get_element_color())
		element_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		middle_section.add_child(element_label)
	
	# 下層：關卡標題和星級
	var bottom_section = VBoxContainer.new()
	bottom_section.custom_minimum_size = Vector2(0, 60)
	main_container.add_child(bottom_section)
	
	# 關卡標題
	level_title_label = Label.new()
	var level_name = level_data.get("name", "未知關卡")
	if level_name is Dictionary:
		level_title_label.text = level_name.get("zh", level_data.get("id", "未知關卡"))
	else:
		level_title_label.text = str(level_name)
	level_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_title_label.add_theme_font_size_override("font_size", 14)
	level_title_label.add_theme_color_override("font_color", Color.WHITE)
	level_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_section.add_child(level_title_label)
	
	# 星級顯示（僅已完成關卡）- 使用文字
	if unlock_status == "completed":
		var star_label = Label.new()
		star_label.text = get_star_text()
		star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star_label.add_theme_font_size_override("font_size", 12)
		star_label.add_theme_color_override("font_color", Color.GOLD)
		star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bottom_section.add_child(star_label)

# === 輔助方法 ===

# 獲取難度顏色
func get_difficulty_color() -> Color:
	match difficulty:
		"normal":
			return Color.GREEN
		"hard":
			return Color.ORANGE
		"hell":
			return Color.RED
		_:
			return Color.WHITE
# === 拖拽數據覆寫 ===

# 覆寫獲取圖塊資料
func get_tile_data() -> Dictionary:
	var base_data = super.get_tile_data()
	
	# 添加關卡特定數據
	base_data["level_id"] = level_id
	base_data["chapter_id"] = chapter_id
	base_data["unlock_status"] = unlock_status
	base_data["star_rating"] = star_rating
	base_data["difficulty"] = difficulty
	base_data["level_data"] = level_data
	
	return base_data

# === 互動限制 ===

# 覆寫拖拽開始檢查
func can_start_drag() -> bool:
	# 只有可用和已完成的關卡才能拖拽
	return unlock_status in ["available", "completed"]

# === 除錯資訊 ===

func get_debug_info() -> Dictionary:
	var base_data = super.get_debug_info()
	base_data["level_id"] = level_id
	base_data["chapter_id"] = chapter_id
	base_data["unlock_status"] = unlock_status
	base_data["star_rating"] = star_rating
	base_data["difficulty"] = difficulty
	return base_data

# === 文字顯示輔助方法 ===

# 獲取難度文字
func get_difficulty_text() -> String:
	match difficulty:
		"normal":
			return "普通"
		"hard":
			return "困難"
		"hell":
			return "地獄"
		_:
			return "?"

# 獲取狀態文字
func get_status_text() -> String:
	match unlock_status:
		"locked":
			return "[鎖定]"
		"available":
			return "[可挑戰]"
		"completed":
			return "[已完成]"
		_:
			return ""

# 獲取狀態顏色
func get_status_color() -> Color:
	match unlock_status:
		"locked":
			return Color.GRAY
		"available":
			return Color.CYAN
		"completed":
			return Color.LIME_GREEN
		_:
			return Color.WHITE

# 獲取元素文字
func get_element_text() -> String:
	enemies = level_data.get("enemies", [])
	if enemies.size() > 0:
		var enemy_info = enemies[0]
		var enemy_id = ""
		
		# 處理兩種格式:純字串或字典
		if enemy_info is String:
			enemy_id = enemy_info
		elif enemy_info is Dictionary:
			enemy_id = enemy_info.get("id", "")
			if enemy_id == "":
				enemy_id = enemy_info.get("enemy_id", "")
		
		if enemy_id != "" and ResourceManager:
			var enemy_data = ResourceManager.get_enemy_data(enemy_id)
			if enemy_data.size() > 0:
				var element = enemy_data.get("element", "")
				print("[LevelTile] 敵人ID：", enemy_id, " 元素：", element)
				return get_element_display_name(element)
	return "無"

# 獲取元素顏色
func get_element_color() -> Color:
	if enemies.size() > 0:
		var enemy_info = enemies[0]
		var enemy_id = ""
		
		# 處理兩種格式:純字串或字典
		if enemy_info is String:
			enemy_id = enemy_info
		elif enemy_info is Dictionary:
			enemy_id = enemy_info.get("id", "")
			if enemy_id == "":
				enemy_id = enemy_info.get("enemy_id", "")
		
		if enemy_id != "" and ResourceManager:
			var enemy_data = ResourceManager.get_enemy_data(enemy_id)
			if enemy_data.size() > 0:
				var element = enemy_data.get("element", "")
				return get_element_display_color(element)
	return Color.WHITE

# 獲取元素顯示名稱
func get_element_display_name(element: String) -> String:
	match element:
		"water":
			return "水"
		"fire":
			return "火"
		"earth":
			return "地"
		"wind":
			return "風"
		"light":
			return "光"
		"dark":
			return "闇"
		_:
			return "無"

# 獲取元素顯示顏色
func get_element_display_color(element: String) -> Color:
	match element:
		"water":
			return Color.DODGER_BLUE
		"fire":
			return Color.ORANGE_RED
		"earth":
			return Color.SANDY_BROWN
		"wind":
			return Color.LIGHT_GREEN
		"light":
			return Color.GOLD
		"dark":
			return Color.PURPLE
		_:
			return Color.WHITE

# 獲取星級文字
func get_star_text() -> String:
	return "★ " + str(star_rating) + " / 3"

func setup_self_data():
	if level_data.has("unlock_status"):
		unlock_status = level_data["unlock_status"]
	else:
		print("[LevelTile] 警告：關卡資料缺少 unlock_status 欄位，使用預設值 'locked'")
	
	if level_data.has("difficulty"):
		difficulty = level_data["difficulty"]
	else:
		print("[LevelTile] 警告：關卡資料缺少 difficulty 欄位，使用預設值 'normal'")

	if level_data.has("star_rating"):
		star_rating = level_data["star_rating"]
	else:
		print("[LevelTile] 警告：關卡資料缺少 star_rating 欄位，使用預設值 0")
	
