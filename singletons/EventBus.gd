# EventBus.gd - AutoLoad 單例
extends Node

# 戰鬥相關事件
signal battle_started(level_data: Dictionary)
signal battle_ended(result: String, rewards: Array)
signal turn_started(turn_number: int)
signal turn_ended()

# 物件生命週期事件  
signal hero_created(hero_instance: Node)
signal hero_destroyed(hero_id: String)
signal enemy_spawned(enemy_instance: Node)
signal enemy_defeated(enemy_id: String, rewards: Dictionary)
signal block_placed(block_instance: Node, position: Vector2)
signal block_removed(block_id: String)

# 能力與效果事件
signal ability_triggered(ability_id: String, caster: Node, target: Node)
signal effect_applied(effect_id: String, target: Node, duration: float)
signal effect_expired(effect_id: String, target: Node)
signal damage_dealt(source: Node, target: Node, amount: int, type: String)
signal healing_applied(source: Node, target: Node, amount: int)

# UI 事件
signal ui_tile_selected(tile_data: Dictionary)
signal ui_grid_updated(grid_state: Array)
signal ui_popup_requested(popup_type: String, data: Dictionary)

# 系統事件
signal game_paused()
signal game_resumed()
signal level_completed(level_id: String, score: int)
signal resource_loaded(resource_type: String, resource_id: String)

func _ready():
	print("[EventBus] 事件系統已初始化")

# 事件發送方法
func emit_battle_event(event_name: String, data: Dictionary = {}):
	match event_name:
		"started":
			battle_started.emit(data)
		"ended":
			battle_ended.emit(data.get("result", ""), data.get("rewards", []))
		_:
			push_warning("Unknown battle event: " + event_name)

func emit_object_event(event_name: String, object_type: String, instance: Node, data: Dictionary = {}):
	match object_type:
		"hero":
			if event_name == "created":
				hero_created.emit(instance)
			elif event_name == "destroyed":
				hero_destroyed.emit(data.get("id", ""))
		"enemy":
			if event_name == "spawned":
				enemy_spawned.emit(instance)
			elif event_name == "defeated":
				enemy_defeated.emit(data.get("id", ""), data.get("rewards", {}))
		"block":
			if event_name == "placed":
				block_placed.emit(instance, data.get("position", Vector2.ZERO))
			elif event_name == "removed":
				block_removed.emit(data.get("id", ""))
		_:
			push_warning("Unknown object type: " + object_type)

# 測試方法 - 可以在開發期間使用
func test_events():
	print("[EventBus] 測試事件系統...")
	
	# 測試戰鬥事件
	battle_started.emit({"level_id": "test_level", "test": true})
	
	# 測試系統事件
	resource_loaded.emit("hero", "test_hero")
	
	print("[EventBus] 事件測試完成")