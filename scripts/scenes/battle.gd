# battle.gd - 重構版本，只負責UI顯示，不處理遊戲邏輯
extends Control

var bottom_right_container: HBoxContainer
var tile_container: ScrollContainer
var hand_hbox: HBoxContainer
var drop_board: BattleBoard

func _ready():
	print("[BattleScene] 載入戰鬥場景，主節點：", self, " parent：", get_parent())
	
	# 連接狀態機發送的UI更新信號
	EventBus.setup_battle_ui.connect(setup_battle_ui)
	EventBus.setup_deck_ui.connect(setup_deck_ui) 
	EventBus.hand_updated.connect(update_hand_display)
	
	# 初始化UI
	setup_ui()

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
	end_turn_button.connect("pressed", _on_end_turn_pressed)
	bottom_right_container.add_child(end_turn_button)

	var skill_button = Button.new()
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


	EventBus.emit_signal("battle_ui_update_complete")

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
	var total_damage: int = 0
	if drop_board:
		total_damage = drop_board.calculate_total_damage()
		print("[BattleScene] 棋盤計算出的總傷害：", total_damage)
		# 清空棋盤顯示
		drop_board.clear_board()
	
	# 獲取UI中剩餘的卡片信息
	var cards_in_ui = []
	if hand_hbox:
		for tile in hand_hbox.get_children():
			if tile.has_method("get_block_id") and tile.get_block_id():
				cards_in_ui.append(tile.get_block_id())
			elif tile.block_id:
				cards_in_ui.append(tile.block_id)
	
	# 通知狀態機回合結束（傳遞UI數據）
	EventBus.emit_signal("turn_ended", total_damage, cards_in_ui)

func _on_skill_pressed():
	# 施放技能，需要看能量是否足夠，反正也是之後再說
	pass

func _on_tile_dropped(tile_data: Dictionary):
	"""棋盤放置方塊事件 - 只負責UI反饋"""
	print("[BattleScene] 方塊已放置到棋盤：", tile_data)
	# 通知狀態機方塊已放置（由狀態機處理遊戲邏輯）
	EventBus.emit_signal("block_placed", null, Vector2.ZERO)