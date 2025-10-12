# BattleBoard.gd - 戰鬥棋盤
# 3x3 的戰鬥棋盤，用於拼裝戰鬥方塊
class_name BattleBoard
extends DropZone

# === 棋盤屬性 ===
@export var board_size: int = 3  # 棋盤大小 (3x3)
@export var grid_spacing: int = 0  # 格子間距
@export var cell_size: Vector2 = Vector2(200, 200)  # 單格尺寸

# === 棋盤狀態 ===
var grid_cells: Array = []  # 存儲棋盤格子
var placed_tiles: Dictionary = {}  # 存儲已放置的方塊 {position: tile_data}
var grid_container: GridContainer
var current_hover_cell: Vector2i = Vector2i(-1, -1)  # 當前懸停的格子
var drop_history: Array = []  # 投放紀錄 [{tile_data, pos}]
var current_tween: Tween  # 追蹤當前的動畫
var original_position: Vector2  # 儲存原始位置

func _ready():
	# 設置基本屬性
	zone_type = "battle_board"
	set_accepted_types(["battle_block"])  # 只接受戰鬥方塊
	
	# 儲存原始位置
	original_position = position
	
	# 調用父類初始化
	super._ready()
	
	# 設置棋盤樣式和佈局
	setup_battle_board()

# === 棋盤設置 ===

# 設置戰鬥棋盤
func setup_battle_board():
	# 設置大小為 3x3 格子
	var board_total_size = Vector2(
		board_size * cell_size.x + (board_size - 1) * grid_spacing,
		board_size * cell_size.y + (board_size - 1) * grid_spacing
	)
	size = board_total_size
	custom_minimum_size = board_total_size
	
	# 創建網格容器
	create_grid_layout()
	
	# 設置棋盤樣式
	setup_board_style()
	
	print("[BattleBoard] 戰鬥棋盤已創建：", board_size, "x", board_size)

# 創建網格佈局
func create_grid_layout():
	# 清除舊的網格
	if grid_container:
		grid_container.queue_free()
	
	# 創建新的網格容器
	grid_container = GridContainer.new()
	grid_container.name = "GridContainer"
	grid_container.columns = board_size
	grid_container.size = size
	grid_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grid_container)
	
	# 初始化格子陣列
	grid_cells.clear()
	grid_cells.resize(board_size * board_size)
	
	# 創建每個格子
	for i in range(board_size * board_size):
		var cell = create_grid_cell(i)
		grid_cells[i] = cell
		grid_container.add_child(cell)

# 創建單個格子
func create_grid_cell(index: int) -> Control:
	var cell = Control.new()
	cell.name = "GridCell_" + str(index)
	cell.custom_minimum_size = cell_size
	cell.size = cell_size
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 設置格子樣式
	var style_box = create_cell_style(
		Color(0.1, 0.1, 0.2, 0.8),  # 深藍色半透明
		Color(0.3, 0.3, 0.5, 0.6),  # 邊框顏色
		10,  # 圓角半徑
		2   # 邊框寬度
	)
	cell.add_theme_stylebox_override("panel", style_box)
	
	# 添加格子編號標籤（用於除錯）
	var label = Label.new()
	label.text = str(index)
	label.size = cell_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.5))
	cell.add_child(label)
	
	return cell

# 設置棋盤整體樣式
func setup_board_style():
	# 重寫父類的基本樣式
	var style_box = create_cell_style(
		Color(0.05, 0.05, 0.15, 0.9),  # 深色背景
		Color(0.3, 0.5, 0.8, 0.8),     # 藍色邊框
		20,  # 圓角半徑
		4    # 邊框寬度
	)
	add_theme_stylebox_override("panel", style_box)
	
	# 更新提示標籤
	update_hint_label()

# 更新提示標籤
func update_hint_label():
	var hint_label = get_node_or_null("HintLabel")
	if hint_label:
		hint_label.text = get_board_hint_text()

# === 投放處理 ===

# 重寫父類的 can_accept_tile 方法，檢查是否可以在當前滑鼠位置放置
func can_accept_tile(tile) -> bool:
	# 先檢查類型是否匹配
	if not super.can_accept_tile(tile):
		return false
	
	# 獲取圖塊的形狀數據
	var shape_pattern = tile.tile_data.get("shape_pattern", [[1]])
	
	# 檢查是否可以在當前鼠標位置放置多格圖塊
	var drop_pos = find_drop_position_from_mouse()
	return can_place_multi_tile_at(drop_pos, shape_pattern)

# 重寫高亮方法，讓拖拽高亮由主程式系統處理
func set_highlight_valid(enabled: bool):
	if enabled:
		# 設置有效高亮但不改變格子顏色
		if highlight_overlay:
			highlight_overlay.color = highlight_color_valid
		start_pulse_animation()
	else:
		clear_highlight()

# 設置無效投放高亮
func set_highlight_invalid(enabled: bool):
	if enabled:
		# 設置無效高亮但不改變格子顏色
		if highlight_overlay:
			highlight_overlay.color = highlight_color_invalid
		start_shake_animation()
	else:
		clear_highlight()

# 重寫震動動畫，讓我們能追蹤和停止它
func start_shake_animation():
	# 先停止之前的動畫
	stop_all_animations()
	
	current_tween = create_tween()
	current_tween.set_loops()
	current_tween.tween_property(self, "position", original_position + Vector2(2, 0), 0.1)
	current_tween.tween_property(self, "position", original_position + Vector2(-2, 0), 0.1)
	current_tween.tween_property(self, "position", original_position, 0.1)
	
	#print("[BattleBoard] 震動動畫開始")

# 重寫脈動動畫
func start_pulse_animation():
	# 先停止之前的動畫
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	current_tween = create_tween()
	current_tween.set_loops()
	current_tween.tween_property(highlight_overlay, "modulate:a", 0.3, 0.5)
	current_tween.tween_property(highlight_overlay, "modulate:a", 0.8, 0.5)



# 重寫動畫停止方法，正確停止震動和恢復位置
func stop_all_animations():
	# 停止當前的 Tween 動畫
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null
	
	# 恢復原始位置
	position = original_position
	
	# 恢復高亮覆蓋層透明度
	if highlight_overlay:
		highlight_overlay.modulate.a = 1.0
	
	#print("[BattleBoard] 所有動畫已停止，位置已恢復")

# 重寫父類的清除高亮方法，避免覆蓋格子樣式
func clear_highlight():
	# 只處理父類的高亮覆蓋層，不影響我們的格子顏色
	if highlight_overlay:
		highlight_overlay.color = Color.TRANSPARENT
	stop_all_animations()



# === 多格圖塊支援 ===

# 檢查多格圖塊是否可以在指定位置放置
func can_place_multi_tile_at(base_pos: Vector2i, shape_pattern: Array) -> bool:
	if base_pos == Vector2i(-1, -1) or shape_pattern.is_empty():
		return false
	
	# 檢查形狀模式中的每個格子
	for row in range(shape_pattern.size()):
		var row_data = shape_pattern[row]
		for col in range(row_data.size()):
			if row_data[col] == 1:  # 有效格子
				var target_pos = Vector2i(base_pos.x + col, base_pos.y + row)
				
				# 檢查是否超出棋盤邊界
				if target_pos.x < 0 or target_pos.x >= board_size or target_pos.y < 0 or target_pos.y >= board_size:
					return false
				
				# 檢查位置是否已被佔用
				if placed_tiles.has(target_pos):
					return false
	
	return true

# 獲取多格圖塊將要佔用的所有位置
func get_multi_tile_positions(base_pos: Vector2i, shape_pattern: Array) -> Array:
	var positions = []
	
	if base_pos == Vector2i(-1, -1) or shape_pattern.is_empty():
		return positions
	
	for row in range(shape_pattern.size()):
		var row_data = shape_pattern[row]
		for col in range(row_data.size()):
			if row_data[col] == 1:  # 有效格子
				var target_pos = Vector2i(base_pos.x + col, base_pos.y + row)
				positions.append(target_pos)
	
	return positions

# 重寫投放處理方法
func handle_tile_drop(tile_data: Dictionary):
	# 停止任何進行中的動畫
	stop_all_animations()
	
	# 根據拖拽位置找到對應的格子
	var drop_position = find_drop_position_from_mouse()
	var shape_pattern = tile_data.get("shape_pattern", [[1]])
	
	if can_place_multi_tile_at(drop_position, shape_pattern):
		place_multi_tile_at_position(tile_data, drop_position, shape_pattern)
		update_board_visual()
		check_board_completion()

		# 投放成功後記錄到 drop_history
		drop_history.append({
			"tile_data": tile_data.duplicate(), 
			"pos": drop_position,
			"shape_pattern": shape_pattern
		})

		# 投放成功後自動移除 BattleTile 實例（如果有）
		if tile_data.has("__tile_instance") and is_instance_valid(tile_data["__tile_instance"]):
			tile_data["__tile_instance"].queue_free()

# 在指定位置放置多格圖塊
func place_multi_tile_at_position(tile_data: Dictionary, base_pos: Vector2i, shape_pattern: Array):
	var positions = get_multi_tile_positions(base_pos, shape_pattern)
	
	# 將圖塊數據放置到所有相關位置
	for pos in positions:
		placed_tiles[pos] = tile_data.duplicate()
		
		# 更新視覺效果
		var cell_index = pos.y * board_size + pos.x
		if cell_index >= 0 and cell_index < grid_cells.size():
			var cell = grid_cells[cell_index]
			update_cell_visual(cell, tile_data)
	
	print("[BattleBoard] 多格圖塊已放置：", tile_data.get("name", {}).get("zh", "未知"), " 佔用位置：", positions)
# 撤銷最後一次投放（支援多格圖塊）
func undo_last_tile_drop():
	if drop_history.size() == 0:
		print("[BattleBoard] 無投放紀錄可撤銷")
		return

	# 停止任何進行中的動畫
	stop_all_animations()

	var last = drop_history.pop_back()
	var base_pos = last["pos"]
	var tile_data = last["tile_data"]
	var shape_pattern = last.get("shape_pattern", [[1]])

	# 獲取所有佔用的位置並移除
	var positions = get_multi_tile_positions(base_pos, shape_pattern)
	for pos in positions:
		if placed_tiles.has(pos):
			placed_tiles.erase(pos)
			var cell_index = pos.y * board_size + pos.x
			if cell_index < grid_cells.size():
				var cell = grid_cells[cell_index]
				reset_cell_visual(cell, cell_index)

	# 重新生成 BattleTile 並放回原位
	if tile_data.has("block_id"):
		var new_tile = BattleTile.create_from_block_data(tile_data["block_id"])
		new_tile.size = cell_size
		# 放回棋盤下方（或自訂位置）
		new_tile.position = global_position + Vector2(0, board_size * cell_size.y + 40)
		get_tree().current_scene.add_child(new_tile)
	
	print("[BattleBoard] 已撤銷多格圖塊：", tile_data.get("name", {}).get("zh", "未知"))

# 根據滑鼠位置找到對應的格子位置
func find_drop_position_from_mouse() -> Vector2i:
	var mouse_pos = get_global_mouse_position()
	var local_mouse_pos = mouse_pos - global_position
	
	# 計算對應的格子座標
	var cell_x = int(local_mouse_pos.x / cell_size.x)
	var cell_y = int(local_mouse_pos.y / cell_size.y)
	
	# 檢查是否在有效範圍內
	if cell_x >= 0 and cell_x < board_size and cell_y >= 0 and cell_y < board_size:
		return Vector2i(cell_x, cell_y)
	
	return Vector2i(-1, -1)  # 超出範圍

# 找到最適合的投放位置（備用方法）
func find_best_drop_position() -> Vector2i:
	# 簡單策略：找第一個空位置
	for y in range(board_size):
		for x in range(board_size):
			var pos = Vector2i(x, y)
			if not placed_tiles.has(pos):
				return pos
	
	return Vector2i(-1, -1)  # 沒有空位置

# 在指定位置放置方塊
func place_tile_at_position(tile_data: Dictionary, pos: Vector2i):
	placed_tiles[pos] = tile_data
	
	# 更新對應格子的視覺效果
	var cell_index = pos.y * board_size + pos.x
	if cell_index < grid_cells.size():
		var cell = grid_cells[cell_index]
		update_cell_visual(cell, tile_data)
	
	print("[BattleBoard] 方塊已放置：", tile_data.get("element", "unknown"), " 在位置 (", pos.x, ",", pos.y, ")")

# 更新格子的視覺效果
func update_cell_visual(cell: Control, tile_data: Dictionary):
	# 獲取方塊屬性
	var element = tile_data.get("element", "neutral")
	var bonus_value = tile_data.get("bonus_value", 1)

	# 重設格子 scale，避免多次投放導致變大
	cell.scale = Vector2(1, 1)

	# 設置格子顏色
	var element_color = get_element_color(element)
	var border_color = get_element_border_color(element)
	var style_box = create_cell_style(element_color, border_color, 10, 3)
	cell.add_theme_stylebox_override("panel", style_box)
	
	# 確保樣式立即應用
	cell.queue_redraw()
	
	print("[BattleBoard] 更新格子視覺：", element, " 顏色：", element_color)

	# 更新格子內的標籤
	var label = cell.get_child(0) as Label
	if label:
		label.text = get_element_display_name(element) + "\n+" + str(bonus_value)
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color.WHITE)
	
	print("[BattleBoard] 格子顏色已更新 - 屬性:", element, " 顏色:", element_color, " 邊框:", border_color)

# === 棋盤邏輯 ===

# 更新整體棋盤視覺
func update_board_visual():
	# 這裡可以添加整體棋盤的視覺更新邏輯
	pass

# 檢查棋盤完成狀態
func check_board_completion():
	var total_cells = board_size * board_size
	var filled_cells = placed_tiles.size()
	
	print("[BattleBoard] 棋盤狀態：", filled_cells, "/", total_cells, " 已填滿")
	
	if filled_cells == total_cells:
		on_board_completed()
	elif filled_cells >= 3:  # 當放置3個或以上方塊時
		calculate_combo_damage()

# 棋盤完成時的處理
func on_board_completed():
	print("[BattleBoard] 棋盤已完成！")
	
	# 計算最終傷害
	var total_damage = calculate_total_damage()
	print("[BattleBoard] 總傷害：", total_damage)
	
	# 播放完成動畫
	play_completion_animation()
	
	# 發送完成訊號
	# EventBus.board_completed.emit(placed_tiles, total_damage)

# 計算連擊傷害
func calculate_combo_damage() -> int:
	var element_counts = {}
	var total_damage = 0
	
	# 統計各屬性方塊數量
	for pos in placed_tiles:
		var tile_data = placed_tiles[pos]
		var element = tile_data.get("element", "neutral")
		var bonus = tile_data.get("bonus_value", 1)
		
		if not element_counts.has(element):
			element_counts[element] = {"count": 0, "total_bonus": 0}
		
		element_counts[element].count += 1
		element_counts[element].total_bonus += bonus
	
	# 計算連擊加成
	for element in element_counts:
		var data = element_counts[element]
		var combo_multiplier = 1.0 + (data.count - 1) * 0.5  # 每額外方塊 +50% 傷害
		var element_damage = data.total_bonus * combo_multiplier
		total_damage += int(element_damage)
		
		print("[BattleBoard] ", element, " 屬性：", data.count, " 個方塊，傷害 ", element_damage)
	
	return total_damage

# 計算總傷害
func calculate_total_damage() -> int:
	return calculate_combo_damage()

# 播放完成動畫
func play_completion_animation():
	# 整體棋盤發光效果
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.3)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# 粒子效果
	create_completion_particles()

# 創建完成粒子效果
func create_completion_particles():
	var center_pos = global_position + size / 2
	
	for i in range(20):
		var particle = ColorRect.new()
		particle.size = Vector2(8, 8)
		particle.color = Color(1, 1, 0.3, 0.9)  # 金色粒子
		particle.position = center_pos
		get_tree().current_scene.add_child(particle)
		
		# 星形擴散
		var angle = i * PI * 2 / 20
		var direction = Vector2(cos(angle), sin(angle))
		var distance = 120
		
		var tween = create_tween()
		tween.tween_property(particle, "position", center_pos + direction * distance, 0.8)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.8)
		tween.tween_callback(particle.queue_free)

# === 清理和重置 ===

# 清空棋盤
func clear_board():
	# 停止任何進行中的動畫
	stop_all_animations()
	
	placed_tiles.clear()
	
	# 重置所有格子的視覺效果
	for i in range(grid_cells.size()):
		var cell = grid_cells[i]
		reset_cell_visual(cell, i)
	
	print("[BattleBoard] 棋盤已清空")

# 重置格子視覺效果
func reset_cell_visual(cell: Control, index: int):
	# 恢復空格子樣式
	var style_box = create_cell_style(
		Color(0.1, 0.1, 0.2, 0.8),    # 深藍色半透明
		Color(0.3, 0.3, 0.5, 0.6),    # 邊框顏色
		10,  # 圓角半徑
		2    # 邊框寬度
	)
	cell.add_theme_stylebox_override("panel", style_box)
	
	# 恢復格子編號
	var label = cell.get_child(0) as Label
	if label:
		label.text = str(index)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.5))
	
	print("[BattleBoard] 格子已重置為空狀態 - 編號:", index)

# === 樣式輔助方法 ===

# 創建基本格子樣式
func create_cell_style(bg_color: Color, border_color: Color, corner_radius: int = 10, border_width: int = 2) -> StyleBoxFlat:
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = bg_color
	style_box.corner_radius_top_left = corner_radius
	style_box.corner_radius_top_right = corner_radius
	style_box.corner_radius_bottom_left = corner_radius
	style_box.corner_radius_bottom_right = corner_radius
	style_box.border_width_left = border_width
	style_box.border_width_right = border_width
	style_box.border_width_top = border_width
	style_box.border_width_bottom = border_width
	style_box.border_color = border_color
	return style_box



# === 輔助方法 ===

# 獲取棋盤提示文字
func get_board_hint_text() -> String:
	var filled = placed_tiles.size()
	var total = board_size * board_size
	return "戰鬥棋盤 " + str(filled) + "/" + str(total)

# 獲取屬性顏色（與 BattleTile 一致）
func get_element_color(element: String) -> Color:
	match element:
		"fire":
			return Color(1.0, 0.267, 0.267, 0.9)
		"water":
			return Color(0.267, 0.667, 1.0, 0.9)
		"grass":
			return Color(0.267, 0.8, 0.267, 0.9)
		"light":
			return Color(1.0, 1.0, 0.6, 0.9)
		"dark":
			return Color(0.4, 0.267, 0.6, 0.9)
		_:
			return Color(0.5, 0.5, 0.5, 0.9)

# 獲取屬性邊框顏色
func get_element_border_color(element: String) -> Color:
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
func get_element_display_name(element: String) -> String:
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
