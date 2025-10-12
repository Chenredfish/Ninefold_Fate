# DragDropManager.gd - 拖放系統核心管理器
# 這是一個 AutoLoad 單例，負責統一管理整個遊戲的拖放互動
extends Node

# === 訊號系統 ===
signal tile_drag_started(tile_data: Dictionary, source_scene: String)
signal tile_drag_ended(tile_data: Dictionary, drop_zone, success: bool)
signal navigation_requested(target_scene: String, tile_type: String)

# === 狀態變數 ===
var current_dragging_tile = null  # 當前拖拽的圖塊
var valid_drop_zones: Array = []  # 有效的投放區域列表
var drag_preview: Control = null  # 拖拽預覽節點
var drag_offset: Vector2 = Vector2.ZERO  # 拖拽偏移量

func _ready():
	print("[DragDropManager] 拖放系統已初始化")

# === 拖拽控制方法 ===

# 開始拖拽
func start_drag(tile, global_pos: Vector2) -> bool:
	if current_dragging_tile != null:
		print("[DragDropManager] 警告：已有圖塊正在拖拽中")
		return false
	
	current_dragging_tile = tile
	drag_offset = tile.global_position - global_pos
	
	# 創建拖拽預覽
	create_drag_preview(tile)
	
	# 設置原圖塊為半透明
	tile.modulate.a = 0.5
	
	# 發送開始拖拽訊號
	var scene_path = get_tree().current_scene.scene_file_path
	tile_drag_started.emit(tile.tile_data, scene_path)
	
	print("[DragDropManager] 開始拖拽：", tile.tile_type)
	return true

# 更新拖拽位置
func update_drag(global_pos: Vector2):
	if drag_preview == null:
		return
	
	drag_preview.global_position = global_pos + drag_offset
	
	# 檢測碰撞的投放區域
	var drop_zone = find_drop_zone_at_position(global_pos)
	update_drop_zone_highlights(drop_zone)

# 結束拖拽
func end_drag(global_pos: Vector2) -> bool:
	if current_dragging_tile == null:
		print("[DragDropManager] 警告：沒有正在拖拽的圖塊")
		return false
	
	var drop_zone = find_drop_zone_at_position(global_pos)
	var success = false
	
	if drop_zone != null and can_drop_on_zone(current_dragging_tile, drop_zone):
		# 成功投放
		success = true
		perform_drop_action(current_dragging_tile, drop_zone)
		play_drop_success_animation()
		print("[DragDropManager] 投放成功")
	else:
		# 失敗，回彈動畫
		play_drop_fail_animation()
		print("[DragDropManager] 投放失敗，執行回彈")
	
	# 發送結束拖拽訊號
	tile_drag_ended.emit(current_dragging_tile.tile_data, drop_zone, success)
	
	# 清理拖拽狀態
	cleanup_drag()
	current_dragging_tile = null
	
	return success

# === 拖拽預覽管理 ===

# 創建拖拽預覽
func create_drag_preview(original_tile):
	drag_preview = Control.new()
	drag_preview.size = original_tile.size
	drag_preview.modulate.a = 0.9
	drag_preview.z_index = 100  # 確保在最頂層
	
	# 創建預覽背景
	var preview_bg = ColorRect.new()
	preview_bg.size = original_tile.size
	preview_bg.color = Color(0.8, 0.8, 1.0, 0.8)  # 淺藍色半透明
	
	# 添加陰影效果
	var shadow = ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.size = original_tile.size + Vector2(12, 12)
	shadow.position = Vector2(-6, -6)
	shadow.z_index = -1
	
	drag_preview.add_child(shadow)
	drag_preview.add_child(preview_bg)
	
	# 添加圖塊標籤（顯示類型）
	if original_tile.has_method("get_display_text"):
		var label = Label.new()
		label.text = original_tile.get_display_text()
		label.size = original_tile.size
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		drag_preview.add_child(label)
	
	# 縮放效果
	drag_preview.scale = Vector2(1.1, 1.1)
	
	# 添加到場景樹
	get_tree().current_scene.add_child(drag_preview)

# === 投放區域管理 ===

# 尋找指定位置的投放區域
func find_drop_zone_at_position(global_pos: Vector2):
	for zone in valid_drop_zones:
		if zone.get_global_rect().has_point(global_pos):
			return zone
	return null

# 更新投放區域高亮效果
func update_drop_zone_highlights(hovered_zone):
	for zone in valid_drop_zones:
		if zone == hovered_zone:
			if can_drop_on_zone(current_dragging_tile, zone):
				zone.set_highlight_valid(true)
			else:
				zone.set_highlight_invalid(true)
		else:
			zone.clear_highlight()

# 檢查是否可以投放到指定區域
func can_drop_on_zone(tile, zone) -> bool:
	return zone.can_accept_tile(tile)

# === 投放動作處理 ===

# 執行投放動作
func perform_drop_action(tile, zone):
	zone.on_tile_dropped(tile.tile_data)
	
	# 處理導航圖塊的特殊邏輯
	if tile.has_method("get_target_scene_path"):
		var target_path = tile.get_target_scene_path()
		if target_path != "":
			navigation_requested.emit(target_path, tile.tile_type)

# === 動畫效果 ===

# 播放成功投放動畫
func play_drop_success_animation():
	if drag_preview == null:
		return
	
	# 縮放動畫：1.2 → 1.0，持續 0.3秒
	var tween = create_tween()
	tween.tween_property(drag_preview, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(drag_preview, "scale", Vector2(1.0, 1.0), 0.2)
	
	# 創建成功粒子效果
	create_success_particles(drag_preview.global_position + drag_preview.size / 2)

# 播放失敗回彈動畫
func play_drop_fail_animation():
	if current_dragging_tile == null or drag_preview == null:
		return
	
	# 回彈動畫
	var tween = create_tween()
	var original_pos = current_dragging_tile.global_position
	var current_pos = drag_preview.global_position
	
	# 彈性回到原位置
	tween.tween_method(
		func(pos): if drag_preview: drag_preview.global_position = pos,
		current_pos,
		original_pos + drag_offset,
		0.4
	)
	tween.tween_callback(cleanup_drag)

# 創建成功粒子效果
func create_success_particles(position: Vector2):
	for i in range(15):
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = Color(1, 1, 0.2, 0.8)  # 金黃色
		particle.position = position
		get_tree().current_scene.add_child(particle)
		
		# 隨機方向擴散
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var distance = randf_range(30, 80)
		
		var tween = create_tween()
		tween.tween_property(particle, "position", position + direction * distance, 0.6)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.6)
		tween.tween_callback(particle.queue_free)

# === 清理方法 ===

# 清理拖拽狀態
func cleanup_drag():
	if current_dragging_tile:
		current_dragging_tile.modulate.a = 1.0
	
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null
	
	# 清除所有投放區域的高亮
	for zone in valid_drop_zones:
		zone.clear_highlight()

# === 投放區域註冊 ===

# 註冊投放區域
func register_drop_zone(zone):
	if zone not in valid_drop_zones:
		valid_drop_zones.append(zone)
		print("[DragDropManager] 註冊投放區域：", zone.zone_type)

# 取消註冊投放區域
func unregister_drop_zone(zone):
	if zone in valid_drop_zones:
		valid_drop_zones.erase(zone)
		print("[DragDropManager] 取消註冊投放區域：", zone.zone_type)

# === 除錯方法 ===

# 獲取當前狀態資訊
func get_debug_info() -> Dictionary:
	return {
		"is_dragging": current_dragging_tile != null,
		"dragging_tile_type": current_dragging_tile.tile_type if current_dragging_tile else "none",
		"drop_zones_count": valid_drop_zones.size(),
		"has_preview": drag_preview != null
	}