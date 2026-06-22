# battle.gd - 重構版本，只負責UI顯示，不處理遊戲邏輯
extends Control

var bottom_right_container: HBoxContainer
var tile_container: ScrollContainer
var hand_hbox: HBoxContainer
var drop_board: BattleBoard

var mana_bar_fill: ColorRect
var mana_label: Label
var mana_bar_max_width: float = 360.0
var skill_button: Button
var _hero_scene: Node = null
var _target_arrow: Label = null


func _ready():
	print("[BattleScene] 載入戰鬥場景，主節點：", self, " parent：", get_parent())
	
	# 連接狀態機發送的UI更新信號
	EventBus.setup_battle_ui.connect(setup_battle_ui)
	EventBus.setup_deck_ui.connect(setup_deck_ui) 
	EventBus.hand_updated.connect(update_hand_display)
	EventBus.ui_damage_animation_requested.connect(_on_ui_damage_animation_requested)
	EventBus.ui_lock_end_turn_button.connect(_on_ui_lock_end_turn_button)
	EventBus.ui_unlock_end_turn_button.connect(_on_ui_unlock_end_turn_button)
	EventBus.ui_load_next_enemy_wave.connect(_on_ui_load_next_enemy_wave)
	EventBus.battle_target_changed.connect(_on_battle_target_changed)

	# 初始化UI
	setup_ui()
	_create_target_arrow()

func setup_ui():
	# 設置為全屏控制
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	create_background_area()
	create_control_buttons()

func create_background_area():
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0.1, 0.1, 0.2, 1.0)
	add_child(bg)

func create_control_buttons():
	# 右下角：結束回合、技能
	bottom_right_container = HBoxContainer.new()
	bottom_right_container.add_theme_constant_override("separation", 20)
	# Anchor to bottom right
	bottom_right_container.anchor_left = 1.0
	bottom_right_container.anchor_top = 1.0
	bottom_right_container.anchor_right = 1.0
	bottom_right_container.anchor_bottom = 1.0
	# Offset from bottom right
	bottom_right_container.offset_right = -40
	bottom_right_container.offset_bottom = -40
	bottom_right_container.offset_left = -520 # 兩個按鈕+間距寬度預留
	bottom_right_container.offset_top = -100
	add_child(bottom_right_container)

	var end_turn_button = Button.new()
	end_turn_button.text = "結束回合"
	end_turn_button.custom_minimum_size = Vector2(240, 80) # 放大兩倍
	end_turn_button.name = "end_turn_button"
	end_turn_button.connect("pressed", _on_end_turn_pressed)
	bottom_right_container.add_child(end_turn_button)

	skill_button = Button.new()
	skill_button.text = "技能"
	skill_button.custom_minimum_size = Vector2(240, 80) # 放大兩倍
	skill_button.connect("pressed", _on_skill_pressed)
	bottom_right_container.add_child(skill_button)

	# 右上角：暫停
	var pause_button = Button.new()
	pause_button.text = "暫停"
	pause_button.custom_minimum_size = Vector2(240, 80) # 放大兩倍
	# Anchor to top right
	pause_button.anchor_left = 1.0
	pause_button.anchor_top = 0.0
	pause_button.anchor_right = 1.0
	pause_button.anchor_bottom = 0.0
	pause_button.offset_right = -40 # 右側預留空間，與下方一致
	pause_button.offset_top = 40
	pause_button.offset_left = -280 # 按鈕寬度+右側預留空間
	pause_button.offset_bottom = 120
	add_child(pause_button)

	_create_mana_bar()

func _create_mana_bar():
	# 底色背景（深藍）
	var bg = ColorRect.new()
	bg.anchor_left = 1.0
	bg.anchor_top = 1.0
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_left = -400.0
	bg.offset_right = -40.0
	bg.offset_top = -120.0
	bg.offset_bottom = -108.0
	bg.color = Color(0.05, 0.1, 0.3, 1.0)
	bg.name = "ManaBarBg"
	add_child(bg)

	# 填充條（亮藍）
	mana_bar_fill = ColorRect.new()
	mana_bar_fill.position = Vector2.ZERO
	mana_bar_fill.size = Vector2(mana_bar_max_width, 12.0)
	mana_bar_fill.color = Color(0.2, 0.5, 1.0, 1.0)
	mana_bar_fill.name = "ManaBarFill"
	bg.add_child(mana_bar_fill)

	# 數字標籤（bar 上方）
	mana_label = Label.new()
	mana_label.position = Vector2(0, -38)
	mana_label.size = Vector2(mana_bar_max_width, 34)
	mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mana_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mana_label.add_theme_font_size_override("font_size", 33)
	mana_label.modulate = Color(0.6, 0.8, 1.0, 1.0)
	mana_label.name = "ManaLabel"
	bg.add_child(mana_label)

func update_mana_bar(current: int, maximum: int):
	if not mana_bar_fill:
		return
	var ratio = float(current) / float(maximum) if maximum > 0 else 0.0
	mana_bar_fill.size.x = mana_bar_max_width * ratio
	if mana_label:
		mana_label.text = "%d/%d" % [current, maximum]

func update_skill_button_state():
	if not skill_button:
		return
	var can_cast = false
	if _hero_scene and _hero_scene.skill_component:
		can_cast = _hero_scene.skill_component.can_cast_active_skill()
	skill_button.disabled = not can_cast

func _on_active_skill_state_changed(can_cast: bool):
	if skill_button:
		skill_button.disabled = not can_cast

# 狀態機調用的UI設置函數
func setup_battle_ui(level_data: Dictionary, enemies_scenes: Array = [], hero_scene: Node = null) -> void:
	print("[BattleScene] 收到更新戰鬥UI的請求，關卡資料ID：", level_data.get("level_id", ""))

	# 設置棋盤UI
	if level_data.has("board"):
		var board_data: Dictionary = level_data["board"]
		var board_size: Vector2 = Vector2(board_data.get("width", 3), board_data.get("height", 3))
		var board_blocked: Array = board_data.get("blocked_positions", [])
		_setup_board_ui(board_size, board_blocked)

	# 顯示敵人（敵人場景已由狀態機創建）
	for enemy in enemies_scenes:
		if enemy and not enemy.get_parent():
			add_child(enemy)
			print("[BattleScene] 添加敵人場景到UI: ", enemy.name)

	# 顯示玩家(英雄)
	if hero_scene and not hero_scene.get_parent():
		add_child(hero_scene)
		print("[BattleScene] 添加英雄場景到UI: ", hero_scene.name)

	# 儲存 hero 引用，連接信號
	if hero_scene:
		_hero_scene = hero_scene
		if hero_scene.has_signal("mana_changed") and not hero_scene.mana_changed.is_connected(func(c, m): update_mana_bar(c, m)):
			hero_scene.mana_changed.connect(func(c, m): update_mana_bar(c, m))
		if hero_scene.has_signal("active_skill_state_changed") and not hero_scene.active_skill_state_changed.is_connected(_on_active_skill_state_changed):
			hero_scene.active_skill_state_changed.connect(_on_active_skill_state_changed)
		update_mana_bar(hero_scene.current_mana, hero_scene.max_mana)
		update_skill_button_state()

	EventBus.battle_ui_update_complete.emit()

func _setup_board_ui(board_size: Vector2, board_blocked: Array):
	# 先加底色區塊
	var board_bg = ColorRect.new()
	board_bg.position = Vector2(240, 750)
	board_bg.size = Vector2(600, 600)
	board_bg.color = Color(0.2, 0.2, 0.3, 1.0)
	add_child(board_bg)

	# 再加棋盤
	drop_board = BattleBoard.new()
	drop_board.position = Vector2(240, 750)
	add_child(drop_board)

	drop_board.tile_dropped.connect(_on_tile_dropped)

# 狀態機調用的手牌設置函數
func setup_deck_ui(current_hands: Array):
	print("[BattleScene] 收到設置手牌 UI 的請求，起手牌：", current_hands)
	update_hand_display(current_hands)

# 更新手牌顯示（純UI功能）
func update_hand_display(current_hands: Array):
	# 有可能沒有tile_container
	if not tile_container:
		tile_container = ScrollContainer.new()
		tile_container.position = Vector2(40, 1420)
		tile_container.size = Vector2(1000, 240)
		tile_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		tile_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		add_child(tile_container)

	# 清空內容容器
	if tile_container.get_child_count() > 0:
		var old_hbox = tile_container.get_child(0)
		old_hbox.queue_free()

	hand_hbox = HBoxContainer.new()
	hand_hbox.name = "hand_hbox"
	hand_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_hbox.size_flags_vertical = Control.SIZE_FILL
	hand_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_hbox.add_theme_constant_override("separation", 20)
	tile_container.add_child(hand_hbox)

	print("[BattleScene] 更新手牌顯示，當前手牌：", current_hands)
	for tile_id in current_hands:
		var tile = BattleTile.create_from_id(tile_id)
		tile.size = Vector2(200, 200)
		tile.name = "BattleTile_" + tile_id
		hand_hbox.add_child(tile)

# UI事件處理（只負責UI，不處理遊戲邏輯）
func _on_end_turn_pressed():
	"""結束回合按鈕被按下 - 只處理UI相關邏輯"""
	# 計算棋盤總傷害（這是UI功能）
	var board_was_full: bool = false
	if drop_board:
		var total_cells = drop_board.board_size * drop_board.board_size
		board_was_full = drop_board.placed_tiles.size() == total_cells
		print("[BattleScene] 棋盤填滿：", board_was_full, "（", drop_board.placed_tiles.size(), "/", total_cells, "）")
		drop_board.clear_board()
	
	# 獲取UI中剩餘的卡片信息
	var cards_in_ui = []
	if hand_hbox:
		for tile in hand_hbox.get_children():
			if tile.has_method("get_block_id") and tile.get_block_id():
				cards_in_ui.append(tile.get_block_id())
			elif tile.block_id:
				cards_in_ui.append(tile.block_id)
	
	#要鎖住回合結束按鈕，避免重複點擊
	_on_ui_lock_end_turn_button()

	# 通知狀態機回合結束（傳遞UI數據）
	EventBus.turn_ended.emit(cards_in_ui, board_was_full)

func _on_skill_pressed():
	EventBus.skill_cast_requested.emit()

func _on_tile_dropped(tile_data: Dictionary):
	"""棋盤放置方塊事件 - 只負責UI反饋"""
	print("[BattleScene] 方塊已放置到棋盤：", tile_data)
	# 通知狀態機方塊已放置（由狀態機處理遊戲邏輯）
	EventBus.block_placed.emit(null, Vector2.ZERO)

func _on_ui_damage_animation_requested(target: Node, amount: int, damage_type: String):
	"""處理UI傷害動畫請求"""
	#print("[BattleScene] 收到UI傷害動畫請求，目標：", target, " 傷害量：", amount, " 類型：", damage_type)
	#跳出傷害數字動畫
	var damage_label = Label.new()
	damage_label.global_position = target.global_position
	damage_label.text = str(amount)
	damage_label.z_index = 5
	damage_label.label_settings = LabelSettings.new()

	var color: Color = Color.WHITE
	match damage_type:
		"fire":
			color = Color(1, 0.5, 0, 1) # Orange for fire
		"water":
			color = Color(0, 0.5, 1, 1) # Blue for water
		"grass":
			color = Color(0, 1, 0.5, 1) # Green for grass
		"light":
			color = Color(1, 1, 0.8, 1) # Light yellow for light
		"dark":
			color = Color(0.5, 0, 0.5, 1) # Purple for dark
		_:
			color = Color(1, 1, 1, 1) # White as default

	damage_label.label_settings.font_color = color
	damage_label.label_settings.font_size = 48
	damage_label.label_settings.outline_color = Color.BLACK
	damage_label.label_settings.outline_size = 2
	
	call_deferred("add_child", damage_label)

	await damage_label.resized
	damage_label.pivot_offset = Vector2(damage_label.size / 2)

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		damage_label, "position:y", damage_label.position.y - 48, 0.25
	).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		damage_label, "position:y", damage_label.position.y, 0.5
	).set_ease(Tween.EASE_IN).set_delay(0.25)

	tween.tween_property(
		damage_label, "scale", Vector2.ZERO, 0.5
	).set_ease(Tween.EASE_IN).set_delay(0.5)

func _on_ui_lock_end_turn_button():
	"""鎖住結束回合按鈕"""
	var end_turn_button = bottom_right_container.get_node("end_turn_button")
	if end_turn_button:
		end_turn_button.disabled = true

func _on_ui_unlock_end_turn_button():
	"""解鎖結束回合按鈕"""
	var end_turn_button = bottom_right_container.get_node("end_turn_button")
	if end_turn_button:
		end_turn_button.disabled = false

func _on_ui_load_next_enemy_wave(enemies: Array):
	for enemy_scene in get_children():
		if enemy_scene.is_in_group("enemy"):
			enemy_scene.queue_free()
	for enemy in enemies:
		if enemy and not enemy.get_parent():
			add_child(enemy)
			print("[BattleScene] 添加第二波敵人：", enemy.name)

func _create_target_arrow():
	_target_arrow = Label.new()
	_target_arrow.text = "▲"
	_target_arrow.add_theme_font_size_override("font_size", 32)
	_target_arrow.modulate = Color(1.0, 0.9, 0.0, 1.0)
	_target_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_arrow.visible = false
	_target_arrow.name = "TargetArrow"
	add_child(_target_arrow)

func _on_battle_target_changed(enemy: Node):
	if not _target_arrow:
		return
	if enemy == null:
		_target_arrow.visible = false
		return
	_target_arrow.visible = true
	_target_arrow.position = enemy.position + Vector2(-16, 80)