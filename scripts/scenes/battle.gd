extends Control

func _ready():
	print("[BattleScene] 載入戰鬥場景，主節點：", self, " parent：", get_parent())
	EventBus.update_battle_ui.connect(update_battle_ui)
	setup_ui()

func setup_ui():
	#設置為全屏控制
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


	create_background_area()
	#不用創造上半部分的資訊區域，因為有_setup_enemies會處理
	#也不用創建棋盤區域，因為有_setup_board_ui會處理
	create_control_buttons()

func create_background_area():
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0.1, 0.1, 0.2, 1.0)
	add_child(bg)

func create_control_buttons():
	# 右下角：結束回合、技能
	var bottom_right_container = HBoxContainer.new()
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

func update_battle_ui(level_data: Dictionary):
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
	print("[BattleScene] 設置戰鬥棋盤UI，大小：", board_size)
	#等等再實作

func _setup_enemies(enemies: Array):
	#這裡有兩個部分：一個是建立敵人的物件(必須，因為需要存放current_hp等資料)
	#另一個是顯示在UI上，對於邏輯比較不需要，可以用一個方塊代表就好了
	pass

func _on_end_turn_pressed():
	#可以新增一個確認視窗，之後再說
	pass

func _on_skill_pressed():
	#施放技能，需要看能量是否足夠，反正也是之後再說
	pass
