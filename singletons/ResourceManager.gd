# ResourceManager.gd - AutoLoad 單例
extends Node

# 資源池
var hero_pool: Dictionary = {}
var enemy_pool: Dictionary = {}
var block_pool: Dictionary = {}
var ability_pool: Dictionary = {}

# 資源數據
var hero_database: Dictionary = {}
var enemy_database: Dictionary = {}
var block_database: Dictionary = {}
var ability_database: Dictionary = {}

# 預載入的場景
var preloaded_scenes: Dictionary = {}

func _ready():
	print("[ResourceManager] 資源管理系統初始化中...")
	_load_databases()
	_preload_common_scenes()
	print("[ResourceManager] 資源管理系統已就緒")

func _load_databases():
	print("[ResourceManager] 載入資源數據庫...")
	
	# 載入各種資源的數據庫
	hero_database = _load_json_database("res://data/heroes.json")
	enemy_database = _load_json_database("res://data/enemies.json")
	block_database = _load_json_database("res://data/blocks.json")
	ability_database = _load_json_database("res://data/abilities.json")
	
	print("[ResourceManager] 數據庫載入完成 - Heroes: ", hero_database.size(), " Enemies: ", enemy_database.size())

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
		"hero": "res://scenes/Hero.tscn",
		"enemy": "res://scenes/Enemy.tscn",
		"block": "res://scenes/Block.tscn"
	}
	
	for scene_type in scene_paths:
		var path = scene_paths[scene_type]
		if ResourceLoader.exists(path):
			preloaded_scenes[scene_type] = load(path)
			print("[ResourceManager] 預載入場景: ", scene_type)
		else:
			print("[ResourceManager] 場景不存在，跳過: ", path)

# 創建方法的簡化版本 - 目前先返回基礎節點
func create_hero(hero_id: String) -> Node:
	print("[ResourceManager] 創建英雄: ", hero_id)
	
	var hero_data = hero_database.get(hero_id)
	if not hero_data:
		push_warning("Hero data not found: " + hero_id + " - 創建基礎英雄")
		return _create_placeholder_hero(hero_id)
	
	# 檢查是否有預載入的場景
	var hero_scene = preloaded_scenes.get("hero")
	if hero_scene:
		var hero_instance = hero_scene.instantiate()
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.resource_loaded.emit("hero", hero_id)
		return hero_instance
	else:
		return _create_placeholder_hero(hero_id)

func create_enemy(enemy_id: String) -> Node:
	print("[ResourceManager] 創建敵人: ", enemy_id)
	
	var enemy_data = enemy_database.get(enemy_id)
	if not enemy_data:
		push_warning("Enemy data not found: " + enemy_id + " - 創建基礎敵人")
		return _create_placeholder_enemy(enemy_id)
	
	var enemy_scene = preloaded_scenes.get("enemy")
	if enemy_scene:
		var enemy_instance = enemy_scene.instantiate()
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.resource_loaded.emit("enemy", enemy_id)
		return enemy_instance
	else:
		return _create_placeholder_enemy(enemy_id)

func create_block(block_id: String) -> Node:
	print("[ResourceManager] 創建凸塊: ", block_id)
	
	var block_data = block_database.get(block_id)
	if not block_data:
		push_warning("Block data not found: " + block_id + " - 創建基礎凸塊")
		return _create_placeholder_block(block_id)
	
	var block_scene = preloaded_scenes.get("block")
	if block_scene:
		var block_instance = block_scene.instantiate()
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.resource_loaded.emit("block", block_id)
		return block_instance
	else:
		return _create_placeholder_block(block_id)

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
func test_resource_creation():
	print("[ResourceManager] 測試資源創建...")
	
	# 測試創建各種物件
	var test_hero = create_hero("test_hero")
	var test_enemy = create_enemy("test_enemy") 
	var test_block = create_block("test_block")
	
	print("[ResourceManager] 測試創建完成")
	
	# 清理測試物件
	test_hero.queue_free()
	test_enemy.queue_free()
	test_block.queue_free()