# ResourceManager.gd - AutoLoad 單例 (JSON 數據驅動版本)
extends Node

# 資源池
var hero_pool: Dictionary = {}
var enemy_pool: Dictionary = {}

# JSON 數據庫
var balance_data: Dictionary = {}
var hero_database: Dictionary = {}
var enemy_database: Dictionary = {}
var block_database: Dictionary = {}  # 為 BattleTile 系統保留
var level_database: Dictionary = {}
var deck_database: Dictionary = {}

# 預載入的場景
var preloaded_scenes: Dictionary = {}

# 當前語言設定
var current_language: String = "zh"

func _ready():
	add_to_group("autoload_resource_manager")
	print("[ResourceManager] 資源管理系統初始化中...")
	_load_databases()
	_preload_common_scenes()
	print("[ResourceManager] 資源管理系統已就緒")

func _load_databases():
	print("[ResourceManager] 載入 JSON 數據庫...")
	
	# 載入平衡數據
	balance_data = _load_json_database("res://data/balance.json")
	
	# 載入各種資源的數據庫
	hero_database = _load_json_database("res://data/heroes.json")
	enemy_database = _load_json_database("res://data/enemies.json")
	block_database = _load_json_database("res://data/blocks.json")  # 為 BattleTile 系統保留
	level_database = _load_json_database("res://data/levels.json")
	deck_database = _load_json_database("res://data/decks.json")
	
	print("[ResourceManager] 數據庫載入完成")
	print("  - Balance: ", "已載入" if balance_data.size() > 0 else "空")
	print("  - Heroes: ", hero_database.size(), " 個")
	print("  - Enemies: ", enemy_database.size(), " 個")
	print("  - Blocks: ", block_database.size(), " 個 (為 BattleTile 使用)")
	print("  - Levels: ", level_database.size(), " 個")
	print("  - Decks: ", deck_database.size(), " 個")

func _load_json_database(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_warning("Database file not found: " + file_path + " - 創建空數據庫")
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Cannot open file: " + file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Error parsing JSON: " + file_path)
		return {}
	
	return json.data

func _preload_common_scenes():
	print("[ResourceManager] 預載入場景...")
	
	# 檢查場景文件是否存在，不存在則跳過
	var scene_paths = {
		"hero": "res://scripts/components/scenes/Hero.tscn",
		"enemy": "res://scripts/components/scenes/Enemy.tscn"
	}
	
	for scene_type in scene_paths:
		var path = scene_paths[scene_type]
		if ResourceLoader.exists(path):
			preloaded_scenes[scene_type] = load(path)
			print("[ResourceManager] 預載入場景: ", scene_type)
		else:
			print("[ResourceManager] 場景不存在，跳過: ", path)

# 從 JSON 數據創建英雄
func create_hero(hero_id: String) -> Node2D:
	print("[ResourceManager] 創建英雄: ", hero_id)
	
	var hero_data = hero_database.get(hero_id)
	if not hero_data:
		push_warning("Hero data not found: " + hero_id)
		return _create_placeholder_hero(hero_id)
	
	# 檢查是否有預載入的場景
	var hero_scene = preloaded_scenes.get("hero")
	if hero_scene:
		var hero_instance = hero_scene.instantiate()
		_setup_hero_from_data(hero_instance, hero_data)
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.resource_loaded.emit("hero", hero_id)
			eb.emit_object_event("created", "hero", hero_instance, {"id": hero_id})
		return hero_instance
	else:
		var hero_instance = _create_hero_from_data(hero_data)
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.emit_object_event("created", "hero", hero_instance, {"id": hero_id})
		return hero_instance

func create_enemy(enemy_id: String) -> Node2D:
	print("[ResourceManager] 創建敵人: ", enemy_id)
	
	var enemy_data = enemy_database.get(enemy_id)
	if not enemy_data:
		push_warning("Enemy data not found: " + enemy_id)
		return _create_placeholder_enemy(enemy_id)
	
	var enemy_scene = preloaded_scenes.get("enemy")
	if enemy_scene:
		var enemy_instance = enemy_scene.instantiate()
		_setup_enemy_from_data(enemy_instance, enemy_data)
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.resource_loaded.emit("enemy", enemy_id)
			eb.emit_object_event("spawned", "enemy", enemy_instance, {"id": enemy_id})
		return enemy_instance
	else:
		var enemy_instance = _create_enemy_from_data(enemy_data)
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.emit_object_event("spawned", "enemy", enemy_instance, {"id": enemy_id})
		return enemy_instance

# 創建帶有覆蓋數值的敵人
func create_enemy_with_overrides(enemy_data: Dictionary) -> Node2D:
	print("[ResourceManager] 創建帶覆蓋數值的敵人: ", enemy_data.get("enemy_id", enemy_data.get("id", "unknown")))
	
	var enemy_id = enemy_data.get("enemy_id", enemy_data.get("id", ""))
	if enemy_id == "":
		push_warning("Enemy data missing ID: " + str(enemy_data))
		return _create_placeholder_enemy("unknown")
	
	# 獲取基礎敵人數據
	var base_enemy_data = enemy_database.get(enemy_id)
	if not base_enemy_data:
		push_warning("Enemy database missing ID: " + enemy_id)
		return _create_placeholder_enemy(enemy_id)
	
	# 合併基礎數據和覆蓋數據
	var final_data = base_enemy_data.duplicate(true)
	
	# 應用覆蓋數值
	if enemy_data.has("hp_override") and enemy_data["hp_override"] != null:
		final_data["base_hp"] = enemy_data["hp_override"]
	if enemy_data.has("atk_override") and enemy_data["atk_override"] != null:
		final_data["base_attack"] = enemy_data["atk_override"]
	if enemy_data.has("cd_override") and enemy_data["cd_override"] != null:
		final_data["countdown"] = enemy_data["cd_override"]
	
	# 保存覆蓋狀態資訊
	final_data["_has_hp_override"] = enemy_data.has("hp_override")
	final_data["_has_atk_override"] = enemy_data.has("atk_override")
	final_data["_has_cd_override"] = enemy_data.has("cd_override")
	final_data["_wave"] = enemy_data.get("wave", 1)
	
	var enemy_scene = preloaded_scenes.get("enemy")
	if enemy_scene:
		var enemy_instance = enemy_scene.instantiate()
		_setup_enemy_from_data(enemy_instance, final_data)
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.resource_loaded.emit("enemy", enemy_id)
			eb.emit_object_event("spawned", "enemy", enemy_instance, {"id": enemy_id, "has_overrides": true})
		return enemy_instance
	else:
		var enemy_instance = _create_enemy_from_data(final_data)
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.emit_object_event("spawned", "enemy", enemy_instance, {"id": enemy_id, "has_overrides": true})
		return enemy_instance

# 簡化版 create_block 方法 - 主要用於測試和兼容性
# 實際遊戲中建議使用 BattleTile.create_from_block_data()
func create_block(block_id: String) -> Node2D:
	print("[ResourceManager] 創建方塊: ", block_id)
	
	var block_data = block_database.get(block_id)
	if not block_data:
		push_warning("Block data not found: " + block_id)
		return _create_placeholder_block(block_id)
	
	# 創建簡化的方塊節點
	return _create_simple_block_from_data(block_data)

# 從 JSON 數據創建物件的方法
func _create_hero_from_data(hero_data: Dictionary) -> Node2D:
	var hero = Node2D.new()
	hero.name = "Hero_" + hero_data.get("id", "unknown")
	
	# 設定屬性
	hero.set_meta("id", hero_data.get("id"))
	hero.set_meta("element", hero_data.get("element", "neutral"))
	hero.set_meta("base_attack", hero_data.get("base_attack", 100))
	hero.set_meta("hp", hero_data.get("hp", 1000))
	hero.set_meta("level", hero_data.get("level", 1))
	
	# 創建視覺元素
	var visual = _create_hero_visual(hero_data)
	hero.add_child(visual)
	
	return hero

func _create_enemy_from_data(enemy_data: Dictionary) -> Node2D:
	var enemy = Node2D.new()
	enemy.name = "Enemy_" + enemy_data.get("id", "unknown")
	
	# 設定屬性
	enemy.set_meta("id", enemy_data.get("id"))
	enemy.set_meta("element", enemy_data.get("element", "neutral"))
	enemy.set_meta("base_hp", enemy_data.get("base_hp", 100))
	enemy.set_meta("base_attack", enemy_data.get("base_attack", 10))
	enemy.set_meta("countdown", enemy_data.get("countdown", 3))
	
	# 創建視覺元素
	var visual = _create_enemy_visual(enemy_data)
	enemy.add_child(visual)
	
	return enemy

# 為場景創建的物件設定數據
func _setup_hero_from_data(hero_instance: Node, hero_data: Dictionary):
	# 如果場景有對應的腳本方法，調用它們來設定數據
	if hero_instance.has_method("load_from_data"):
		hero_instance.load_from_data(hero_data)
	else:
		# 否則使用 meta 數據
		hero_instance.set_meta("id", hero_data.get("id"))
		hero_instance.set_meta("element", hero_data.get("element", "neutral"))
		hero_instance.set_meta("base_attack", hero_data.get("base_attack", 100))
		hero_instance.set_meta("hp", hero_data.get("hp", 1000))

func _setup_enemy_from_data(enemy_instance: Node, enemy_data: Dictionary):
	if enemy_instance.has_method("load_from_data"):
		enemy_instance.load_from_data(enemy_data)
	else:
		enemy_instance.set_meta("id", enemy_data.get("id"))
		enemy_instance.set_meta("element", enemy_data.get("element", "neutral"))
		enemy_instance.set_meta("base_hp", enemy_data.get("base_hp", 100))
		enemy_instance.set_meta("base_attack", enemy_data.get("base_attack", 10))
		enemy_instance.set_meta("countdown", enemy_data.get("countdown", 3))

func _setup_block_from_data(block_instance: Node, block_data: Dictionary):
	if block_instance.has_method("load_from_data"):
		block_instance.load_from_data(block_data)
	else:
		# 基本屬性
		block_instance.set_meta("id", block_data.get("id"))
		block_instance.set_meta("element", block_data.get("element", "neutral"))
		block_instance.set_meta("shape", block_data.get("shape", "single"))
		block_instance.set_meta("bonus_value", block_data.get("bonus_value", 1))
		block_instance.set_meta("rarity", block_data.get("rarity", "common"))
		
		# 形狀相關屬性
		block_instance.set_meta("shape_pattern", get_block_shape_pattern(block_data))
		block_instance.set_meta("dimensions", get_block_dimensions(block_data))
		block_instance.set_meta("rotation_allowed", is_block_rotation_allowed(block_data))
		block_instance.set_meta("flip_allowed", is_block_flip_allowed(block_data))

# 創建視覺元素的輔助方法
func _create_hero_visual(hero_data: Dictionary) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(64, 64)
	
	# 背景
	var bg = ColorRect.new()
	bg.color = Color.GOLD
	bg.size = Vector2(64, 64)
	container.add_child(bg)
	
	# 標籤
	var label = Label.new()
	label.text = _get_localized_name(hero_data)
	label.position = Vector2(0, 70)
	label.add_theme_font_size_override("font_size", 12)
	container.add_child(label)
	
	return container

func _create_enemy_visual(enemy_data: Dictionary) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(64, 64)
	
	# 根據屬性設定顏色
	var element_colors = {
		"fire": Color.RED,
		"water": Color.BLUE,
		"grass": Color.GREEN,
		"light": Color.WHITE,
		"dark": Color.BLACK
	}
	
	var bg = ColorRect.new()
	bg.color = element_colors.get(enemy_data.get("element", "neutral"), Color.GRAY)
	bg.size = Vector2(64, 64)
	container.add_child(bg)
	
	var label = Label.new()
	label.text = _get_localized_name(enemy_data)
	label.position = Vector2(0, 70)
	label.add_theme_font_size_override("font_size", 12)
	container.add_child(label)
	
	return container

# 獲取本地化名稱
func _get_localized_name(data: Dictionary) -> String:
	var name_data = data.get("name", {})
	if typeof(name_data) == TYPE_DICTIONARY:
		return name_data.get(current_language, name_data.get("zh", data.get("id", "Unknown")))
	else:
		return str(name_data)

# 佔位符創建方法 - 用於開發初期
func _create_placeholder_hero(hero_id: String) -> Node2D:
	var hero = Node2D.new()
	hero.name = "Hero_" + hero_id
	
	# 添加基礎視覺元素
	var visual = ColorRect.new()
	visual.color = Color.GOLD
	visual.size = Vector2(64, 64)
	visual.position = Vector2(-32, -32)
	hero.add_child(visual)
	
	# 添加標籤
	var label = Label.new()
	label.text = "英雄"
	label.position = Vector2(-20, 40)
	hero.add_child(label)
	
	return hero

func _create_placeholder_enemy(enemy_id: String) -> Node2D:
	var enemy = Node2D.new()
	enemy.name = "Enemy_" + enemy_id
	
	var visual = ColorRect.new()
	visual.color = Color.RED
	visual.size = Vector2(64, 64)
	visual.position = Vector2(-32, -32)
	enemy.add_child(visual)
	
	var label = Label.new()
	label.text = "敵人"
	label.position = Vector2(-20, 40)
	enemy.add_child(label)
	
	return enemy

func _create_placeholder_block(block_id: String) -> Node2D:
	var block = Node2D.new()
	block.name = "Block_" + block_id
	
	var visual = ColorRect.new()
	visual.color = Color.BLUE
	visual.size = Vector2(48, 48)
	visual.position = Vector2(-24, -24)
	block.add_child(visual)
	
	var label = Label.new()
	label.text = "凸塊"
	label.position = Vector2(-15, 30)
	label.add_theme_font_size_override("font_size", 12)
	block.add_child(label)
	
	return block

func _create_simple_block_from_data(block_data: Dictionary) -> Node2D:
	var block = Node2D.new()
	block.name = "Block_" + block_data.get("id", "unknown")
	
	# 設定屬性
	block.set_meta("id", block_data.get("id"))
	block.set_meta("element", block_data.get("element", "neutral"))
	block.set_meta("bonus_value", block_data.get("bonus_value", 1))
	block.set_meta("rarity", block_data.get("rarity", "common"))
	block.set_meta("shape", block_data.get("shape", "single"))
	
	# 創建簡單視覺元素
	var element_colors = {
		"fire": Color.RED,
		"water": Color.BLUE,
		"grass": Color.GREEN,
		"light": Color.YELLOW,
		"dark": Color.PURPLE,
		"neutral": Color.GRAY
	}
	
	var visual = ColorRect.new()
	visual.color = element_colors.get(block_data.get("element", "neutral"), Color.GRAY)
	visual.size = Vector2(48, 48)
	visual.position = Vector2(-24, -24)
	block.add_child(visual)
	
	var label = Label.new()
	label.text = _get_localized_name(block_data)
	label.position = Vector2(-20, 30)
	label.add_theme_font_size_override("font_size", 10)
	block.add_child(label)
	
	return block

# 批量創建方法
func create_heroes_batch(hero_ids: Array) -> Array:
	var heroes: Array = []
	for hero_id in hero_ids:
		var hero = create_hero(hero_id)
		if hero:
			heroes.append(hero)
	return heroes

func create_enemies_batch(enemy_ids: Array) -> Array:
	var enemies: Array = []
	for enemy_id in enemy_ids:
		var enemy = create_enemy(enemy_id)
		if enemy:
			enemies.append(enemy)
	return enemies

# 物件池管理 - 簡化版本
func return_to_pool(object_instance: Node):
	print("[ResourceManager] 回收物件到池: ", object_instance.name)
	# 暫時直接釋放，之後可以實現真正的池化
	object_instance.queue_free()

# 測試方法
# 工具方法：技能相關
func get_skill_data(skill_id: String) -> Dictionary:
	var skill_manager = get_node_or_null("/root/SkillManager")
	if skill_manager:
		return skill_manager.get_skill_data(skill_id)
	return {}

func create_hero_with_skills(hero_id: String) -> Node2D:
	var hero = create_hero(hero_id)
	if not hero:
		return hero
	
	# 從 JSON 中獲取技能列表（简化版本 - 仅存储技能数据）
	var hero_data = hero_database.get(hero_id, {})
	var skills_list = hero_data.get("skills", [])
	
	var skill_manager = get_node_or_null("/root/SkillManager")
	if skill_manager and skills_list.size() > 0:
		var skill_data_list: Array = []
		for skill_info in skills_list:
			var skill_id: String
			if skill_info is String:
				skill_id = skill_info
			elif skill_info is Dictionary:
				skill_id = skill_info.get("id", "")
			
			if skill_id != "":
				var skill_data = skill_manager.get_skill_data(skill_id)
				if skill_data.size() > 0:
					skill_data_list.append(skill_data)
		
		hero.set_meta("skills_data", skill_data_list)
		print("[ResourceManager] 為英雄 ", hero_id, " 添加了 ", skill_data_list.size(), " 個技能数据")
	
	return hero

# 简化版本 - 移除复杂的技能组件系统

# 工具方法：訪問平衡數據
func get_balance_value(key: String, default_value = null):
	return balance_data.get(key, default_value)

func get_hero_base_attack() -> int:
	return balance_data.get("hero_base_attack", 100)

func get_tile_bonus(element: String) -> int:
	var tile_bonus = balance_data.get("tile_bonus", {})
	return tile_bonus.get(element, 1)

func get_element_multiplier(relationship: String) -> float:
	var multipliers = balance_data.get("element_multiplier", {})
	return multipliers.get(relationship, 1.0)

func get_combo_multiplier(combo_count: int) -> float:
	var combo_table = balance_data.get("combo_multiplier_table", {})
	var combo_str = str(combo_count)
	
	if combo_table.has(combo_str):
		return combo_table[combo_str]
	elif combo_count > 11:
		# 11連以上的公式：每+1連擊，倍率+0.5
		return 2.0 + (combo_count - 11) * 0.5
	else:
		return 1.0

# 工具方法：載入關卡數據
func get_level_data(level_id: String) -> Dictionary:
	return level_database.get(level_id, {})

func get_deck_data(deck_id: String) -> Dictionary:
	return deck_database.get(deck_id, {})


func get_all_level_ids() -> Array:
	return level_database.keys()

func get_enemy_data(enemy_id: String) -> Dictionary:
	return enemy_database.get(enemy_id, {})

# 工具方法：創建關卡中的敵人
func create_level_enemies(level_id: String) -> Array:
	var level_data = get_level_data(level_id)
	var enemies_data = level_data.get("enemies", [])
	var enemies = []
	
	for enemy_info in enemies_data:
		var enemy = create_enemy(enemy_info.get("id", ""))
		if enemy:
			# 覆蓋關卡特定的屬性
			enemy.set_meta("level_hp", enemy_info.get("hp", enemy.get_meta("base_hp")))
			enemy.set_meta("level_attack", enemy_info.get("atk", enemy.get_meta("base_attack")))
			enemy.set_meta("level_countdown", enemy_info.get("cd", enemy.get_meta("countdown")))
			enemies.append(enemy)
	
	return enemies

# 工具方法：處理凸塊形狀
func get_block_shape_pattern(block_data: Dictionary) -> Array:
	# 優先使用 JSON 中的 shape_pattern
	if block_data.has("shape_pattern"):
		return block_data["shape_pattern"]
	
	# 回退：根據 shape 類型生成預設 pattern
	var shape = block_data.get("shape", "single")
	match shape:
		"single":
			return [[1]]
		"line_2":
			return [[1, 1]]
		"line_3":
			return [[1, 1, 1]]
		"line_4":
			return [[1, 1, 1, 1]]
		"L_shape":
			return [[1, 0], [1, 0], [1, 1]]
		"T_shape":
			return [[1, 1, 1], [0, 1, 0]]
		"square":
			return [[1, 1], [1, 1]]
		"cross":
			return [[0, 1, 0], [1, 1, 1], [0, 1, 0]]
		_:
			push_warning("Unknown block shape: " + shape)
			return [[1]]

func get_block_dimensions(block_data: Dictionary) -> Vector2:
	var pattern = get_block_shape_pattern(block_data)
	if pattern.size() == 0:
		return Vector2(1, 1)
	
	var height = pattern.size()
	var width = 0
	for row in pattern:
		if row.size() > width:
			width = row.size()
	
	return Vector2(width, height)

func is_block_rotation_allowed(block_data: Dictionary) -> bool:
	return block_data.get("rotation_allowed", false)

func is_block_flip_allowed(block_data: Dictionary) -> bool:
	return block_data.get("flip_allowed", false)

func get_rotated_pattern(pattern: Array, rotations: int) -> Array:
	# 順時針旋轉 pattern (rotations * 90度)
	var result = pattern.duplicate(true)
	
	for i in range(rotations % 4):
		result = _rotate_pattern_90(result)
	
	return result

func get_flipped_pattern(pattern: Array, flip_horizontal: bool = false, flip_vertical: bool = false) -> Array:
	var result = pattern.duplicate(true)
	
	if flip_vertical:
		result.reverse()
	
	if flip_horizontal:
		for i in range(result.size()):
			result[i].reverse()
	
	return result

func _rotate_pattern_90(pattern: Array) -> Array:
	if pattern.size() == 0:
		return []
	
	var rows = pattern.size()
	var cols = pattern[0].size()
	var rotated = []
	
	# 創建新的 pattern (轉置 + 水平翻轉)
	for j in range(cols):
		var new_row = []
		for i in range(rows - 1, -1, -1):
			new_row.append(pattern[i][j])
		rotated.append(new_row)
	
	return rotated

# 工具方法：重新載入數據（熱重載）
func reload_balance_data():
	print("[ResourceManager] 重新載入平衡數據...")
	balance_data = _load_json_database("res://data/balance.json")
	print("[ResourceManager] 平衡數據重新載入完成")

# 測試方法
func test_resource_creation():
	print("[ResourceManager] 測試資源創建...")
	
	# 測試創建各種物件（使用真實 ID）
	var test_hero = create_hero("H001")
	var test_enemy = create_enemy("E001") 
	var test_block = create_block("B001")
	
	print("[ResourceManager] 測試創建完成")
	print("英雄屬性: ", test_hero.get_meta("element") if test_hero else "創建失敗")
	print("敵人血量: ", test_enemy.get_meta("base_hp") if test_enemy else "創建失敗")  
	print("方塊加成: ", test_block.get_meta("bonus_value") if test_block else "創建失敗")
	
	# 清理測試物件
	if test_hero: test_hero.queue_free()
	if test_enemy: test_enemy.queue_free() 
	if test_block: test_block.queue_free()

func test_balance_data():
	print("[ResourceManager] 測試平衡數據...")
	print("英雄基礎攻擊: ", get_hero_base_attack())
	print("火屬性方塊加成: ", get_tile_bonus("fire"))
	print("屬性相剋倍率: ", get_element_multiplier("advantage"))
	print("3連擊倍率: ", get_combo_multiplier(3))
	print("15連擊倍率: ", get_combo_multiplier(15))

func test_block_shapes():
	print("[ResourceManager] 測試凸塊形狀系統...")
	
	# 測試現有的單格凸塊
	var block_data = block_database.get("B001", {})
	if block_data.size() > 0:
		print("B001 形狀資訊:")
		print("  - Pattern: ", get_block_shape_pattern(block_data))
		print("  - Dimensions: ", get_block_dimensions(block_data))
		print("  - Rotation: ", is_block_rotation_allowed(block_data))
		print("  - Flip: ", is_block_flip_allowed(block_data))
	
	# 測試虛擬的多格凸塊
	var test_l_shape = {
		"shape": "L_shape",
		"rotation_allowed": true
	}
	print("L型凸塊測試:")
	print("  - Pattern: ", get_block_shape_pattern(test_l_shape))
	print("  - Dimensions: ", get_block_dimensions(test_l_shape))
	
	# 測試旋轉功能
	var original_pattern = [[1, 0], [1, 0], [1, 1]]
	print("  - 原始 Pattern: ", original_pattern)
	print("  - 旋轉90度: ", get_rotated_pattern(original_pattern, 1))
	print("  - 旋轉180度: ", get_rotated_pattern(original_pattern, 2))

# 創建帶有覆蓋數值的英雄
func create_hero_with_overrides(hero_data: Dictionary) -> Node2D:
	print("[ResourceManager] 創建帶覆蓋數值的英雄: ", hero_data.get("hero_id", hero_data.get("id", "unknown")))

	var hero_id = hero_data.get("hero_id", hero_data.get("id", ""))
	if hero_id == "":
		push_warning("Hero data missing ID: " + str(hero_data))
		return _create_placeholder_hero("unknown")

	# 獲取基礎英雄數據
	var base_hero_data = hero_database.get(hero_id)
	if not base_hero_data:
		push_warning("Hero database missing ID: " + hero_id)
		return _create_placeholder_hero(hero_id)

	# 合併基礎數據和覆蓋數據
	var final_data = base_hero_data.duplicate(true)

	# 應用覆蓋數值
	if hero_data.has("hp_override") and hero_data["hp_override"] != null:
		final_data["hp"] = hero_data["hp_override"]
	if hero_data.has("atk_override") and hero_data["atk_override"] != null:
		final_data["base_attack"] = hero_data["atk_override"]
	if hero_data.has("level_override") and hero_data["level_override"] != null:
		final_data["level"] = hero_data["level_override"]

	# 保存覆蓋狀態資訊
	final_data["_has_hp_override"] = hero_data.has("hp_override")
	final_data["_has_atk_override"] = hero_data.has("atk_override")
	final_data["_has_level_override"] = hero_data.has("level_override")

	var hero_scene = preloaded_scenes.get("hero")
	if hero_scene:
		var hero_instance = hero_scene.instantiate()
		_setup_hero_from_data(hero_instance, final_data)
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.resource_loaded.emit("hero", hero_id)
			eb.emit_object_event("created", "hero", hero_instance, {"id": hero_id, "has_overrides": true})
		return hero_instance
	else:
		var hero_instance = _create_hero_from_data(final_data)
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.emit_object_event("created", "hero", hero_instance, {"id": hero_id, "has_overrides": true})
		return hero_instance
