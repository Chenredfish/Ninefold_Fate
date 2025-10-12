# NavigationTile.gd - 導航圖塊
# 用於場景切換的特化圖塊，主要用於主選單的功能導航
class_name NavigationTile
extends DraggableTile

# === 導出屬性 ===
@export var target_scene_path: String = ""  # 目標場景路徑
@export var navigation_data: Dictionary = {}  # 導航相關數據
@export var function_name: String = ""  # 功能名稱（如 "battle", "shop", "settings"）
@export var icon_texture: Texture2D  # 功能圖標

# === 內部節點 ===
var icon_node: TextureRect
var title_label: Label
var description_label: Label

func _ready():
	# 設置基本屬性 - 根據功能名稱設定類型
	if function_name != "":
		tile_type = function_name  # 使用具體功能名稱作為類型
	else:
		tile_type = "navigation"   # 預設為 navigation
	
	# 調用父類初始化
	super._ready()
	
	# 設置導航圖塊的特殊樣式
	setup_navigation_style()

# === 樣式設定 ===

# 設置導航圖塊的特殊樣式
func setup_navigation_style():
	# 重寫基本樣式
	var style_box = StyleBoxFlat.new()
	
	# 根據功能類型設定不同顏色
	match function_name:
		"battle":
			style_box.bg_color = Color(1.0, 0.267, 0.267, 0.9)  # 紅色 - 戰鬥
		"shop":
			style_box.bg_color = Color(1.0, 0.8, 0.2, 0.9)      # 金色 - 商店
		"deck":
			style_box.bg_color = Color(0.267, 0.8, 1.0, 0.9)    # 藍色 - 構築
		"settings":
			style_box.bg_color = Color(0.6, 0.6, 0.6, 0.9)      # 灰色 - 設定
		_:
			style_box.bg_color = Color(0.4, 0.4, 0.5, 0.9)      # 預設灰色
	
	# 圓角設定
	style_box.corner_radius_top_left = 25
	style_box.corner_radius_top_right = 25
	style_box.corner_radius_bottom_left = 25
	style_box.corner_radius_bottom_right = 25
	
	# 邊框設定
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color.WHITE
	
	add_theme_stylebox_override("panel", style_box)
	
	# 創建內容佈局
	create_navigation_content()

# 創建導航圖塊的內容佈局
func create_navigation_content():
	# 清除舊的標籤
	var old_label = get_node_or_null("TypeLabel")
	if old_label:
		old_label.queue_free()
	
	# 創建垂直容器
	var vbox = VBoxContainer.new()
	vbox.name = "ContentContainer"
	vbox.size = size
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)
	
	# 添加圖標
	if icon_texture:
		icon_node = TextureRect.new()
		icon_node.texture = icon_texture
		icon_node.custom_minimum_size = Vector2(80, 80)
		icon_node.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon_node)
	
	# 添加標題標籤
	title_label = Label.new()
	title_label.text = get_function_display_name()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 標題樣式
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	
	vbox.add_child(title_label)
	
	# 添加描述標籤
	description_label = Label.new()
	description_label.text = get_function_description()
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# 描述樣式
	description_label.add_theme_font_size_override("font_size", 12)
	description_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.8))
	
	vbox.add_child(description_label)

# === 文字內容 ===

# 獲取功能顯示名稱
func get_function_display_name() -> String:
	match function_name:
		"battle":
			return "戰鬥"
		"shop":
			return "商店"
		"deck", "build":
			return "構築"
		"settings":
			return "設定"
		"level_select":
			return "關卡選擇"
		_:
			return function_name.capitalize()

# 獲取功能描述
func get_function_description() -> String:
	match function_name:
		"battle":
			return "進入戰鬥模式"
		"shop":
			return "購買道具和裝備"
		"deck", "build":
			return "編輯卡組和策略"
		"settings":
			return "遊戲設定"
		"level_select":
			return "選擇關卡挑戰"
		_:
			return ""

# 重寫顯示文字方法
func get_display_text() -> String:
	return get_function_display_name()

# 重寫目標場景路徑方法
func get_target_scene_path() -> String:
	return target_scene_path

# === 拖拽事件處理 ===

# 拖拽開始時的特殊處理
func on_drag_started():
	super.on_drag_started()
	
	# 播放開始拖拽的音效或動畫
	play_drag_start_effect()

# 拖拽結束時的特殊處理
func on_drag_ended(success: bool):
	super.on_drag_ended(success)
	
	if success and target_scene_path != "":
		print("[NavigationTile] 準備切換到場景：", target_scene_path)
		
		# 延遲切換場景，讓動畫完成
		await get_tree().create_timer(0.5).timeout
		
		# 實際場景切換
		perform_scene_transition()
	elif success:
		# 沒有場景路徑，可能是其他類型的導航動作
		perform_navigation_action()

# === 場景切換邏輯 ===

# 執行場景切換
func perform_scene_transition():
	print("[NavigationTile] 切換場景：", target_scene_path)
	
	# 可以在這裡添加場景切換的過渡效果
	if ResourceLoader.exists(target_scene_path):
		get_tree().change_scene_to_file(target_scene_path)
	else:
		print("[NavigationTile] 錯誤：場景文件不存在 - ", target_scene_path)

# 執行導航動作（非場景切換）
func perform_navigation_action():
	print("[NavigationTile] 執行導航動作：", function_name)
	
	# 根據功能類型執行不同動作
	match function_name:
		"exit":
			get_tree().quit()
		"restart":
			get_tree().reload_current_scene()
		_:
			print("[NavigationTile] 未定義的導航動作：", function_name)

# === 視覺效果 ===

# 播放拖拽開始效果
func play_drag_start_effect():
	# 創建光環效果
	var glow_effect = ColorRect.new()
	glow_effect.size = size + Vector2(20, 20)
	glow_effect.position = Vector2(-10, -10)
	glow_effect.color = Color(1, 1, 1, 0.3)
	glow_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow_effect)
	
	# 光環脈動動畫
	var tween = create_tween()
	tween.tween_property(glow_effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(glow_effect.queue_free)

# 設置懸停效果（重寫父類方法）
func set_hover_effect(enabled: bool):
	if enabled:
		scale = Vector2(1.1, 1.1)
		modulate = Color(1.3, 1.3, 1.3, 1.0)
		
		# 添加懸停動畫
		var tween = create_tween()
		tween.tween_property(self, "rotation", 0.05, 0.2)
		tween.tween_property(self, "rotation", -0.05, 0.4)
		tween.tween_property(self, "rotation", 0.0, 0.2)
	else:
		scale = Vector2(1.0, 1.0)
		modulate = original_modulate
		rotation = 0.0

# === 設定方法 ===

# 設定導航資料
func set_navigation_data(scene_path: String, func_name: String, data: Dictionary = {}):
	target_scene_path = scene_path
	function_name = func_name
	navigation_data = data
	
	# 更新 tile_type 以匹配功能名稱
	tile_type = func_name
	
	# 更新tile_data
	tile_data = {
		"target_scene": scene_path,
		"function": func_name,
		"navigation_data": data
	}
	
	# 重新創建內容
	setup_navigation_style()

# 設定圖標
func set_icon(texture: Texture2D):
	icon_texture = texture
	if icon_node:
		icon_node.texture = texture

# === 工廠方法 ===

# 創建戰鬥導航圖塊
static func create_battle_tile(scene_path: String = "") -> NavigationTile:
	var tile = NavigationTile.new()
	tile.set_navigation_data(scene_path, "battle")
	return tile

# 創建商店導航圖塊
static func create_shop_tile(scene_path: String = "") -> NavigationTile:
	var tile = NavigationTile.new()
	tile.set_navigation_data(scene_path, "shop")
	return tile

# 創建構築導航圖塊
static func create_deck_tile(scene_path: String = "") -> NavigationTile:
	var tile = NavigationTile.new()
	tile.set_navigation_data(scene_path, "deck")
	return tile

# 創建設定導航圖塊
static func create_settings_tile(scene_path: String = "") -> NavigationTile:
	var tile = NavigationTile.new()
	tile.set_navigation_data(scene_path, "settings")
	return tile