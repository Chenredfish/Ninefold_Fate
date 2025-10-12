# DraggableTile.gd - 可拖拽圖塊基類
# 所有可拖拽的UI圖塊都應該繼承這個類別
class_name DraggableTile
extends Control

# === 訊號 ===
signal drag_started()
signal drag_ended(success: bool)

# === 導出屬性 ===
@export var tile_type: String = ""  # 圖塊類型（如 "navigation", "battle", "level"）
@export var tile_data: Dictionary = {}  # 圖塊相關數據
@export var return_on_invalid_drop: bool = true  # 無效投放時是否回到原位

# === 狀態變數 ===
var is_dragging: bool = false
var original_position: Vector2
var original_modulate: Color

func _ready():
	# 連接輸入事件
	gui_input.connect(_on_gui_input)
	
	# 保存原始狀態
	original_position = global_position
	original_modulate = modulate
	
	# 設置基本樣式
	setup_base_style()
	
	print("[DraggableTile] 圖塊已初始化：", tile_type)

# === 輸入處理 ===

func _on_gui_input(event: InputEvent):
	# 處理觸控輸入
	if event is InputEventScreenTouch:
		var touch_event = event as InputEventScreenTouch
		
		if touch_event.pressed and not is_dragging:
			# 開始拖拽
			start_dragging(touch_event.position)
		elif not touch_event.pressed and is_dragging:
			# 結束拖拽
			end_dragging(touch_event.position)
	
	# 處理滑鼠輸入（用於桌面測試）
	elif event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed and not is_dragging:
				start_dragging(mouse_event.position)
			elif not mouse_event.pressed and is_dragging:
				end_dragging(mouse_event.position)
	
	# 處理拖拽移動
	elif (event is InputEventScreenDrag and is_dragging) or \
		 (event is InputEventMouseMotion and is_dragging and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		var drag_pos = event.position if event is InputEventScreenDrag else event.position
		update_dragging(drag_pos)

# === 拖拽控制方法 ===

# 開始拖拽
func start_dragging(local_pos: Vector2):
	var global_pos = global_position + local_pos
	
	if DragDropManager.start_drag(self, global_pos):
		is_dragging = true
		original_position = global_position
		
		# 調用可重寫的開始拖拽方法
		on_drag_started()
		
		# 發送訊號
		drag_started.emit()

# 更新拖拽位置
func update_dragging(local_pos: Vector2):
	var global_pos = global_position + local_pos
	DragDropManager.update_drag(global_pos)

# 結束拖拽
func end_dragging(local_pos: Vector2):
	var global_pos = global_position + local_pos
	var success = DragDropManager.end_drag(global_pos)
	
	is_dragging = false
	
	# 調用可重寫的結束拖拽方法
	on_drag_ended(success)
	
	# 發送訊號
	drag_ended.emit(success)

# === 可重寫的虛擬方法 ===

# 拖拽開始時調用（子類別可重寫）
func on_drag_started():
	pass

# 拖拽結束時調用（子類別可重寫）
func on_drag_ended(success: bool):
	pass

# 獲取顯示文字（子類別可重寫）
func get_display_text() -> String:
	return tile_type.capitalize()

# 獲取目標場景路徑（導航圖塊可重寫）
func get_target_scene_path() -> String:
	return ""

# === 樣式設定 ===

# 設定基本樣式
func setup_base_style():
	# 設定最小尺寸
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(200, 200)
	
	# 創建基本樣式盒
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.3, 0.3, 0.4, 0.9)  # 深灰色背景
	style_box.corner_radius_top_left = 20
	style_box.corner_radius_top_right = 20
	style_box.corner_radius_bottom_left = 20
	style_box.corner_radius_bottom_right = 20
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.6, 0.6, 0.7, 1.0)
	
	add_theme_stylebox_override("panel", style_box)
	
	# 添加標籤顯示圖塊類型
	create_type_label()

# 創建類型標籤
func create_type_label():
	# 檢查是否已有標籤
	var existing_label = get_node_or_null("TypeLabel")
	if existing_label:
		existing_label.queue_free()
	
	# 創建新標籤
	var label = Label.new()
	label.name = "TypeLabel"
	label.text = get_display_text()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不攔截滑鼠事件
	
	# 設定字體樣式
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	
	add_child(label)

# === 視覺效果 ===

# 設定拖拽狀態的視覺效果
func set_dragging_visual(dragging: bool):
	if dragging:
		modulate.a = 0.5
		scale = Vector2(0.95, 0.95)
	else:
		modulate = original_modulate
		scale = Vector2(1.0, 1.0)

# 設定懸停效果
func set_hover_effect(enabled: bool):
	if enabled:
		modulate = Color(1.2, 1.2, 1.2, 1.0)  # 稍微變亮
		scale = Vector2(1.05, 1.05)
	else:
		modulate = original_modulate
		scale = Vector2(1.0, 1.0)

# === 資料設定方法 ===

# 設定圖塊資料
func set_tile_data(new_type: String, new_data: Dictionary = {}):
	tile_type = new_type
	tile_data = new_data
	
	# 更新顯示
	create_type_label()

# 獲取圖塊資料
func get_tile_data() -> Dictionary:
	return {
		"type": tile_type,
		"data": tile_data,
		"position": global_position
	}

# === 除錯方法 ===

# 獲取除錯資訊
func get_debug_info() -> Dictionary:
	return {
		"tile_type": tile_type,
		"is_dragging": is_dragging,
		"position": global_position,
		"data_keys": tile_data.keys()
	}

# === 滑鼠懸停效果（可選） ===

func _mouse_entered():
	if not is_dragging:
		set_hover_effect(true)

func _mouse_exited():
	if not is_dragging:
		set_hover_effect(false)

# 連接懸停事件
func _enter_tree():
	if not mouse_entered.is_connected(_mouse_entered):
		mouse_entered.connect(_mouse_entered)
	if not mouse_exited.is_connected(_mouse_exited):
		mouse_exited.connect(_mouse_exited)