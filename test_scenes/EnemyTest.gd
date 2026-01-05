# EnemyTest.gd - 敵人系統測試（獨立運行）
extends Node2D

var enemy_instance: Enemy

func _ready():
	print("[EnemyTest] 開始敵人系統測試（獨立模式）")
	
	# 等待 AutoLoad 系統完全初始化
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 檢查並初始化必要的系統
	_check_required_systems()
	
	# 連接 EventBus 事件來監聽敵人創建
	if EventBus:
		EventBus.enemy_spawned.connect(_on_enemy_spawned)
		EventBus.enemy_defeated.connect(_on_enemy_defeated)
		print("[EnemyTest] EventBus 連接成功")
	else:
		print("[EnemyTest] 警告：EventBus 不可用")
	
	# 創建敵人
	_test_enemy_creation()
	
	# 設置測試UI
	_setup_test_ui()

func _check_required_systems():
	"""檢查並報告必要系統的狀態"""
	print("[EnemyTest] 檢查系統狀態:")
	print("  - EventBus: ", "✓" if EventBus else "✗")
	print("  - ResourceManager: ", "✓" if ResourceManager else "✗")
	print("  - StateManager: ", "✓" if StateManager else "✗ (這是正常的，測試不需要)")
	
	# 如果 ResourceManager 不可用，嘗試手動獲取
	if not ResourceManager:
		var rm = get_node_or_null("/root/ResourceManager")
		if rm:
			print("  - ResourceManager 通過路徑獲取成功")
		else:
			print("  - 錯誤：ResourceManager 完全不可用")

func _test_enemy_creation():
	"""測試敵人創建"""
	print("[EnemyTest] 創建水之史萊姆...")
	
	# 使用全局變數或路徑獲取 ResourceManager
	var rm = ResourceManager
	if not rm:
		rm = get_node_or_null("/root/ResourceManager")
	
	if rm:
		print("[EnemyTest] ResourceManager 可用，開始創建敵人")
		enemy_instance = rm.create_enemy("E001")
		if enemy_instance:
			add_child(enemy_instance)
			enemy_instance.position = Vector2(200, 300)
			print("[EnemyTest] 敵人創建成功:", enemy_instance.enemy_name)
			print("[EnemyTest] 敵人屬性:", enemy_instance.element)
			print("[EnemyTest] 敵人血量:", enemy_instance.current_hp, "/", enemy_instance.base_hp)
		else:
			print("[EnemyTest] 敵人創建失敗")
	else:
		print("[EnemyTest] 錯誤：ResourceManager 不可用，無法創建敵人")
		# 創建一個測試用的佔位符敵人
		_create_fallback_enemy()

func _setup_test_ui():
	"""設置測試用的UI按鈕"""
	var ui_container = Control.new()
	ui_container.name = "TestUI"
	add_child(ui_container)
	
	# 攻擊按鈕
	var attack_button = Button.new()
	attack_button.text = "攻擊敵人 (50傷害)"
	attack_button.position = Vector2(50, 50)
	attack_button.size = Vector2(150, 40)
	attack_button.pressed.connect(_on_attack_button_pressed)
	ui_container.add_child(attack_button)
	
	# 測試倒數按鈕
	var countdown_button = Button.new()
	countdown_button.text = "手動倒數"
	countdown_button.position = Vector2(50, 100)
	countdown_button.size = Vector2(150, 40)
	countdown_button.pressed.connect(_on_countdown_button_pressed)
	ui_container.add_child(countdown_button)
	
	# 狀態顯示標籤
	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "等待敵人創建..."
	info_label.position = Vector2(50, 150)
	info_label.size = Vector2(300, 100)
	ui_container.add_child(info_label)
	
	# 每秒更新資訊顯示
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_info_display)
	timer.autostart = true
	add_child(timer)

func _on_attack_button_pressed():
	"""攻擊按鈕按下"""
	if enemy_instance and enemy_instance.is_alive:
		print("[EnemyTest] 對敵人造成50點傷害")
		enemy_instance.take_damage(50, "fire")
	else:
		print("[EnemyTest] 沒有可攻擊的敵人")

func _on_countdown_button_pressed():
	"""倒數按鈕按下"""
	if enemy_instance and enemy_instance.is_alive:
		print("[EnemyTest] 手動觸發倒數")
		enemy_instance.tick_countdown()
	else:
		print("[EnemyTest] 沒有活著的敵人")

func _update_info_display():
	"""更新資訊顯示"""
	var info_label = get_node_or_null("TestUI/InfoLabel")
	if info_label and enemy_instance:
		var info = enemy_instance.get_enemy_info()
		info_label.text = "敵人狀態:\n名稱: %s\n血量: %d/%d\n倒數: %d/%d\n存活: %s" % [
			info.name,
			info.current_hp,
			info.max_hp,
			info.countdown,
			info.max_countdown,
			"是" if info.is_alive else "否"
		]

func _on_enemy_spawned(enemy: Node):
	"""敵人生成事件"""
	print("[EnemyTest] 收到敵人生成事件: ", enemy.name)

func _on_enemy_defeated(enemy_id: String, rewards: Dictionary):
	"""敵人被擊敗事件"""
	print("[EnemyTest] 敵人被擊敗: ", enemy_id)
	print("[EnemyTest] 獲得獎勵: ", rewards)
	
	# 3秒後重新創建敵人進行下一輪測試
	await get_tree().create_timer(3.0).timeout
	_test_enemy_creation()

func _create_fallback_enemy():
	"""創建備用測試敵人（當 ResourceManager 不可用時）"""
	print("[EnemyTest] 創建備用測試敵人")
	
	# 手動創建一個 Enemy 節點
	enemy_instance = preload("res://scripts/components/scenes/Enemy.tscn").instantiate()
	
	# 手動設置屬性
	enemy_instance.enemy_id = "E001"
	enemy_instance.enemy_name = "測試史萊姆"
	enemy_instance.element = "water"
	enemy_instance.base_hp = 800
	enemy_instance.current_hp = 800
	enemy_instance.base_attack = 80
	enemy_instance.max_countdown = 3
	enemy_instance.current_countdown = 3
	
	add_child(enemy_instance)
	enemy_instance.position = Vector2(200, 300)
	print("[EnemyTest] 備用敵人創建成功")

func _input(event):
	"""按鍵輸入處理"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_on_attack_button_pressed()
			KEY_2:
				_on_countdown_button_pressed()
			KEY_R:
				if not enemy_instance or not enemy_instance.is_alive:
					print("[EnemyTest] 重新創建敵人")
					_test_enemy_creation()
			KEY_ESCAPE:
				print("[EnemyTest] 退出測試")
				get_tree().quit()
			KEY_F1:
				print("[EnemyTest] 顯示幫助")
				_show_help()

func _show_help():
	"""顯示幫助信息"""
	print("=== EnemyTest 控制說明 ===")
	print("1 或 攻擊按鈕: 對敵人造成50點火屬性傷害")
	print("2 或 倒數按鈕: 手動觸發敵人倒數")
	print("R: 重新創建敵人")
	print("F1: 顯示此幫助")
	print("ESC: 退出測試")
	print("===========================")