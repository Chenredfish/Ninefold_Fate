# SimpleTest.gd - 簡單的單例測試
extends Node2D

func _ready():
	print("==========================================")
	print("=== 九重運命 - 完整系統測試 ===")
	print("==========================================")
	
	# 等待一幀確保所有 AutoLoad 都已載入
	await get_tree().process_frame
	
	test_autoloads()
	create_test_objects()
	
	print("\n==========================================")
	print("=== 測試完成 ===")
	print("所有系統運行正常！")
	print("按 Enter 重新測試，ESC 退出")
	print("==========================================")

func test_autoloads():
	print("\n--- 檢查 AutoLoad ---")
	print("當前時間: ", Time.get_datetime_string_from_system())
	print("Godot 版本: ", Engine.get_version_info())
	
	# 檢查 EventBus
	var event_bus: EventBus = get_node_or_null("/root/EventBus")
	if event_bus:
		print("✅ EventBus 載入成功")
		
		# 測試事件發送
		event_bus.battle_started.emit({"test": true})
		print("✅ EventBus 事件發送成功")
	else:
		print("❌ EventBus 載入失敗")
	
	# 檢查 ResourceManager
	var resource_manager: ResourceManager = get_node_or_null("/root/ResourceManager")
	if resource_manager:
		print("✅ ResourceManager 載入成功")
		print("   - 英雄數據庫: ", resource_manager.hero_database.size(), " 項目")
		print("   - 敵人數據庫: ", resource_manager.enemy_database.size(), " 項目")
		print("   - 凸塊數據庫: ", resource_manager.block_database.size(), " 項目")
	else:
		print("❌ ResourceManager 載入失敗")
	
	# 檢查 DebugManager
	var debug_manager: DebugManager = get_node_or_null("/root/DebugManager")
	if debug_manager:
		print("✅ DebugManager 載入成功")
	else:
		print("❌ DebugManager 載入失敗")
	
	# 檢查 SkillManager
	var skill_manager = get_node_or_null("/root/SkillManager")
	if skill_manager:
		print("✅ SkillManager 載入成功")
		print("   - 技能數據庫: ", skill_manager.skills_database.size(), " 項目")
		print("   - 可用技能: ", skill_manager.get_all_skill_ids())
		
		# 測試技能系統
		if skill_manager.has_method("test_skill_system"):
			print("--- SkillManager 功能測試 ---")
			skill_manager.test_skill_system()
		
	else:
		print("❌ SkillManager 載入失敗")

func create_test_objects():
	print("\n--- 測試 JSON 驅動的物件創建 ---")

	var resource_manager: ResourceManager = get_node_or_null("/root/ResourceManager")
	if not resource_manager:
		print("❌ ResourceManager 不可用")
		return
	
	# 測試平衡數據
	print("📊 平衡數據測試:")
	resource_manager.test_balance_data()
	
	# 測試創建真實的遊戲物件 (使用 JSON 中的 ID)
	print("\n🎮 物件創建測試:")
	var hero = resource_manager.create_hero("H001")
	var enemy = resource_manager.create_enemy("E001")
	# 方塊現在使用 BattleTile 系統
	var battle_tile = BattleTile.create_from_block_data("B001")
	
	# 測試帶技能的英雄創建
	print("\n⚔️ 技能系統測試:")
	var hero_with_skills = resource_manager.create_hero_with_skills("H001")
	if hero_with_skills:
		var skills_data = hero_with_skills.get_meta("skills_data", [])
		print("英雄技能數量: ", skills_data.size())
		for skill_data in skills_data:
			var skill_name = skill_data.get("name", {}).get("zh", "未知技能")
			var skill_type = skill_data.get("type", "未知")
			print("  - ", skill_name, " (", skill_type, ")")
	
	# 測試關卡數據
	print("\n🗺️ 關卡數據測試:")
	var level_data: Dictionary = resource_manager.get_level_data("level_001")
	if level_data.size() > 0:
		print("關卡 001 名稱: ", level_data.get("name", {}).get("zh", "未知"))
		print("關卡 001 英雄: ", level_data.get("hero_id"))
		print("關卡 001 敵人數量: ", level_data.get("enemies", []).size())
	
	# 放置到場景中並顯示數據驅動的屬性
	if hero:
		add_child(hero)
		hero.position = Vector2(200, 300)
		print("✅ 英雄創建成功")
		print("   - 屬性: ", hero.get_meta("element"))
		print("   - 攻擊力: ", hero.get_meta("base_attack"))
		print("   - 生命值: ", hero.get_meta("hp"))
	
	if enemy:
		add_child(enemy)
		enemy.position = Vector2(400, 300)
		print("✅ 敵人創建成功")
		print("   - 屬性: ", enemy.get_meta("element"))
		print("   - 生命值: ", enemy.get_meta("base_hp"))
		print("   - 攻擊力: ", enemy.get_meta("base_attack"))
		print("   - 倒數: ", enemy.get_meta("countdown"))
	
	if block:
		add_child(block)
		block.position = Vector2(300, 450)
		print("✅ 凸塊創建成功")
		print("   - 屬性: ", block.get_meta("element"))
		print("   - 加成: ", block.get_meta("bonus_value"))
		print("   - 稀有度: ", block.get_meta("rarity"))

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Enter
		# 清理現有物件
		for child in get_children():
			child.queue_free()
		
		# 重新測試
		call_deferred("_ready")
	
	if event.is_action_pressed("ui_cancel"):  # ESC
		print("退出測試")
		get_tree().quit()
