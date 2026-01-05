extends Control

var bottom_right_container:HBoxContainer
var tile_container:ScrollContainer
var hand_hbox:HBoxContainer
var drop_board:BattleBoard

func _ready():
	print("[BattleScene] 載入戰鬥場景，主節點：", self, " parent：", get_parent())
	# 連接狀態機發送的UI更新信號
	EventBus.setup_battle_ui.connect(setup_battle_ui)
	EventBus.setup_deck_ui.connect(setup_deck_ui)
	EventBus.hand_updated.connect(update_hand_display)
	# 初始化UI
	setup_ui()

func setup_ui():
	#設置為全屏控制
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


	create_background_area()
	#不用創造上半部分的資訊區域，因為有_setup_enemies會處理
	#也不用創建棋盤區域，因為有_setup_board_ui會處理
	#還要創造tile，他應該會根據deck動態生成，類似敵人和棋盤的處理方式
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

func setup_battle_ui(level_data: Dictionary):
	print("[BattleScene] 收到更新戰鬥UI的請求，關卡資料ID：", level_data.get("level_id", ""))

	if level_data.size() == 0:
		print("[BattleScene] 錯誤：關卡資料為空，無法更新UI")
		return
	
	if level_data.has("board"):
		var board_data:Dictionary = level_data["board"]
		#預設是3x3的棋盤
		var board_size:Vector2 = Vector2(board_data.get("width", 3), board_data.get("height", 3))
		#不過目前還沒用到blocked_positions
		var board_blocked:Array = board_data.get("blocked_positions", [])
		_setup_board_ui(board_size, board_blocked)
	else:
		print("[BattleScene] 警告：關卡資料中缺少board資訊，無法設置棋盤UI")

	if level_data.has("enemies"):
		var enemies:Array = level_data.get("enemies")
		_setup_enemies(enemies)
	else:
		var enemies:Array = []
		print("[BattleScene] 警告：關卡資料中缺少enemies資訊，無法設置敵人UI")

	EventBus.emit_signal("battle_ui_update_complete")

func _setup_board_ui(board_size: Vector2, board_blocked: Array):
	# 先加底色區塊
	var board_bg = ColorRect.new()
	board_bg.position = Vector2(240, 750)
	board_bg.size = Vector2(600, 600)
	board_bg.color = Color(0.2, 0.2, 0.3, 1.0)
	add_child(board_bg)

	#再加棋盤
	drop_board = BattleBoard.new()
	drop_board.position = Vector2(240, 750)
	add_child(drop_board)

	drop_board.tile_dropped.connect(_on_tile_dropped)

func setup_deck_ui(current_hands: Array):
	print("[BattleScene] 收到設置手牌 UI 的請求，起手牌：", current_hands)
	update_hand_display(current_hands)

func update_hand_display(current_hands: Array):
	#有可能沒有tile_container
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

	print("[更新手牌區域] 當前手牌：", current_hands)
	for tile_id in current_hands:
		var tile = BattleTile.create_from_id(tile_id)
		tile.size = Vector2(200, 200)
		tile.name = "BattleTile_" + tile_id
		hand_hbox.add_child(tile)


func _on_end_turn_pressed():
	"""結束回合按鈕被按下"""
	var total_value: int = drop_board.calculate_total_damage()
	print("[BattleScene] 結束回合按鈕被按下,計算棋盤總價值：", total_value)

	if not self.hand_hbox:
		return 
	
	# 先記錄UI中實際還有哪些卡
	var cards_in_ui = []
	for tile in self.hand_hbox.get_children():
		if tile.block_id:
			cards_in_ui.append(tile.block_id)
	
	print("[BattleScene] UI中的卡片：", cards_in_ui)
	print("[BattleScene] 手牌列表：", current_hands)
	
	# 找出被使用的卡片(在手牌中但不在UI中)
	var used_cards = []
	for card_id in current_hands:
		if card_id not in cards_in_ui:
			used_cards.append(card_id)
	
	# 從current_hands移除被使用的卡片
	for card_id in used_cards:
		current_hands.erase(card_id)
		print("[BattleScene] 移除已使用的卡片：", card_id)

	drop_board.clear_board()

	# 補充卡片到4張
	while current_hands.size() < 4:
		# 從deck_data裡找不在手牌中的卡
		var available_cards = []
		for card_id in deck_data:
			if card_id not in current_hands:
				available_cards.append(card_id)
		
		# 如果沒有可用卡片就停止
		if available_cards.is_empty():
			print("[BattleScene] 牌組已空,無法補充更多卡片")
			break
		
		# 隨機抽一張
		var rand_index: int = randi() % available_cards.size()
		var drawn_card = available_cards[rand_index]
		current_hands.append(drawn_card)
		print("[BattleScene] 抽到卡片：", drawn_card)

	print("[BattleScene] 補充後手牌：", current_hands)
	update_tile_container()

	#要鎖住送出結束回合事件，等狀態回到玩家回合再解鎖
	EventBus.emit_signal("turn_ended")


func _on_skill_pressed():
	#施放技能，需要看能量是否足夠，反正也是之後再說
	pass

func _on_tile_dropped(tile_data: Dictionary):
	"""棋盤放置方塊事件 - 只負責UI反饋"""
	print("[BattleScene] 方塊已放置到棋盤：", tile_data)
	# 通知狀態機方塊已放置（由狀態機處理遊戲邏輯）
	EventBus.emit_signal("block_placed", null, Vector2.ZERO)
