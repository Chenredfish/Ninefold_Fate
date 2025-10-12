# BattleTile.gd - 戰鬥方塊
# 用於戰鬥場景的屬性方塊，基於 blocks.json 數據創建
class_name BattleTile
extends DraggableTile

# === 導出屬性 ===
@export var block_id: String = ""  # 方塊ID（如 "B001"）
@export var element: String = ""    # 屬性（火、水、草、光、暗）
@export var bonus_value: int = 1    # 加成值
@export var rarity: String = "common"  # 稀有度
@export var block_name: Dictionary = {}  # 多語言名稱 {"zh": "火焰方塊", "en": "Fire Block"}
@export var shape: String = "single"     # 方塊形狀
@export var shape_pattern: Array = []    # 形狀模式
@export var rotation_allowed: bool = false  # 是否可旋轉
@export var flip_allowed: bool = false      # 是否可翻轉
@export var icon_path: String = ""          # 圖標路徑

# === 內部節點 ===
var background_rect: ColorRect
var icon_node: TextureRect
var element_label: Label
var bonus_label: Label

func _ready():
	# 設置基本屬性
	tile_type = "battle_block"  # 戰鬥方塊，區別於導航中的 "battle"
	
	# 調用父類初始化
	super._ready()
	
	# 設置戰鬥方塊的特殊樣式
	setup_battle_tile_style()

# === 工廠方法 ===

# 從 ResourceManager 創建戰鬥方塊
static func create_from_block_data(block_id: String) -> BattleTile:
	var tile = BattleTile.new()
	tile.setup_from_resource_manager(block_id)
	return tile

# === 資源管理器集成 ===

# 從 ResourceManager 設置方塊數據
func setup_from_resource_manager(block_id_param: String):
	block_id = block_id_param
	
	# 從 ResourceManager 獲取方塊數據
	var block_data = ResourceManager.block_database.get(block_id)
	if not block_data:
		push_warning("[BattleTile] 找不到方塊數據：" + block_id)
		setup_placeholder_data()
		return
	
	# 設置完整屬性
	element = block_data.get("element", "neutral")
	block_name = block_data.get("name", {"zh": "未知方塊", "en": "Unknown Block"})
	shape = block_data.get("shape", "single")
	shape_pattern = block_data.get("shape_pattern", [[1]])
	rotation_allowed = block_data.get("rotation_allowed", false)
	flip_allowed = block_data.get("flip_allowed", false)
	bonus_value = block_data.get("bonus_value", 1)
	rarity = block_data.get("rarity", "common")
	icon_path = block_data.get("icon_path", "")
	
	# 更新完整 tile_data
	tile_data = {
		"type": "battle_block",
		"block_id": block_id,
		"element": element,
		"bonus_value": bonus_value,
		"rarity": rarity,
		"name": block_name,
		"localized_name": get_localized_name(block_data),
		"shape": shape,
		"shape_pattern": shape_pattern,
		"rotation_allowed": rotation_allowed,
		"flip_allowed": flip_allowed,
		"icon_path": icon_path
	}
	
	print("[BattleTile] 創建戰鬥方塊：", block_id, " (", element, ", +", bonus_value, ")")
	
	# 重新設置樣式
	if is_inside_tree():
		setup_battle_tile_style()

# 設置占位符數據（當找不到真實數據時）
func setup_placeholder_data():
	element = "neutral"
	bonus_value = 1
	rarity = "common"
	tile_data = {
		"type": "battle_block",
		"block_id": block_id,
		"element": element,
		"bonus_value": bonus_value,
		"rarity": rarity,
		"name": {"zh": "未知方塊", "en": "Unknown Block"},
		"localized_name": "未知方塊",
		"shape": shape,
		"shape_pattern": shape_pattern,
		"rotation_allowed": rotation_allowed,
		"flip_allowed": flip_allowed,
		"icon_path": icon_path
	}

# 獲取本地化名稱
func get_localized_name(block_data: Dictionary) -> String:
	var names = block_data.get("name", {})
	return names.get(ResourceManager.current_language, names.get("zh", "未知"))

# 獲取方塊完整資訊摘要
func get_info_summary() -> String:
	return "%s (%s) | +%d | %s | %s" % [
		tile_data.get("localized_name", "?"),
		element,
		bonus_value,
		rarity,
		"可旋轉" if rotation_allowed else "固定"
	]



# === 樣式設定 ===

# 設置戰鬥方塊的特殊樣式
func setup_battle_tile_style():
	# 清除舊的內容
	for child in get_children():
		if child.name in ["ContentContainer", "TypeLabel"]:
			child.queue_free()
	
	# 創建背景
	background_rect = ColorRect.new()
	background_rect.name = "Background"
	background_rect.size = size
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_rect)
	
	# 根據屬性設置顏色
	var element_color = get_element_color()
	background_rect.color = element_color
	
	# 創建邊框樣式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = element_color
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.corner_radius_bottom_right = 15
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.border_color = get_element_border_color()
	
	add_theme_stylebox_override("panel", style_box)
	
	# 創建內容佈局
	create_battle_content()

# 創建戰鬥方塊的內容佈局
func create_battle_content():
	# 檢查是否是多格圖塊
	if is_multi_grid_tile():
		create_multi_grid_content()
	else:
		create_single_grid_content()

# 創建單格圖塊內容
func create_single_grid_content():
	# 創建垂直容器
	var vbox = VBoxContainer.new()
	vbox.name = "ContentContainer"
	vbox.size = size
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)
	
	# 屬性標籤
	element_label = Label.new()
	element_label.text = get_element_display_name()
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	element_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 屬性標籤樣式
	element_label.add_theme_font_size_override("font_size", 16)
	element_label.add_theme_color_override("font_color", Color.WHITE)
	
	vbox.add_child(element_label)
	
	# 加成值標籤
	bonus_label = Label.new()
	bonus_label.text = "+" + str(bonus_value)
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bonus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 加成值標籤樣式
	bonus_label.add_theme_font_size_override("font_size", 24)
	bonus_label.add_theme_color_override("font_color", Color.YELLOW)
	
	vbox.add_child(bonus_label)
	
	# 方塊ID標籤（調試用）
	var id_label = Label.new()
	id_label.text = block_id
	id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	id_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	id_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# ID標籤樣式
	id_label.add_theme_font_size_override("font_size", 12)
	id_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.7))
	
	vbox.add_child(id_label)

# 創建多格圖塊內容（縮放顯示）
func create_multi_grid_content():
	# 計算縮放參數
	var scale_info = calculate_multi_grid_scale()
	
	# 創建縮放後的多格圖塊容器
	var grid_container = Control.new()
	grid_container.name = "MultiGridContainer"
	grid_container.size = Vector2(scale_info.display_width, scale_info.display_height)
	grid_container.position = Vector2(
		(size.x - scale_info.display_width) / 2,
		(size.y - scale_info.display_height) / 2
	)
	grid_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grid_container)
	
	# 渲染各個格子
	for row in range(shape_pattern.size()):
		var row_data = shape_pattern[row]
		for col in range(row_data.size()):
			if row_data[col] == 1:  # 有效格子
				create_grid_cell(grid_container, row, col, scale_info)
	
	# 添加形狀標識
	create_shape_indicator(grid_container, scale_info)
	
	# 添加加成值標籤
	create_bonus_overlay(grid_container, scale_info)

# 計算多格圖塊縮放參數
func calculate_multi_grid_scale() -> Dictionary:
	# 計算實際佔用的格子數量
	var max_width = 0
	var max_height = shape_pattern.size()
	
	for row_data in shape_pattern:
		max_width = max(max_width, row_data.size())
	
	# 標準格子大小 (棋盤中每格66.67px)
	var standard_cell_size = 66.67
	var actual_width = max_width * standard_cell_size
	var actual_height = max_height * standard_cell_size
	
	# 可視區域 (容器的80%)
	var display_area = 160.0  # 200 * 0.8
	
	# 計算縮放係數
	var scale_factor = min(display_area / actual_width, display_area / actual_height)
	
	# 縮放後的顯示尺寸
	var display_width = actual_width * scale_factor
	var display_height = actual_height * scale_factor
	var cell_size = standard_cell_size * scale_factor
	
	return {
		"scale_factor": scale_factor,
		"display_width": display_width,
		"display_height": display_height,
		"cell_size": cell_size,
		"max_width": max_width,
		"max_height": max_height
	}

# 創建單個格子
func create_grid_cell(parent: Control, row: int, col: int, scale_info: Dictionary):
	var cell = ColorRect.new()
	cell.size = Vector2(scale_info.cell_size - 2, scale_info.cell_size - 2)  # 2px間距
	cell.position = Vector2(col * scale_info.cell_size + 1, row * scale_info.cell_size + 1)
	cell.color = get_element_color()
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 添加圓角效果
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = get_element_color()
	style_box.corner_radius_top_left = min(15 * scale_info.scale_factor, 8)
	style_box.corner_radius_top_right = min(15 * scale_info.scale_factor, 8)
	style_box.corner_radius_bottom_left = min(15 * scale_info.scale_factor, 8)
	style_box.corner_radius_bottom_right = min(15 * scale_info.scale_factor, 8)
	style_box.border_width_left = max(1, 2 * scale_info.scale_factor)
	style_box.border_width_right = max(1, 2 * scale_info.scale_factor)
	style_box.border_width_top = max(1, 2 * scale_info.scale_factor)
	style_box.border_width_bottom = max(1, 2 * scale_info.scale_factor)
	style_box.border_color = get_element_border_color()
	
	# 創建有樣式的面板而不是ColorRect
	var cell_panel = Panel.new()
	cell_panel.size = Vector2(scale_info.cell_size - 2, scale_info.cell_size - 2)
	cell_panel.position = Vector2(col * scale_info.cell_size + 1, row * scale_info.cell_size + 1)
	cell_panel.add_theme_stylebox_override("panel", style_box)
	cell_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	parent.add_child(cell_panel)

# 創建形狀標識
func create_shape_indicator(parent: Control, scale_info: Dictionary):
	var indicator = Label.new()
	var indicator_text = get_shape_indicator_text()
	if indicator_text.is_empty():
		return
	
	indicator.text = indicator_text
	indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 計算位置（根據形狀類型）
	var indicator_pos = get_shape_indicator_position(scale_info)
	indicator.position = indicator_pos
	indicator.size = Vector2(20 * scale_info.scale_factor, 20 * scale_info.scale_factor)
	
	# 樣式設置
	indicator.add_theme_font_size_override("font_size", max(12, 16 * scale_info.scale_factor))
	indicator.add_theme_color_override("font_color", Color.WHITE)
	
	parent.add_child(indicator)

# 創建加成值覆蓋標籤
func create_bonus_overlay(parent: Control, scale_info: Dictionary):
	bonus_label = Label.new()
	bonus_label.text = "+" + str(bonus_value)
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bonus_label.position = Vector2(scale_info.display_width - 30 * scale_info.scale_factor, -5)
	bonus_label.size = Vector2(30 * scale_info.scale_factor, 20 * scale_info.scale_factor)
	bonus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 樣式設置
	bonus_label.add_theme_font_size_override("font_size", max(14, 18 * scale_info.scale_factor))
	bonus_label.add_theme_color_override("font_color", Color.YELLOW)
	
	parent.add_child(bonus_label)

# === 屬性相關方法 ===

# 獲取屬性顏色
func get_element_color() -> Color:
	match element:
		"fire":
			return Color(1.0, 0.267, 0.267, 0.9)  # 紅色
		"water":
			return Color(0.267, 0.667, 1.0, 0.9)  # 藍色
		"grass":
			return Color(0.267, 0.8, 0.267, 0.9)  # 綠色
		"light":
			return Color(1.0, 1.0, 0.6, 0.9)      # 淺黃色
		"dark":
			return Color(0.4, 0.267, 0.6, 0.9)    # 紫色
		_:
			return Color(0.5, 0.5, 0.5, 0.9)      # 灰色 (中性)

# 獲取屬性邊框顏色
func get_element_border_color() -> Color:
	match element:
		"fire":
			return Color(0.8, 0.0, 0.0, 1.0)
		"water":
			return Color(0.0, 0.4, 0.8, 1.0)
		"grass":
			return Color(0.0, 0.6, 0.0, 1.0)
		"light":
			return Color(0.9, 0.9, 0.0, 1.0)
		"dark":
			return Color(0.3, 0.0, 0.5, 1.0)
		_:
			return Color(0.3, 0.3, 0.3, 1.0)

# 獲取屬性顯示名稱
func get_element_display_name() -> String:
	match element:
		"fire":
			return "火"
		"water":
			return "水"
		"grass":
			return "草"
		"light":
			return "光"
		"dark":
			return "暗"
		_:
			return "無"

# 重寫顯示文字方法
func get_display_text() -> String:
	return get_element_display_name() + " +" + str(bonus_value)

# === 戰鬥相關方法 ===

# 獲取戰鬥力值
func get_battle_power() -> int:
	return bonus_value

# 檢查屬性克制關係
func check_element_advantage(target_element: String) -> float:
	# 簡單的屬性克制關係
	match [element, target_element]:
		["fire", "grass"], ["water", "fire"], ["grass", "water"]:
			return 1.5  # 優勢
		["grass", "fire"], ["fire", "water"], ["water", "grass"]:
			return 0.75  # 劣勢
		["light", "dark"], ["dark", "light"]:
			return 1.25  # 光暗互克
		_:
			return 1.0  # 無克制關係

# === 多格圖塊輔助方法 ===

# 檢查是否是多格圖塊
func is_multi_grid_tile() -> bool:
	if shape_pattern.is_empty():
		return false
	
	# 單格圖塊：[[1]]
	if shape_pattern.size() == 1 and shape_pattern[0].size() == 1:
		return false
	
	# 計算有效格子數量
	var valid_cells = 0
	for row in shape_pattern:
		for cell in row:
			if cell == 1:
				valid_cells += 1
	
	return valid_cells > 1

# 獲取形狀指示器文字
func get_shape_indicator_text() -> String:
	match shape:
		"L_shape":
			return "L"
		"T_shape":
			return "T"
		"cross":
			return "+"
		"line_3", "line_2":
			# 判斷方向
			if shape_pattern.size() == 1:
				return "—"  # 水平線
			else:
				return "|"  # 垂直線
		"square":
			return "■"
		_:
			return ""

# 獲取形狀指示器位置
func get_shape_indicator_position(scale_info: Dictionary) -> Vector2:
	match shape:
		"L_shape":
			# 左下角
			return Vector2(5, scale_info.display_height - 25)
		"T_shape":
			# 底部中央
			return Vector2(scale_info.display_width / 2 - 10, scale_info.display_height - 25)
		"cross":
			# 中央
			return Vector2(scale_info.display_width / 2 - 10, scale_info.display_height / 2 - 10)
		"square":
			# 右上角
			return Vector2(scale_info.display_width - 25, 5)
		_:
			# 默認左上角
			return Vector2(5, 5)

# === 擴展性工廠方法 ===

# 根據 ID 創建戰鬥方塊（主要方法）
static func create_from_id(block_id: String) -> BattleTile:
	return create_from_block_data(block_id)

# 根據屬性創建戰鬥方塊（動態查詢）
static func create_from_element(element: String) -> BattleTile:
	if not ResourceManager:
		push_warning("[BattleTile] ResourceManager 未找到，使用預設方塊")
		return create_from_id("B001")
	
	# 動態查找指定屬性的方塊
	for block_id in ResourceManager.block_database:
		var block_data = ResourceManager.block_database[block_id]
		if block_data.get("element") == element:
			return create_from_id(block_id)
	
	push_warning("[BattleTile] 找不到屬性 '%s' 的方塊，使用預設" % element)
	return create_from_id("B001")

# 根據條件查詢創建方塊
static func create_by_criteria(criteria: Dictionary) -> BattleTile:
	if not ResourceManager:
		return create_from_id("B001")
	
	var matching_blocks = []
	for block_id in ResourceManager.block_database:
		var block_data = ResourceManager.block_database[block_id]
		var matches = true
		
		# 檢查所有條件
		for key in criteria:
			if block_data.get(key) != criteria[key]:
				matches = false
				break
		
		if matches:
			matching_blocks.append(block_id)
	
	if matching_blocks.size() > 0:
		# 如果有多個匹配，返回第一個
		return create_from_id(matching_blocks[0])
	
	push_warning("[BattleTile] 找不到符合條件的方塊：%s" % str(criteria))
	return create_from_id("B001")

# 根據稀有度隨機創建方塊
static func create_random_by_rarity(rarity: String = "common") -> BattleTile:
	return create_by_criteria({"rarity": rarity})

# 隨機創建任意方塊
static func create_random() -> BattleTile:
	if not ResourceManager or ResourceManager.block_database.is_empty():
		return create_from_id("B001")
	
	var all_ids = ResourceManager.block_database.keys()
	var random_id = all_ids[randi() % all_ids.size()]
	return create_from_id(random_id)

# 獲取所有可用的方塊ID
static func get_available_ids() -> Array:
	if not ResourceManager:
		return ["B001"]
	return ResourceManager.block_database.keys()

# 根據屬性獲取所有相關方塊ID
static func get_ids_by_element(element: String) -> Array:
	if not ResourceManager:
		return []
	
	var matching_ids = []
	for block_id in ResourceManager.block_database:
		var block_data = ResourceManager.block_database[block_id]
		if block_data.get("element") == element:
			matching_ids.append(block_id)
	
	return matching_ids

# === 兼容性方法（保留舊接口，但使用動態查詢）===

static func create_fire_tile() -> BattleTile:
	return create_from_element("fire")

static func create_water_tile() -> BattleTile:
	return create_from_element("water")

static func create_grass_tile() -> BattleTile:
	return create_from_element("grass")

static func create_light_tile() -> BattleTile:
	return create_from_element("light")

static func create_dark_tile() -> BattleTile:
	return create_from_element("dark")

# === 進階工廠方法示例 ===

# 創建高稀有度方塊
static func create_rare_tile() -> BattleTile:
	return create_by_criteria({"rarity": "rare"})

# 創建可旋轉的方塊
static func create_rotatable_tile() -> BattleTile:
	return create_by_criteria({"rotation_allowed": true})

# 創建特定形狀的方塊
static func create_by_shape(shape: String) -> BattleTile:
	return create_by_criteria({"shape": shape})
