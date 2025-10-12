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
	tile.unlock_status = "available"
	if title != "":
		# 如果提供了標題，覆蓋原有標題
		if tile.level_data.has("name") and tile.level_data["name"] is Dictionary:
			tile.level_data["name"]["zh"] = title
		else:
			tile.level_data["name"] = {"zh": title}
	return tile

# 創建已完成關卡
static func create_completed_level(chapter: String, level_id: String, stars: int = 3) -> LevelTile:
	var tile = create_from_level_id(chapter, level_id)
	tile.unlock_status = "completed"
	tile.star_rating = stars
	return tile

# 創建鎖定關卡
static func create_locked_level(chapter: String, level_id: String) -> LevelTile:
	var tile = create_from_level_id(chapter, level_id)
	tile.unlock_status = "locked"
	return tile

func _ready():
	# 設置基本屬性
	tile_type = "level"
	
	# 調用父類初始化
	super._ready()
	
	# 設置關卡圖塊的特殊樣式
	setup_level_tile_style()

# === 樣式設定 ===

# 設置關卡圖塊樣式
func setup_level_tile_style():
	var style_box = StyleBoxFlat.new()
	
	# 根據解鎖狀態設定顏色
	match unlock_status:
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
	match difficulty:
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
	
	# 上層：關卡編號和難度指示器
	var top_row = HBoxContainer.new()
	top_row.custom_minimum_size = Vector2(0, 40)
	main_container.add_child(top_row)
	
	# 關卡編號
	level_number_label = Label.new()
	level_number_label.text = level_id.replace("level", "").replace("_", "-")
	level_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_number_label.add_theme_font_size_override("font_size", 16)
	level_number_label.add_theme_color_override("font_color", Color.WHITE)
	level_number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(level_number_label)
	
	# 彈性分隔符
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	
	# 難度指示器
	difficulty_indicator = ColorRect.new()
	difficulty_indicator.custom_minimum_size = Vector2(20, 20)
	difficulty_indicator.color = get_difficulty_color()
	top_row.add_child(difficulty_indicator)
	
	# 中層：關卡圖示或鎖定圖示
	var middle_section = CenterContainer.new()
	middle_section.custom_minimum_size = Vector2(0, 80)
	main_container.add_child(middle_section)
	
	if unlock_status == "locked":
		# 鎖定圖示
		lock_icon = TextureRect.new()
		# 這裡可以設定鎖定圖示，目前用文字代替
		var lock_label = Label.new()
		lock_label.text = "🔒"
		lock_label.add_theme_font_size_override("font_size", 32)
		lock_label.add_theme_color_override("font_color", Color.GRAY)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		middle_section.add_child(lock_label)
	else:
		# 關卡圖示（可以根據敵人類型等設定）
		level_icon = TextureRect.new()
		# 這裡可以設定關卡圖示，目前用文字代替
		var icon_label = Label.new()
		icon_label.text = get_level_icon()
		icon_label.add_theme_font_size_override("font_size", 32)
		icon_label.add_theme_color_override("font_color", Color.WHITE)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		middle_section.add_child(icon_label)
	
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
	level_title_label.add_theme_font_size_override("font_size", 12)
	level_title_label.add_theme_color_override("font_color", Color.WHITE)
	level_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_section.add_child(level_title_label)
	
	# 星級顯示（僅已完成關卡）
	if unlock_status == "completed":
		star_container = HBoxContainer.new()
		star_container.alignment = BoxContainer.ALIGNMENT_CENTER
		star_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		for i in range(3):
			var star_label = Label.new()
			if i < star_rating:
				star_label.text = "⭐"
				star_label.add_theme_color_override("font_color", Color.GOLD)
			else:
				star_label.text = "☆"
				star_label.add_theme_color_override("font_color", Color.GRAY)
			star_label.add_theme_font_size_override("font_size", 14)
			star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			star_container.add_child(star_label)
		
		bottom_section.add_child(star_container)

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

# 獲取關卡圖示
func get_level_icon() -> String:
	# 根據敵人類型或關卡特性返回對應圖示
	var enemies = level_data.get("enemies", [])
	if enemies.size() > 0:
		match enemies[0]:
			"goblin":
				return "👹"
			"orc":
				return "👺"
			"dragon":
				return "🐲"
			_:
				return "⚔️"
	return "⚔️"

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