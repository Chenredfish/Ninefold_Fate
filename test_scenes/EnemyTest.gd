# EnemyTest.gd - 敵人系統測試（獨立運行）
extends Node2D

var enemy_instances: Array[Enemy] = []
var hero_instance: Hero
var poison_timer: Timer

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
		EventBus.damage_dealt_to_hero.connect(_on_damage_dealt_to_hero)
		# 監聽 damage_dealt 事件來驗證事件發送
		if not EventBus.damage_dealt.is_connected(_on_damage_event_received):
			EventBus.damage_dealt.connect(_on_damage_event_received)
		print("[EnemyTest] EventBus 連接成功")
	else:
		print("[EnemyTest] 警告：EventBus 不可用")
	
	# 創建敵人
	_test_enemy_creation()
	
	# 創建我方角色
	_test_hero_creation()
	
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
	"""測試敵人創建（創建3個敵人）"""
	print("[EnemyTest] 創建多個敵人進行測試...")
	
	# 清理舊敵人
	for enemy in enemy_instances:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemy_instances.clear()
	
	# 使用全局變數或路徑獲取 ResourceManager
	var rm = ResourceManager
	if not rm:
		rm = get_node_or_null("/root/ResourceManager")
	
	if rm:
		print("[EnemyTest] ResourceManager 可用，開始創建敵人")
		var enemy_ids = ["E001", "E002", "E001"]  # 創建3個敵人（包括重複）
		for i in range(enemy_ids.size()):
			var enemy = rm.create_enemy(enemy_ids[i])
			if enemy:
				add_child(enemy)
				# 增加敵人間距，避免重疊
				enemy.position = Vector2(200 + i * 150, 250)
				enemy_instances.append(enemy)
				print("[EnemyTest] 敵人", i+1, "創建成功:", enemy.enemy_name)
	else:
		print("[EnemyTest] 錯誤：ResourceManager 不可用，無法創建敵人")
		print("[EnemyTest] 請確保 ResourceManager 已正確配置為 AutoLoad")

func _test_hero_creation():
	"""測試我方角色創建"""
	print("[EnemyTest] 創建測試英雄...")
	
	var rm = ResourceManager
	if not rm:
		rm = get_node_or_null("/root/ResourceManager")
	
	if rm:
		print("[EnemyTest] ResourceManager 可用，開始創建英雄")
		hero_instance = rm.create_hero("H001")
		if hero_instance:
			add_child(hero_instance)
			hero_instance.position = Vector2(100, 250)
			print("[EnemyTest] 英雄創建成功:", hero_instance.hero_name)
		else:
			print("[EnemyTest] 英雄創建失敗")
	else:
		print("[EnemyTest] ResourceManager 不可用，無法創建英雄")
		print("[EnemyTest] 請確保 ResourceManager 已正確配置為 AutoLoad")
	
	# 設置持續傷害系統（毒傷害）
	_setup_poison_system()

func _setup_test_ui():
	"""設置測試用的UI按鈕"""
	var ui_container = Control.new()
	ui_container.name = "TestUI"
	add_child(ui_container)
	
	# 攻擊按鈕（單體攻擊）
	var attack_button = Button.new()
	attack_button.text = "單體攻擊 (第1個敵人 50火傷)"
	attack_button.position = Vector2(50, 50)
	attack_button.size = Vector2(200, 40)
	attack_button.pressed.connect(_on_single_attack_pressed)
	ui_container.add_child(attack_button)
	
	# 範圍攻擊按鈕（事件系統）
	var aoe_attack_button = Button.new()
	aoe_attack_button.text = "範圍攻擊 (所有敵人 30冰傷)"
	aoe_attack_button.position = Vector2(270, 50)
	aoe_attack_button.size = Vector2(200, 40)
	aoe_attack_button.pressed.connect(_on_aoe_attack_pressed)
	ui_container.add_child(aoe_attack_button)
	
	# 毒系統按鈕（靜默攻擊）
	var poison_button = Button.new()
	poison_button.text = "開關毒傷 (靈大傷害 5/秒)"
	poison_button.position = Vector2(490, 50)
	poison_button.size = Vector2(200, 40)
	poison_button.pressed.connect(_on_poison_toggle_pressed)
	ui_container.add_child(poison_button)
	
	# 測試倒數按鈕
	var countdown_button = Button.new()
	countdown_button.text = "手動倒數"
	countdown_button.position = Vector2(50, 100)
	countdown_button.size = Vector2(150, 40)
	countdown_button.pressed.connect(_on_countdown_button_pressed)
	ui_container.add_child(countdown_button)
	
	# 狀態顯示標籤（調整位置到底部）
	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "等待角色創建..."
	info_label.position = Vector2(50, 400)  # 移到底部，避免與角色重疊
	info_label.size = Vector2(700, 200)
	ui_container.add_child(info_label)
	
	# 每秒更新資訊顯示
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_info_display)
	timer.autostart = true
	add_child(timer)

func _on_single_attack_pressed():
	"""單體攻擊（直接調用） - 只攻擊第一個敵人"""
	if enemy_instances.size() > 0 and enemy_instances[0].is_alive:
		var target = enemy_instances[0]
		var source = hero_instance if hero_instance else null
		var source_name = source.hero_name if source else "现境"
		print("[EnemyTest] ", source_name, " 對 ", target.enemy_name, " 直接攻擊 - 50點火傷害（會發送事件）")
		target.take_damage(50, "fire", source)
	else:
		print("[EnemyTest] 沒有有效目標")

func _on_aoe_attack_pressed():
	"""範圍攻擊（事件系統） - 攻擊所有敵人"""
	var alive_enemies = enemy_instances.filter(func(enemy): return enemy.is_alive)
	if alive_enemies.size() > 0:
		var source = hero_instance if hero_instance else null
		var source_name = source.hero_name if source else "现境"
		print("[EnemyTest] ", source_name, " 發動範圍攻擊 - 對", alive_enemies.size(), "個敵人造成30點冰傷害")
		if EventBus:
			for enemy in alive_enemies:
				EventBus.damage_dealt.emit(source, enemy, 30, "ice")
		else:
			print("[EnemyTest] EventBus 不可用")
	else:
		print("[EnemyTest] 沒有活著的敵人")

var poison_active: bool = false

func _on_poison_toggle_pressed():
	"""開關毒傷系統（靜默攻擊） - 持續傷害"""
	poison_active = !poison_active
	if poison_active:
		print("[EnemyTest] 毒傷系統已開啟 - 所有敵人每秒受到5點毒傷害（靜默，不發送事件）")
	else:
		print("[EnemyTest] 毒傷系統已關閉")

func _setup_poison_system():
	"""設置毒傷系統"""
	poison_timer = Timer.new()
	poison_timer.wait_time = 1.0
	poison_timer.timeout.connect(_apply_poison_damage)
	poison_timer.autostart = true
	add_child(poison_timer)

func _apply_poison_damage():
	"""應用毒傷害（靜默模式）"""
	if not poison_active:
		return
	
	for enemy in enemy_instances:
		if enemy.is_alive:
			# 使用靜默攻擊，不發送事件
			enemy.take_damage(5, "poison", null, false)

func _on_countdown_button_pressed():
	"""倒數按鈕按下"""
	var alive_enemies = enemy_instances.filter(func(enemy): return enemy.is_alive)
	if alive_enemies.size() > 0:
		print("[EnemyTest] 手動觸發", alive_enemies.size(), "個敵人的倍數")
		for enemy in alive_enemies:
			enemy.tick_countdown()
			
	else:
		print("[EnemyTest] 沒有活著的敵人")

func _update_info_display():
	"""更新資訊顯示"""
	var info_label = get_node_or_null("TestUI/InfoLabel")
	if info_label:
		var text = ""
		
		# 英雄資訊
		if hero_instance:
			var hero_info = hero_instance.get_hero_info()
			text += "英雄: %s (%s) HP:%d/%d\n" % [
				hero_info.name, hero_info.element,
				hero_info.current_hp, hero_info.max_hp
			]
		else:
			text += "英雄: 未創建\n"
		
		# 敵人資訊
		text += "\n敵人狀態:\n"
		if enemy_instances.size() > 0:
			for i in range(enemy_instances.size()):
				var enemy = enemy_instances[i]
				var info = enemy.get_enemy_info()
				text += "%d. %s (%s) HP:%d/%d 倍數:%d/%d %s\n" % [
					i+1, info.name, info.element,
					info.current_hp, info.max_hp,
					info.countdown, info.max_countdown,
					"活著" if info.is_alive else "死亡"
				]
		else:
			text += "無敵人\n"
		
		# 毒傷狀態
		text += "\n毒傷系統: %s" % ("開啟" if poison_active else "關閉")
		
		info_label.text = text

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
	"""備用方案已移除 - 請確保 ResourceManager 正確配置"""
	print("[EnemyTest] 錯誤：ResourceManager 不可用")
	print("[EnemyTest] 請檢查 project.godot 中的 AutoLoad 設置")
	print("[EnemyTest] 備用敵人創建成功")

func _create_fallback_hero():
	"""創建備用測試英雄（當 ResourceManager 不可用時）"""
	print("[EnemyTest] 創建備用測試英雄")
	
	# 手動創建一個 Hero 節點
	hero_instance = Hero.new()
	
	# 嘗試從JSON載入資料（模擬 ResourceManager.create_hero 的過程）
	var hero_data = _load_hero_data_fallback("H001")
	if hero_data:
		hero_instance.load_from_data(hero_data)
	
	add_child(hero_instance)
	hero_instance.position = Vector2(100, 300)
	print("[EnemyTest] 備用英雄創建成功")

func _load_enemy_data_fallback(enemy_id: String) -> Dictionary:
	"""備用方案：載入敵人資料"""
	var file_path = "res://data/enemies.json"
	if ResourceLoader.exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_text)
			if parse_result == OK:
				var data = json.data
				if data is Dictionary and data.has("enemies"):
					for enemy in data.enemies:
						if enemy.get("id", "") == enemy_id:
							return enemy
	
	# 如果載入失敗，返回預設資料
	print("[EnemyTest] 無法載入JSON，使用預設敵人資料")
	return {
		"id": "E001",
		"name": {"zh": "測試史萊姆", "en": "Test Slime"},
		"element": "water",
		"base_hp": 800,
		"base_attack": 80,
		"max_countdown": 3,
		"sprite_path": "",
		"tags": ["slime"]
	}

func _load_hero_data_fallback(hero_id: String) -> Dictionary:
	"""備用方案：載入英雄資料"""
	var file_path = "res://data/heroes.json"
	if ResourceLoader.exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_text)
			if parse_result == OK:
				var data = json.data
				if data is Dictionary and data.has("heroes"):
					for hero in data.heroes:
						if hero.get("id", "") == hero_id:
							return hero
	
	# 如果載入失敗，返回預設資料
	print("[EnemyTest] 無法載入JSON，使用預設英雄資料")
	return {
		"id": "H001",
		"name": {"zh": "測試勇者", "en": "Test Hero"},
		"element": "fire",
		"base_attack": 100,
		"hp": 1000,
		"level": 1,
		"sprite_path": "",
		"skills": [],
		"tags": ["warrior"]
	}

func _input(event):
	"""按鍵輸入處理"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_on_single_attack_pressed()
			KEY_2:
				_on_countdown_button_pressed()
			KEY_R:
				if enemy_instances.size() == 0 or not enemy_instances.any(func(enemy): return enemy.is_alive):
					print("[EnemyTest] 重新創建敵人")
					_test_enemy_creation()
			KEY_ESCAPE:
				print("[EnemyTest] 退出測試")
				get_tree().quit()
			KEY_F1:
				print("[EnemyTest] 顯示幫助")
				_show_help()

func _on_damage_dealt_to_hero(source: Node, amount: int, damage_type: String):
	hero_instance.take_damage(amount, damage_type, source)
	"""監聽對英雄的傷害事件"""
	var source_name = "環境傷害"
	if source and source.has_method("get_hero_info"):
		source_name = source.hero_name
	elif source and source.has_method("get_enemy_info"):
		source_name = source.enemy_name
	elif source:
		source_name = source.name

	print("[EnemyTest] 💥 英雄受到傷害事件: ", source_name, " → ", hero_instance.hero_name, " (", amount, " ", damage_type, "傷害)")

func _on_damage_event_received(source: Node, target: Node, amount: int, damage_type: String):
	"""監聽傷害事件，驗證事件系統運作"""
	var source_name = "環境傷害"
	if source and source.has_method("get_hero_info"):
		source_name = source.hero_name
	elif source and source.has_method("get_enemy_info"):
		source_name = source.enemy_name
	elif source:
		source_name = source.name

	var target_name = "未知目標"
	if target and target.has_method("get_hero_info"):
		target_name = target.hero_name
	elif target and target.has_method("get_enemy_info"):
		target_name = target.enemy_name
	elif target:
		target_name = target.name

	
	print("[EnemyTest] 🔥 收到傷害事件: ", source_name, " → ", target_name, " (", amount, " ", damage_type, "傷害)")

func _show_help():
	"""顯示幫助信息"""
	print("=== EnemyTest 控制說明 ===")
	print("單體攻擊: 對第一個敵人造成50點火傷害（直接調用，會發送事件）")
	print("範圍攻擊: 對所有敵人造成30點冰傷害（事件系統，不重複發送事件）") 
	print("毒傷系統: 每秒對所有敵人造成5點毒傷害（靜默模式，不發送事件）")
	print("手動倒數: 觸發所有敵人的倒數機制")
	print("R: 重新創建敵人")
	print("F1: 顯示此幫助")
	print("ESC: 退出測試")
	print("===========================")

# 註：本測試需要 ResourceManager 正確配置為 AutoLoad 才能運行
# 如果 ResourceManager 不可用，請檢查項目設置
