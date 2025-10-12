# DropZone.gd - 投放區域基類
# 定義可以接受拖拽圖塊的區域，處理高亮效果和投放驗證
class_name DropZone
extends Control

# === 訊號 ===
signal tile_dropped(tile_data: Dictionary)
signal tile_hover_enter(tile_data: Dictionary)
signal tile_hover_exit()

# === 導出屬性 ===
@export var accepted_tile_types: Array[String] = []  # 接受的圖塊類型
@export var zone_type: String = ""  # 投放區域類型
@export var highlight_color_valid: Color = Color(0.267, 1.0, 0.267, 0.25)  # 有效高亮顏色
@export var highlight_color_invalid: Color = Color(1.0, 0.267, 0.267, 0.25)  # 無效高亮顏色

# === 內部節點 ===
var highlight_overlay: ColorRect
var border_highlight: NinePatchRect

func _ready():
	# 創建高亮覆蓋層
	setup_highlight_overlay()
	
	# 註冊到拖放管理器
	DragDropManager.register_drop_zone(self)
	
	# 設置基本樣式
	setup_base_style()
	
	print("[DropZone] 投放區域已初始化：", zone_type)

func _exit_tree():
	# 從管理器中移除
	DragDropManager.unregister_drop_zone(self)

# === 高亮系統設置 ===

# 設置高亮覆蓋層
func setup_highlight_overlay():
	highlight_overlay = ColorRect.new()
	highlight_overlay.name = "HighlightOverlay"
	highlight_overlay.size = size
	highlight_overlay.color = Color.TRANSPARENT
	highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_overlay.z_index = 10
	add_child(highlight_overlay)

# 設置基本樣式
func setup_base_style():
	# 設置最小尺寸
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(200, 200)
	
	# 創建基本樣式盒（虛線邊框）
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.3, 0.3)  # 半透明背景
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.corner_radius_bottom_right = 15
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color(0.5, 0.5, 0.6, 0.6)  # 虛線效果
	
	add_theme_stylebox_override("panel", style_box)
	
	# 添加提示標籤
	create_hint_label()

# 創建提示標籤
func create_hint_label():
	var existing_label = get_node_or_null("HintLabel")
	if existing_label:
		existing_label.queue_free()
	
	var label = Label.new()
	label.name = "HintLabel"
	label.text = get_zone_hint_text()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 設定字體樣式
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.8))
	
	add_child(label)

# === 投放驗證 ===

# 檢查是否可以接受指定圖塊
func can_accept_tile(tile) -> bool:
	# 如果沒有指定接受類型，則接受所有
	if accepted_tile_types.is_empty():
		return true
	
	# 檢查圖塊類型是否在接受列表中
	return tile.tile_type in accepted_tile_types

# === 高亮效果控制 ===

# 設置有效投放高亮
func set_highlight_valid(enabled: bool):
	if enabled:
		highlight_overlay.color = highlight_color_valid
		
		# 更新邊框樣式
		var style = StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.corner_radius_top_left = 15
		style.corner_radius_top_right = 15
		style.corner_radius_bottom_left = 15
		style.corner_radius_bottom_right = 15
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = Color(0.267, 1.0, 0.267, 1.0)  # 綠色邊框
		add_theme_stylebox_override("panel", style)
		
		# 開始脈動動畫
		start_pulse_animation()
	else:
		clear_highlight()

# 設置無效投放高亮
func set_highlight_invalid(enabled: bool):
	if enabled:
		highlight_overlay.color = highlight_color_invalid
		
		# 更新邊框樣式
		var style = StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.corner_radius_top_left = 15
		style.corner_radius_top_right = 15
		style.corner_radius_bottom_left = 15
		style.corner_radius_bottom_right = 15
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = Color(1.0, 0.267, 0.267, 1.0)  # 紅色邊框
		add_theme_stylebox_override("panel", style)
		
		# 開始搖擺動畫
		start_shake_animation()
	else:
		clear_highlight()

# 清除高亮效果
func clear_highlight():
	highlight_overlay.color = Color.TRANSPARENT
	setup_base_style()  # 恢復基本樣式
	stop_all_animations()

# === 動畫效果 ===

# 開始脈動動畫
func start_pulse_animation():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(highlight_overlay, "modulate:a", 0.3, 0.5)
	tween.tween_property(highlight_overlay, "modulate:a", 0.8, 0.5)

# 開始搖擺動畫
func start_shake_animation():
	var tween = create_tween()
	tween.set_loops()
	var original_pos = position
	tween.tween_property(self, "position", original_pos + Vector2(2, 0), 0.1)
	tween.tween_property(self, "position", original_pos + Vector2(-2, 0), 0.1)
	tween.tween_property(self, "position", original_pos, 0.1)

# 停止所有動畫
func stop_all_animations():
	# 在 Godot 4.x 中，Tween 會自動管理，我們只需要恢復狀態
	# 恢復原始狀態
	highlight_overlay.modulate.a = 1.0

# === 投放處理 ===

# 處理圖塊投放
func on_tile_dropped(tile_data: Dictionary):
	print("[DropZone] 接收到投放：", tile_data)
	
	# 播放投放成功效果
	play_drop_success_effect()
	
	# 發送投放訊號
	tile_dropped.emit(tile_data)
	
	# 調用可重寫的投放處理方法
	handle_tile_drop(tile_data)

# 可重寫的投放處理方法（子類別可重寫）
func handle_tile_drop(tile_data: Dictionary):
	pass

# 播放投放成功效果
func play_drop_success_effect():
	# 縮放效果
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	# 創建成功粒子
	create_drop_particles()

# 創建投放粒子效果
func create_drop_particles():
	var center_pos = global_position + size / 2
	
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color(0.2, 1.0, 0.2, 0.9)  # 綠色粒子
		particle.position = center_pos
		get_tree().current_scene.add_child(particle)
		
		# 圓形擴散
		var angle = i * PI / 4
		var direction = Vector2(cos(angle), sin(angle))
		var distance = 40
		
		var tween = create_tween()
		tween.tween_property(particle, "position", center_pos + direction * distance, 0.4)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tween.tween_callback(particle.queue_free)

# === 輔助方法 ===

# 獲取區域提示文字（子類別可重寫）
func get_zone_hint_text() -> String:
	if zone_type.is_empty():
		return "拖拽至此"
	else:
		return zone_type.capitalize() + " 區域"

# 獲取全域矩形範圍（使用原生方法）
func get_drop_zone_rect() -> Rect2:
	return get_global_rect()  # 使用 Control 的原生方法

# === 資料設定方法 ===

# 設置接受的圖塊類型
func set_accepted_types(types: Array[String]):
	accepted_tile_types = types
	create_hint_label()  # 更新提示

# 添加接受的圖塊類型
func add_accepted_type(type: String):
	if type not in accepted_tile_types:
		accepted_tile_types.append(type)
		create_hint_label()

# 移除接受的圖塊類型
func remove_accepted_type(type: String):
	if type in accepted_tile_types:
		accepted_tile_types.erase(type)
		create_hint_label()

# === 除錯方法 ===

# 獲取除錯資訊
func get_debug_info() -> Dictionary:
	return {
		"zone_type": zone_type,
		"accepted_types": accepted_tile_types,
		"position": global_position,
		"size": size,
		"is_highlighted": highlight_overlay.color.a > 0
	}
