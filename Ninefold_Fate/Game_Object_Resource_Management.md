# Ninefold Fate - 遊戲物件與資源管理規格書

版本：v0.1  
基於：Game_SRS.md + Godot_Implementation_Specification.md  
更新日期：2025-10-10

---

## 📑 目錄

- [一、概述與設計原則](#一概述與設計原則)
  - [1.1 核心物件類型](#11-核心物件類型)
  - [1.2 設計原則](#12-設計原則)
- [二、EventBus 全域事件系統](#二eventbus-全域事件系統)
  - [2.1 EventBus 架構設計](#21-eventbus-架構設計)
  - [2.2 事件監聽範例](#22-事件監聽範例)
- [三、核心物件架構設計](#三核心物件架構設計)
  - [3.1 基礎物件類別 (BaseGameObject)](#31-基礎物件類別-basegameobject)
  - [3.2 英雄類別 (Hero)](#32-英雄類別-hero)
  - [3.3 凸塊類別 (Block)](#33-凸塊類別-block)
  - [3.4 敵人類別 (Enemy)](#34-敵人類別-enemy)
- [四、能力組件系統 (Component-Based Abilities)](#四能力組件系統-component-based-abilities)
  - [4.1 基礎能力組件 (AbilityComponent)](#41-基礎能力組件-abilitycomponent)
  - [4.2 具體能力組件範例](#42-具體能力組件範例)
    - [4.2.1 治療能力 (HealAbility)](#421-治療能力-healability)
    - [4.2.2 燃燒能力 (BurnAbility)](#422-燃燒能力-burnability)
    - [4.2.3 護盾能力 (ShieldAbility)](#423-護盾能力-shieldability)
- [五、資源管理與載入系統](#五資源管理與載入系統)
  - [5.1 資源管理器 (ResourceManager)](#51-資源管理器-resourcemanager)
  - [5.2 資料類型定義](#52-資料類型定義)
- [六、擴展性設計](#六擴展性設計)
  - [6.1 新增物件類型](#61-新增物件類型)
  - [6.2 新增能力組件](#62-新增能力組件)
  - [6.3 擴展 EventBus](#63-擴展-eventbus)
  - [6.4 效能優化考慮](#64-效能優化考慮)
- [七、測試與除錯](#七測試與除錯)
  - [7.1 除錯工具](#71-除錯工具)
  - [7.2 單元測試範例](#72-單元測試範例)
- [八、實際使用指南](#八實際使用指南)
  - [8.1 項目設置步驟](#81-項目設置步驟)
  - [8.2 EventBus 使用方法](#82-eventbus-使用方法)
  - [8.3 ResourceManager 使用方法](#83-resourcemanager-使用方法)
  - [8.4 實戰範例：創建戰鬥場景](#84-實戰範例創建戰鬥場景)
  - [8.5 常見問題與解決方案](#85-常見問題與解決方案)
- [九、總結](#九總結)

---

## 一、概述與設計原則

### 1.1 核心物件類型
本遊戲包含三大核心物件類型：
- **英雄 (Hero)**：玩家控制的主要單位，具有屬性和技能
- **凸塊 (Block)**：戰鬥中的攻擊單元，有不同屬性和效果
- **敵人 (Enemy)**：關卡中的對手，具有血量、攻擊力和倒數機制

### 1.2 設計原則
- **組件化架構**：每個物件由多個可重用組件組成
- **EventBus 解耦**：使用全域事件系統避免直接引用
- **資源池管理**：預載入和復用物件實例提升效能
- **數據驅動**：物件屬性由 JSON 配置文件定義
- **擴展性優先**：便於新增物件類型和能力效果

---

## 二、EventBus 全域事件系統

### 2.1 EventBus 架構設計

```gdscript
# EventBus.gd - AutoLoad 單例
extends Node

# 戰鬥相關事件
signal battle_started(level_data: Dictionary)
signal battle_ended(result: String, rewards: Array)
signal turn_started(turn_number: int)
signal turn_ended()

# 物件生命週期事件  
signal hero_created(hero_instance: Hero)
signal hero_destroyed(hero_id: String)
signal enemy_spawned(enemy_instance: Enemy)
signal enemy_defeated(enemy_id: String, rewards: Dictionary)
signal block_placed(block_instance: Block, position: Vector2)
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
		_:
			push_warning("Unknown object type: " + object_type)
```

### 2.2 事件監聽範例

```gdscript
# BattleManager.gd
extends Node

func _ready():
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.ability_triggered.connect(_on_ability_triggered)

func _on_battle_started(level_data: Dictionary):
	print("戰鬥開始：關卡 ", level_data.get("level_id"))
	_spawn_enemies(level_data.get("enemies", []))

func _on_enemy_defeated(enemy_id: String, rewards: Dictionary):
	print("敵人 ", enemy_id, " 被擊敗，獲得獎勵：", rewards)
	_check_victory_condition()

func _on_ability_triggered(ability_id: String, caster: Node, target: Node):
	print("技能 ", ability_id, " 被觸發")
	_apply_ability_effects(ability_id, caster, target)
```

---

## 三、核心物件架構設計

### 3.1 基礎物件類別 (BaseGameObject)

```gdscript
# BaseGameObject.gd - 所有遊戲物件的基類
class_name BaseGameObject
extends Node2D

@export var object_id: String = ""
@export var object_name: String = ""
@export var object_type: String = ""

# 組件容器
var components: Dictionary = {}
var effects: Array[AbilityComponent] = []

# 生命週期
signal object_created(instance: BaseGameObject)
signal object_destroyed(object_id: String)

func _init(id: String = "", type: String = ""):
	object_id = id if id != "" else _generate_unique_id()
	object_type = type
	
func _ready():
	_initialize_components()
	object_created.emit(self)
	EventBus.emit_object_event("created", object_type, self, {"id": object_id})

func _exit_tree():
	object_destroyed.emit(object_id)
	EventBus.emit_object_event("destroyed", object_type, self, {"id": object_id})

# 組件管理
func add_component(component_type: String, component_instance: Node):
	components[component_type] = component_instance
	add_child(component_instance)
	component_instance.setup(self)

func get_component(component_type: String) -> Node:
	return components.get(component_type)

func has_component(component_type: String) -> bool:
	return components.has(component_type)

func remove_component(component_type: String):
	if has_component(component_type):
		var component = components[component_type]
		component.cleanup()
		component.queue_free()
		components.erase(component_type)

# 效果管理
func add_effect(effect: AbilityComponent):
	effects.append(effect)
	add_child(effect)
	effect.apply_to(self)

func remove_effect(effect_id: String):
	for i in range(effects.size() - 1, -1, -1):
		if effects[i].effect_id == effect_id:
			effects[i].remove_from(self)
			effects[i].queue_free()
			effects.remove_at(i)
			break

# 虛擬方法，由子類實現
func _initialize_components():
	pass

func _generate_unique_id() -> String:
	return object_type + "_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
```

### 3.2 英雄類別 (Hero)

```gdscript
# Hero.gd - 英雄物件
class_name Hero
extends BaseGameObject

@export var hero_data: HeroData
@export var current_hp: int = 100
@export var max_hp: int = 100
@export var attack_power: int = 10
@export var element_type: String = "neutral"

# 英雄特有的訊號
signal hp_changed(old_hp: int, new_hp: int)
signal skill_ready(skill_id: String)
signal skill_used(skill_id: String, target: Node)

# 技能相關
var skills: Array[AbilityComponent] = []
var skill_cooldowns: Dictionary = {}

func _init(id: String = "", data: HeroData = null):
	super._init(id, "hero")
	hero_data = data
	if hero_data:
		_load_from_data(hero_data)

func _initialize_components():
	# 添加基礎組件
	add_component("HealthComponent", HealthComponent.new())
	add_component("AttackComponent", AttackComponent.new()) 
	add_component("MovementComponent", MovementComponent.new())
	
	# 根據英雄數據添加特殊組件
	if hero_data and hero_data.has_shield:
		add_component("ShieldComponent", ShieldComponent.new())
	
	# 載入技能
	_load_skills()

func _load_from_data(data: HeroData):
	object_name = data.hero_name
	max_hp = data.base_hp
	current_hp = max_hp
	attack_power = data.base_attack
	element_type = data.element

func _load_skills():
	if not hero_data or hero_data.skills.is_empty():
		return
		
	for skill_data in hero_data.skills:
		var skill_component = AbilityComponent.create_from_data(skill_data)
		skills.append(skill_component)
		add_child(skill_component)

# 血量管理
func take_damage(amount: int, source: Node = null):
	var health_component = get_component("HealthComponent")
	if health_component:
		health_component.take_damage(amount, source)
	else:
		_fallback_take_damage(amount, source)

func heal(amount: int, source: Node = null):
	var health_component = get_component("HealthComponent")
	if health_component:
		health_component.heal(amount, source)
	else:
		_fallback_heal(amount, source)

func _fallback_take_damage(amount: int, source: Node):
	var old_hp = current_hp
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(old_hp, current_hp)
	EventBus.damage_dealt.emit(source, self, amount, "physical")
	
	if current_hp <= 0:
		_handle_death()

func _fallback_heal(amount: int, source: Node):
	var old_hp = current_hp
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(old_hp, current_hp)
	EventBus.healing_applied.emit(source, self, amount)

func _handle_death():
	EventBus.emit_object_event("destroyed", "hero", self, {
		"id": object_id,
		"cause": "death"
	})

# 技能使用
func use_skill(skill_index: int, target: Node = null):
	if skill_index < 0 or skill_index >= skills.size():
		return false
		
	var skill = skills[skill_index]
	var skill_id = skill.ability_id
	
	# 檢查冷卻時間
	if skill_cooldowns.has(skill_id) and skill_cooldowns[skill_id] > 0:
		return false
	
	# 執行技能
	skill.execute(self, target)
	skill_used.emit(skill_id, target)
	EventBus.ability_triggered.emit(skill_id, self, target)
	
	# 設定冷卻時間
	skill_cooldowns[skill_id] = skill.cooldown_time
	
	return true

func _process(delta):
	# 更新技能冷卻時間
	for skill_id in skill_cooldowns.keys():
		skill_cooldowns[skill_id] = max(0, skill_cooldowns[skill_id] - delta)
		if skill_cooldowns[skill_id] == 0:
			skill_ready.emit(skill_id)
```

### 3.3 凸塊類別 (Block)

```gdscript
# Block.gd - 凸塊物件
class_name Block
extends BaseGameObject

@export var block_data: BlockData
@export var element_type: String = "neutral"
@export var attack_value: int = 1
@export var special_effects: Array[String] = []

# 凸塊狀態
enum BlockState {
	INACTIVE,    # 未激活
	ACTIVE,      # 激活狀態
	USED,        # 已使用
	DESTROYED    # 已銷毀
}

var current_state: BlockState = BlockState.INACTIVE
var grid_position: Vector2 = Vector2(-1, -1)

# 凸塊特有訊號
signal block_activated(block_instance: Block)
signal block_used(block_instance: Block, target: Node)
signal state_changed(old_state: BlockState, new_state: BlockState)

func _init(id: String = "", data: BlockData = null):
	super._init(id, "block")
	block_data = data
	if block_data:
		_load_from_data(block_data)

func _initialize_components():
	# 基礎組件
	add_component("ElementComponent", ElementComponent.new())
	add_component("VisualComponent", VisualComponent.new())
	
	# 根據凸塊數據添加特殊組件
	if block_data:
		for effect_id in block_data.special_effects:
			var effect_component = AbilityComponent.create_by_id(effect_id)
			add_component(effect_id, effect_component)

func _load_from_data(data: BlockData):
	object_name = data.block_name
	element_type = data.element
	attack_value = data.base_attack
	special_effects = data.special_effects.duplicate()

# 狀態管理
func set_state(new_state: BlockState):
	if new_state == current_state:
		return
		
	var old_state = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)
	
	match new_state:
		BlockState.ACTIVE:
			block_activated.emit(self)
		BlockState.USED:
			_on_block_used()
		BlockState.DESTROYED:
			_on_block_destroyed()

func activate():
	set_state(BlockState.ACTIVE)

func use_on_target(target: Node):
	if current_state != BlockState.ACTIVE:
		return false
	
	# 執行攻擊
	_perform_attack(target)
	
	# 觸發特殊效果
	for effect_id in special_effects:
		var effect_component = get_component(effect_id)
		if effect_component:
			effect_component.execute(self, target)
	
	block_used.emit(self, target)
	set_state(BlockState.USED)
	return true

func _perform_attack(target: Node):
	var damage = attack_value
	
	# 屬性加成計算
	var element_component = get_component("ElementComponent")
	if element_component:
		damage = element_component.calculate_damage(damage, target)
	
	# 造成傷害
	if target.has_method("take_damage"):
		target.take_damage(damage, self)

func _on_block_used():
	# 可以在這裡添加使用後的效果，如淡出動畫
	pass

func _on_block_destroyed():
	EventBus.block_removed.emit(object_id)

# 網格位置管理
func set_grid_position(pos: Vector2):
	grid_position = pos
	EventBus.block_placed.emit(self, pos)

func get_grid_position() -> Vector2:
	return grid_position
```

### 3.4 敵人類別 (Enemy)

```gdscript
# Enemy.gd - 敵人物件
class_name Enemy
extends BaseGameObject

@export var enemy_data: EnemyData
@export var current_hp: int = 50
@export var max_hp: int = 50
@export var attack_power: int = 8
@export var countdown_max: int = 3
@export var countdown_current: int = 3

# 敵人特有訊號
signal countdown_tick(remaining_time: int)
signal countdown_zero()
signal enemy_attack(target: Node, damage: int)
signal hp_changed(old_hp: int, new_hp: int)

var is_defeated: bool = false

func _init(id: String = "", data: EnemyData = null):
	super._init(id, "enemy")
	enemy_data = data
	if enemy_data:
		_load_from_data(enemy_data)

func _initialize_components():
	# 基礎組件
	add_component("HealthComponent", HealthComponent.new())
	add_component("AttackComponent", AttackComponent.new())
	add_component("CountdownComponent", CountdownComponent.new())
	
	# AI 組件（如果有的話）
	if enemy_data and enemy_data.has_ai:
		add_component("AIComponent", AIComponent.new())

func _load_from_data(data: EnemyData):
	object_name = data.enemy_name
	max_hp = data.base_hp
	current_hp = max_hp
	attack_power = data.base_attack
	countdown_max = data.countdown_time
	countdown_current = countdown_max

# 倒數機制
func tick_countdown():
	if is_defeated:
		return
		
	countdown_current = max(0, countdown_current - 1)
	countdown_tick.emit(countdown_current)
	
	if countdown_current <= 0:
		countdown_zero.emit()
		_perform_attack()
		_reset_countdown()

func _reset_countdown():
	countdown_current = countdown_max

func accelerate_countdown(amount: int = 1):
	countdown_current = max(0, countdown_current - amount)
	countdown_tick.emit(countdown_current)
	
	if countdown_current <= 0:
		countdown_zero.emit()
		_perform_attack()
		_reset_countdown()

# 攻擊機制
func _perform_attack():
	# 尋找攻擊目標（通常是英雄）
	var target = _find_attack_target()
	if not target:
		return
	
	var damage = attack_power
	
	# 應用攻擊組件的修正
	var attack_component = get_component("AttackComponent")
	if attack_component:
		damage = attack_component.calculate_damage(damage, target)
	
	# 執行攻擊
	if target.has_method("take_damage"):
		target.take_damage(damage, self)
	
	enemy_attack.emit(target, damage)

func _find_attack_target() -> Node:
	# 簡單實現：尋找第一個英雄
	var heroes = get_tree().get_nodes_in_group("heroes")
	if heroes.size() > 0:
		return heroes[0]
	return null

# 血量管理
func take_damage(amount: int, source: Node = null):
	if is_defeated:
		return
		
	var health_component = get_component("HealthComponent")
	if health_component:
		health_component.take_damage(amount, source)
	else:
		_fallback_take_damage(amount, source)

func _fallback_take_damage(amount: int, source: Node):
	var old_hp = current_hp
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(old_hp, current_hp)
	EventBus.damage_dealt.emit(source, self, amount, "physical")
	
	if current_hp <= 0 and not is_defeated:
		_handle_defeat()

func _handle_defeat():
	is_defeated = true
	
	# 計算獎勵
	var rewards = _calculate_rewards()
	
	EventBus.enemy_defeated.emit(object_id, rewards)
	EventBus.emit_object_event("defeated", "enemy", self, {
		"id": object_id,
		"rewards": rewards
	})

func _calculate_rewards() -> Dictionary:
	var rewards = {
		"experience": enemy_data.exp_reward if enemy_data else 10,
		"gold": enemy_data.gold_reward if enemy_data else 5
	}
	
	# 可以根據敵人類型和難度計算額外獎勵
	return rewards
```

---

## 四、能力組件系統 (Component-Based Abilities)

### 4.1 基礎能力組件 (AbilityComponent)

```gdscript
# AbilityComponent.gd - 所有能力效果的基類
class_name AbilityComponent
extends Node

@export var ability_id: String = ""
@export var ability_name: String = ""
@export var description: String = ""
@export var cooldown_time: float = 0.0
@export var duration: float = -1.0  # -1 表示永久效果

# 能力類型
enum AbilityType {
	INSTANT,     # 瞬間效果
	DURATION,    # 持續效果
	TOGGLE,      # 開關效果
	PASSIVE      # 被動效果
}

@export var ability_type: AbilityType = AbilityType.INSTANT

# 目標類型
enum TargetType {
	SELF,        # 自己
	SINGLE,      # 單一目標
	MULTIPLE,    # 多個目標
	AREA,        # 區域效果
	ALL_ENEMIES, # 所有敵人
	ALL_ALLIES   # 所有盟友
}

@export var target_type: TargetType = TargetType.SINGLE

# 生命週期
var caster: Node = null
var target: Node = null
var is_active: bool = false
var remaining_duration: float = 0.0

# 訊號
signal ability_started(caster: Node, target: Node)
signal ability_finished(caster: Node, target: Node)
signal ability_interrupted(reason: String)

func _ready():
	if duration > 0:
		remaining_duration = duration

func _process(delta):
	if is_active and duration > 0:
		remaining_duration -= delta
		if remaining_duration <= 0:
			_end_ability()

# 靜態創建方法
static func create_from_data(ability_data: Dictionary) -> AbilityComponent:
	var ability_id = ability_data.get("id", "")
	return create_by_id(ability_id)

static func create_by_id(ability_id: String) -> AbilityComponent:
	match ability_id:
		"heal":
			return HealAbility.new()
		"shield":
			return ShieldAbility.new()
		"burn":
			return BurnAbility.new()
		"freeze":
			return FreezeAbility.new()
		"poison":
			return PoisonAbility.new()
		"buff_attack":
			return AttackBuffAbility.new()
		"debuff_defense":
			return DefenseDebuffAbility.new()
		_:
			push_warning("Unknown ability ID: " + ability_id)
			return AbilityComponent.new()

# 核心方法
func setup(owner_node: Node):
	caster = owner_node
	_initialize_ability()

func execute(caster_node: Node, target_node: Node = null) -> bool:
	if not _can_execute(caster_node, target_node):
		return false
	
	caster = caster_node
	target = target_node if target_node else caster_node
	
	is_active = true
	ability_started.emit(caster, target)
	
	_execute_ability()
	
	if ability_type == AbilityType.INSTANT:
		_end_ability()
	
	return true

func apply_to(target_node: Node):
	target = target_node
	is_active = true
	_apply_effect()

func remove_from(target_node: Node):
	if target_node == target:
		_remove_effect()
		is_active = false

func interrupt(reason: String = ""):
	if is_active:
		_remove_effect()
		is_active = false
		ability_interrupted.emit(reason)

# 虛擬方法，由子類實現
func _initialize_ability():
	pass

func _can_execute(caster_node: Node, target_node: Node) -> bool:
	return true

func _execute_ability():
	pass

func _apply_effect():
	pass

func _remove_effect():
	pass

func _end_ability():
	if is_active:
		_remove_effect()
		is_active = false
		ability_finished.emit(caster, target)

func cleanup():
	if is_active:
		interrupt("cleanup")
```

### 4.2 具體能力組件範例

#### 4.2.1 治療能力 (HealAbility)

```gdscript
# HealAbility.gd - 治療能力
class_name HealAbility
extends AbilityComponent

@export var heal_amount: int = 20
@export var heal_over_time: bool = false
@export var heal_per_tick: int = 5
@export var tick_interval: float = 1.0

var heal_timer: Timer = null

func _initialize_ability():
	ability_id = "heal"
	ability_name = "治療術"
	description = "恢復目標的生命值"
	target_type = TargetType.SINGLE
	
	if heal_over_time:
		ability_type = AbilityType.DURATION
		duration = 5.0
	else:
		ability_type = AbilityType.INSTANT

func _execute_ability():
	if not heal_over_time:
		# 瞬間治療
		_perform_heal(heal_amount)
	else:
		# 持續治療
		_start_heal_over_time()

func _perform_heal(amount: int):
	if target and target.has_method("heal"):
		target.heal(amount, caster)
		EventBus.healing_applied.emit(caster, target, amount)

func _start_heal_over_time():
	if heal_timer:
		heal_timer.queue_free()
	
	heal_timer = Timer.new()
	heal_timer.wait_time = tick_interval
	heal_timer.timeout.connect(_on_heal_tick)
	add_child(heal_timer)
	heal_timer.start()

func _on_heal_tick():
	if is_active and target:
		_perform_heal(heal_per_tick)

func _remove_effect():
	if heal_timer:
		heal_timer.stop()
		heal_timer.queue_free()
		heal_timer = null
```

#### 4.2.2 燃燒能力 (BurnAbility)

```gdscript
# BurnAbility.gd - 燃燒效果
class_name BurnAbility
extends AbilityComponent

@export var damage_per_tick: int = 3
@export var tick_interval: float = 1.0

var burn_timer: Timer = null
var visual_effect: Node2D = null

func _initialize_ability():
	ability_id = "burn"
	ability_name = "燃燒"
	description = "目標持續受到火焰傷害"
	ability_type = AbilityType.DURATION
	duration = 6.0
	target_type = TargetType.SINGLE

func _execute_ability():
	_start_burn_effect()

func _start_burn_effect():
	# 創建燃燒計時器
	burn_timer = Timer.new()
	burn_timer.wait_time = tick_interval
	burn_timer.timeout.connect(_on_burn_tick)
	add_child(burn_timer)
	burn_timer.start()
	
	# 創建視覺效果
	_create_visual_effect()

func _on_burn_tick():
	if is_active and target and target.has_method("take_damage"):
		target.take_damage(damage_per_tick, caster)
		EventBus.damage_dealt.emit(caster, target, damage_per_tick, "fire")

func _create_visual_effect():
	# 創建燃燒粒子效果
	visual_effect = preload("res://effects/BurnEffect.tscn").instantiate()
	if target:
		target.add_child(visual_effect)

func _remove_effect():
	if burn_timer:
		burn_timer.stop()
		burn_timer.queue_free()
		burn_timer = null
	
	if visual_effect:
		visual_effect.queue_free()
		visual_effect = null
```

#### 4.2.3 護盾能力 (ShieldAbility)

```gdscript
# ShieldAbility.gd - 護盾效果
class_name ShieldAbility
extends AbilityComponent

@export var shield_amount: int = 30
@export var absorb_percentage: float = 1.0  # 100% 吸收

var remaining_shield: int = 0
var original_take_damage_method: Callable

func _initialize_ability():
	ability_id = "shield"
	ability_name = "護盾"
	description = "為目標提供傷害吸收護盾"
	ability_type = AbilityType.DURATION
	duration = 10.0
	target_type = TargetType.SINGLE

func _execute_ability():
	remaining_shield = shield_amount
	_apply_shield()

func _apply_shield():
	if not target or not target.has_method("take_damage"):
		return
	
	# 保存原始的 take_damage 方法
	original_take_damage_method = target.take_damage
	
	# 替換為護盾版本的 take_damage
	target.take_damage = _shielded_take_damage
	
	# 發送護盾應用事件
	EventBus.effect_applied.emit(ability_id, target, duration)

func _shielded_take_damage(damage: int, source: Node = null):
	var absorbed_damage = min(damage * absorb_percentage, remaining_shield)
	var remaining_damage = damage - absorbed_damage
	
	remaining_shield -= absorbed_damage
	
	print("護盾吸收了 ", absorbed_damage, " 點傷害，剩餘護盾：", remaining_shield)
	
	# 如果還有剩餘傷害，使用原始方法處理
	if remaining_damage > 0:
		original_take_damage_method.call(remaining_damage, source)
	
	# 護盾消耗完畢
	if remaining_shield <= 0:
		_remove_effect()

func _remove_effect():
	if target and original_take_damage_method.is_valid():
		# 恢復原始的 take_damage 方法
		target.take_damage = original_take_damage_method
	
	EventBus.effect_expired.emit(ability_id, target)
```

---

## 五、資源管理與載入系統

### 5.1 資源管理器 (ResourceManager)

```gdscript
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
	_load_databases()
	_preload_common_scenes()

func _load_databases():
	# 載入各種資源的數據庫
	hero_database = _load_json_database("res://data/heroes.json")
	enemy_database = _load_json_database("res://data/enemies.json")
	block_database = _load_json_database("res://data/blocks.json")
	ability_database = _load_json_database("res://data/abilities.json")
	
	print("資源數據庫載入完成")

func _load_json_database(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_warning("Database file not found: " + file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Error parsing JSON: " + file_path)
		return {}
	
	return json.data

func _preload_common_scenes():
	# 預載入常用場景
	preloaded_scenes["hero"] = preload("res://scenes/Hero.tscn")
	preloaded_scenes["enemy"] = preload("res://scenes/Enemy.tscn") 
	preloaded_scenes["block"] = preload("res://scenes/Block.tscn")

# 英雄創建與管理
func create_hero(hero_id: String) -> Hero:
	var hero_data = hero_database.get(hero_id)
	if not hero_data:
		push_error("Hero data not found: " + hero_id)
		return null
	
	# 檢查是否有可重用的實例
	var pooled_hero = _get_from_pool("hero", hero_id)
	if pooled_hero:
		pooled_hero._load_from_data(HeroData.from_dict(hero_data))
		return pooled_hero
	
	# 創建新實例
	var hero_scene = preloaded_scenes.get("hero")
	if not hero_scene:
		push_error("Hero scene not preloaded")
		return null
	
	var hero_instance = hero_scene.instantiate()
	hero_instance._load_from_data(HeroData.from_dict(hero_data))
	
	EventBus.resource_loaded.emit("hero", hero_id)
	return hero_instance

func create_enemy(enemy_id: String) -> Enemy:
	var enemy_data = enemy_database.get(enemy_id)
	if not enemy_data:
		push_error("Enemy data not found: " + enemy_id)
		return null
	
	var pooled_enemy = _get_from_pool("enemy", enemy_id)
	if pooled_enemy:
		pooled_enemy._load_from_data(EnemyData.from_dict(enemy_data))
		return pooled_enemy
	
	var enemy_scene = preloaded_scenes.get("enemy")
	if not enemy_scene:
		push_error("Enemy scene not preloaded")
		return null
	
	var enemy_instance = enemy_scene.instantiate()
	enemy_instance._load_from_data(EnemyData.from_dict(enemy_data))
	
	EventBus.resource_loaded.emit("enemy", enemy_id)
	return enemy_instance

func create_block(block_id: String) -> Block:
	var block_data = block_database.get(block_id)
	if not block_data:
		push_error("Block data not found: " + block_id)
		return null
	
	var pooled_block = _get_from_pool("block", block_id)
	if pooled_block:
		pooled_block._load_from_data(BlockData.from_dict(block_data))
		return pooled_block
	
	var block_scene = preloaded_scenes.get("block")
	if not block_scene:
		push_error("Block scene not preloaded")
		return null
	
	var block_instance = block_scene.instantiate()
	block_instance._load_from_data(BlockData.from_dict(block_data))
	
	EventBus.resource_loaded.emit("block", block_id)
	return block_instance

# 物件池管理
func _get_from_pool(object_type: String, object_id: String) -> Node:
	var pool = _get_pool(object_type)
	if pool.has(object_id) and pool[object_id].size() > 0:
		return pool[object_id].pop_back()
	return null

func return_to_pool(object_instance: BaseGameObject):
	var object_type = object_instance.object_type
	var pool = _get_pool(object_type)
	
	if not pool.has(object_instance.object_id):
		pool[object_instance.object_id] = []
	
	# 清理物件狀態
	object_instance._cleanup_for_pool()
	pool[object_instance.object_id].append(object_instance)

func _get_pool(object_type: String) -> Dictionary:
	match object_type:
		"hero":
			return hero_pool
		"enemy":
			return enemy_pool
		"block":
			return block_pool
		_:
			push_warning("Unknown object type for pool: " + object_type)
			return {}

# 批量創建
func create_heroes_batch(hero_ids: Array[String]) -> Array[Hero]:
	var heroes: Array[Hero] = []
	for hero_id in hero_ids:
		var hero = create_hero(hero_id)
		if hero:
			heroes.append(hero)
	return heroes

func create_enemies_batch(enemy_ids: Array[String]) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for enemy_id in enemy_ids:
		var enemy = create_enemy(enemy_id)
		if enemy:
			enemies.append(enemy)
	return enemies

# 清理資源
func cleanup_unused_resources():
	# 清理超過一定數量的池化物件
	_cleanup_pool(hero_pool, 10)
	_cleanup_pool(enemy_pool, 20)
	_cleanup_pool(block_pool, 50)

func _cleanup_pool(pool: Dictionary, max_per_type: int):
	for object_id in pool.keys():
		var objects = pool[object_id]
		while objects.size() > max_per_type:
			var obj = objects.pop_back()
			obj.queue_free()
```

### 5.2 資料類型定義

```gdscript
# HeroData.gd - 英雄數據結構
class_name HeroData
extends Resource

@export var hero_id: String = ""
@export var hero_name: String = ""
@export var description: String = ""
@export var element: String = "neutral"
@export var rarity: int = 1  # 1-5 星
@export var base_hp: int = 100
@export var base_attack: int = 10
@export var base_defense: int = 5
@export var has_shield: bool = false
@export var skills: Array[Dictionary] = []

static func from_dict(data: Dictionary) -> HeroData:
	var hero_data = HeroData.new()
	hero_data.hero_id = data.get("id", "")
	hero_data.hero_name = data.get("name", "")
	hero_data.description = data.get("description", "")
	hero_data.element = data.get("element", "neutral")
	hero_data.rarity = data.get("rarity", 1)
	hero_data.base_hp = data.get("base_hp", 100)
	hero_data.base_attack = data.get("base_attack", 10)
	hero_data.base_defense = data.get("base_defense", 5)
	hero_data.has_shield = data.get("has_shield", false)
	hero_data.skills = data.get("skills", [])
	return hero_data
```

```gdscript
# EnemyData.gd - 敵人數據結構
class_name EnemyData
extends Resource

@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export var description: String = ""
@export var base_hp: int = 50
@export var base_attack: int = 8
@export var countdown_time: int = 3
@export var has_ai: bool = false
@export var exp_reward: int = 10
@export var gold_reward: int = 5
@export var special_abilities: Array[String] = []

static func from_dict(data: Dictionary) -> EnemyData:
	var enemy_data = EnemyData.new()
	enemy_data.enemy_id = data.get("id", "")
	enemy_data.enemy_name = data.get("name", "")
	enemy_data.description = data.get("description", "")
	enemy_data.base_hp = data.get("base_hp", 50)
	enemy_data.base_attack = data.get("base_attack", 8)
	enemy_data.countdown_time = data.get("countdown_time", 3)
	enemy_data.has_ai = data.get("has_ai", false)
	enemy_data.exp_reward = data.get("exp_reward", 10)
	enemy_data.gold_reward = data.get("gold_reward", 5)
	enemy_data.special_abilities = data.get("special_abilities", [])
	return enemy_data
```

```gdscript
# BlockData.gd - 凸塊數據結構
class_name BlockData
extends Resource

@export var block_id: String = ""
@export var block_name: String = ""
@export var description: String = ""
@export var element: String = "neutral"
@export var base_attack: int = 1
@export var rarity: int = 1
@export var special_effects: Array[String] = []

static func from_dict(data: Dictionary) -> BlockData:
	var block_data = BlockData.new()
	block_data.block_id = data.get("id", "")
	block_data.block_name = data.get("name", "")
	block_data.description = data.get("description", "")
	block_data.element = data.get("element", "neutral")
	block_data.base_attack = data.get("base_attack", 1)
	block_data.rarity = data.get("rarity", 1)
	block_data.special_effects = data.get("special_effects", [])
	return block_data
```

---

## 六、擴展性設計

### 6.1 新增物件類型

要新增一個新的物件類型（例如「道具」），只需要：

1. **繼承 BaseGameObject**：
```gdscript
class_name Item
extends BaseGameObject

func _init(id: String = "", data: ItemData = null):
	super._init(id, "item")
```

2. **定義對應的數據結構**：
```gdscript
class_name ItemData
extends Resource
```

3. **在 ResourceManager 中添加支援**：
```gdscript
var item_database: Dictionary = {}
var item_pool: Dictionary = {}

func create_item(item_id: String) -> Item:
	# 實現創建邏輯
```

4. **在 EventBus 中添加相關事件**：
```gdscript
signal item_used(item_instance: Item, target: Node)
signal item_consumed(item_id: String)
```

### 6.2 新增能力組件

要新增一個新的能力效果，只需要：

1. **繼承 AbilityComponent**：
```gdscript
class_name NewAbility
extends AbilityComponent

func _initialize_ability():
	ability_id = "new_ability"
	# 設定能力屬性

func _execute_ability():
	# 實現能力效果
```

2. **在 AbilityComponent.create_by_id 中註冊**：
```gdscript
"new_ability":
	return NewAbility.new()
```

3. **在資料庫中配置**：
```json
{
	"id": "new_ability",
	"name": "新能力",
	"description": "新能力的描述"
}
```

### 6.3 擴展 EventBus

隨著系統複雜度增加，可以考慮將 EventBus 拆分為多個專門的事件管理器：

```gdscript
# BattleEventBus.gd - 專門處理戰鬥事件
# UIEventBus.gd - 專門處理 UI 事件  
# SystemEventBus.gd - 專門處理系統事件
```

### 6.4 效能優化考慮

1. **物件池大小調整**：根據實際使用情況調整池化物件的最大數量
2. **事件監聽優化**：避免過多的事件監聽器，考慮使用事件聚合
3. **組件快取**：對頻繁查詢的組件進行快取
4. **批量處理**：對大量物件的批量操作進行優化

---

## 七、測試與除錯

### 7.1 除錯工具

```gdscript
# DebugManager.gd - 除錯工具
extends Node

var debug_panel: Control
var object_inspector: Control

func _ready():
	if OS.is_debug_build():
		_setup_debug_tools()

func _setup_debug_tools():
	# 創建除錯面板
	debug_panel = preload("res://debug/DebugPanel.tscn").instantiate()
	get_tree().current_scene.add_child(debug_panel)

func log_object_creation(object: BaseGameObject):
	print("[DEBUG] Object created: ", object.object_id, " (", object.object_type, ")")

func log_event_emission(event_name: String, data: Dictionary):
	print("[DEBUG] Event emitted: ", event_name, " with data: ", data)

func inspect_object(object: BaseGameObject):
	print("=== Object Inspector ===")
	print("ID: ", object.object_id)
	print("Type: ", object.object_type)
	print("Components: ", object.components.keys())
	print("Effects: ", object.effects.size())
	print("======================")
```

### 7.2 單元測試範例

```gdscript
# TestHero.gd - 英雄類別測試
extends "res://addons/gut/test.gd"

func test_hero_creation():
	var hero_data = HeroData.new()
	hero_data.hero_id = "test_hero"
	hero_data.base_hp = 100
	
	var hero = Hero.new("test_hero_1", hero_data)
	assert_eq(hero.object_id, "test_hero_1")
	assert_eq(hero.max_hp, 100)
	assert_eq(hero.current_hp, 100)

func test_hero_take_damage():
	var hero = Hero.new()
	hero.max_hp = 100
	hero.current_hp = 100
	
	hero.take_damage(30)
	assert_eq(hero.current_hp, 70)

func test_ability_component():
	var heal_ability = HealAbility.new()
	heal_ability.heal_amount = 25
	
	var hero = Hero.new()
	hero.current_hp = 50
	hero.max_hp = 100
	
	heal_ability.execute(hero, hero)
	assert_eq(hero.current_hp, 75)
```

---

## 八、實際使用指南

### 8.1 項目設置步驟

#### 步驟 1：配置 AutoLoad 單例

在 Godot 編輯器中，進入 **Project → Project Settings → AutoLoad**，按順序添加以下單例：

```
1. EventBus          →  res://singletons/EventBus.gd
2. ResourceManager   →  res://singletons/ResourceManager.gd  
3. DebugManager      →  res://singletons/DebugManager.gd
```

> ⚠️ **注意順序**：EventBus 必須最先載入，因為其他單例會依賴它。

#### 步驟 2：創建資料夾結構

```
res://
├── singletons/
│   ├── EventBus.gd
│   ├── ResourceManager.gd
│   └── DebugManager.gd
├── data/
│   ├── heroes.json
│   ├── enemies.json
│   ├── blocks.json
│   └── abilities.json
├── scenes/
│   ├── Hero.tscn
│   ├── Enemy.tscn
│   └── Block.tscn
├── scripts/
│   ├── BaseGameObject.gd
│   ├── Hero.gd
│   ├── Enemy.gd
│   ├── Block.gd
│   └── components/
│       ├── AbilityComponent.gd
│       ├── HealAbility.gd
│       ├── BurnAbility.gd
│       └── ShieldAbility.gd
└── effects/
    ├── BurnEffect.tscn
    └── HealEffect.tscn
```

#### 步驟 3：創建數據文件

**heroes.json** 範例：
```json
{
  "hero_001": {
    "id": "hero_001",
    "name": "火焰劍士",
    "description": "擅長火屬性攻擊的劍士",
    "element": "fire",
    "rarity": 3,
    "base_hp": 120,
    "base_attack": 15,
    "base_defense": 8,
    "has_shield": false,
    "skills": [
      {
        "id": "flame_strike",
        "name": "烈焰斬擊",
        "cooldown": 3.0
      }
    ]
  }
}
```

**enemies.json** 範例：
```json
{
  "slime_001": {
    "id": "slime_001", 
    "name": "綠色史萊姆",
    "description": "基礎敵人",
    "base_hp": 30,
    "base_attack": 5,
    "countdown_time": 4,
    "has_ai": false,
    "exp_reward": 8,
    "gold_reward": 3,
    "special_abilities": []
  }
}
```

### 8.2 EventBus 使用方法

#### 發送事件

```gdscript
# 在任何腳本中發送事件
func start_battle():
    var level_data = {
        "level_id": "level_001",
        "enemies": ["slime_001", "goblin_001"],
        "difficulty": 1
    }
    EventBus.battle_started.emit(level_data)

# 使用便利方法發送事件  
func defeat_enemy():
    EventBus.emit_object_event("defeated", "enemy", enemy_instance, {
        "id": enemy_instance.object_id,
        "rewards": {"exp": 10, "gold": 5}
    })
```

#### 監聽事件

```gdscript
# 在場景或管理器中監聽事件
extends Node

func _ready():
    # 連接事件監聽
    EventBus.battle_started.connect(_on_battle_started)
    EventBus.enemy_defeated.connect(_on_enemy_defeated)
    EventBus.damage_dealt.connect(_on_damage_dealt)
    
    # 也可以使用一次性連接
    EventBus.level_completed.connect(_on_level_completed, CONNECT_ONE_SHOT)

func _on_battle_started(level_data: Dictionary):
    print("戰鬥開始！關卡：", level_data.level_id)
    # 初始化戰鬥UI
    battle_ui.setup_level(level_data)

func _on_enemy_defeated(enemy_id: String, rewards: Dictionary):
    print("敵人 ", enemy_id, " 被擊敗")
    # 顯示獎勵
    ui_manager.show_rewards(rewards)
    
func _on_damage_dealt(source: Node, target: Node, amount: int, type: String):
    # 播放傷害特效
    effect_manager.play_damage_effect(target.global_position, amount, type)
```

### 8.3 ResourceManager 使用方法

#### 創建物件

```gdscript
# 創建英雄
func setup_player_team():
    var hero = ResourceManager.create_hero("hero_001")
    if hero:
        add_child(hero)
        hero.position = Vector2(100, 200)
        
        # 連接英雄事件
        hero.hp_changed.connect(_on_hero_hp_changed)
        hero.skill_used.connect(_on_hero_skill_used)

# 創建敵人
func spawn_enemies():
    var enemy_ids = ["slime_001", "goblin_001"] 
    var enemies = ResourceManager.create_enemies_batch(enemy_ids)
    
    for i in range(enemies.size()):
        var enemy = enemies[i]
        add_child(enemy)
        enemy.position = Vector2(300 + i * 100, 150)
        
        # 設定敵人到群組
        enemy.add_to_group("enemies")

# 創建凸塊
func setup_player_blocks():
    var block_ids = ["fire_block", "water_block", "heal_block"]
    
    for i in range(block_ids.size()):
        var block = ResourceManager.create_block(block_ids[i])
        if block:
            add_child(block)
            block.position = Vector2(50 + i * 60, 400)
```

#### 回收物件到池

```gdscript
func cleanup_battle():
    # 回收所有敵人到物件池
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        enemy.remove_from_group("enemies")
        remove_child(enemy)
        ResourceManager.return_to_pool(enemy)
    
    # 回收使用完的凸塊
    for block in used_blocks:
        ResourceManager.return_to_pool(block)
```

### 8.4 實戰範例：創建戰鬥場景

這是一個完整的戰鬥場景設置範例：

```gdscript
# BattleScene.gd
extends Node2D

var current_hero: Hero = null
var current_enemies: Array[Enemy] = []
var available_blocks: Array[Block] = []

func _ready():
    # 連接全域事件
    EventBus.battle_started.connect(_on_battle_started)
    EventBus.enemy_defeated.connect(_on_enemy_defeated)
    EventBus.block_placed.connect(_on_block_placed)
    
func start_battle(level_id: String):
    # 發送戰鬥開始事件
    var level_data = {
        "level_id": level_id,
        "hero_id": "hero_001", 
        "enemy_ids": ["slime_001", "goblin_001"],
        "available_blocks": ["fire_block", "water_block", "heal_block", "shield_block"]
    }
    EventBus.battle_started.emit(level_data)

func _on_battle_started(level_data: Dictionary):
    print("=== 戰鬥開始 ===")
    
    # 1. 創建英雄
    _setup_hero(level_data.hero_id)
    
    # 2. 創建敵人
    _setup_enemies(level_data.enemy_ids)
    
    # 3. 準備凸塊
    _setup_blocks(level_data.available_blocks)
    
    print("戰鬥場景設置完成")

func _setup_hero(hero_id: String):
    current_hero = ResourceManager.create_hero(hero_id)
    if current_hero:
        add_child(current_hero)
        current_hero.position = Vector2(200, 300)
        current_hero.add_to_group("heroes")
        
        # 連接英雄特定事件
        current_hero.hp_changed.connect(_on_hero_hp_changed)
        current_hero.skill_ready.connect(_on_hero_skill_ready)
        
        print("英雄創建成功：", current_hero.object_name)

func _setup_enemies(enemy_ids: Array):
    current_enemies = ResourceManager.create_enemies_batch(enemy_ids)
    
    for i in range(current_enemies.size()):
        var enemy = current_enemies[i]
        add_child(enemy)
        enemy.position = Vector2(500 + i * 80, 200)
        enemy.add_to_group("enemies")
        
        # 連接敵人事件
        enemy.countdown_zero.connect(_on_enemy_attack.bind(enemy))
        enemy.hp_changed.connect(_on_enemy_hp_changed.bind(enemy))
        
        print("敵人生成：", enemy.object_name)

func _setup_blocks(block_ids: Array):
    for i in range(min(block_ids.size(), 4)):  # 最多4個凸塊
        var block = ResourceManager.create_block(block_ids[i])
        if block:
            add_child(block)
            block.position = Vector2(100 + i * 70, 450)
            available_blocks.append(block)
            
            # 設定拖拽功能（假設有拖拽組件）
            block.add_component("DragComponent", DragComponent.new())
            
        print("凸塊準備：", block.object_name)

# 事件處理函數
func _on_hero_hp_changed(old_hp: int, new_hp: int):
    print("英雄血量變化：", old_hp, " → ", new_hp)
    # 更新UI血條
    ui_manager.update_hero_hp_bar(new_hp, current_hero.max_hp)

func _on_hero_skill_ready(skill_id: String):
    print("英雄技能準備就緒：", skill_id)
    # 高亮技能按鈕
    ui_manager.highlight_skill_button(skill_id)

func _on_enemy_attack(enemy: Enemy):
    print("敵人 ", enemy.object_name, " 發動攻擊！")
    # 敵人攻擊英雄
    if current_hero:
        current_hero.take_damage(enemy.attack_power, enemy)

func _on_enemy_hp_changed(enemy: Enemy, old_hp: int, new_hp: int):
    print("敵人 ", enemy.object_name, " 血量：", old_hp, " → ", new_hp)
    # 更新敵人血條
    ui_manager.update_enemy_hp_bar(enemy.object_id, new_hp, enemy.max_hp)

func _on_enemy_defeated(enemy_id: String, rewards: Dictionary):
    print("敵人被擊敗，獲得獎勵：", rewards)
    
    # 移除敵人
    for i in range(current_enemies.size() - 1, -1, -1):
        if current_enemies[i].object_id == enemy_id:
            var defeated_enemy = current_enemies[i]
            current_enemies.remove_at(i)
            
            # 播放擊敗動畫
            _play_defeat_animation(defeated_enemy)
            
            # 回收到物件池
            ResourceManager.return_to_pool(defeated_enemy)
            break
    
    # 檢查勝利條件
    if current_enemies.size() == 0:
        _handle_victory()

func _on_block_placed(block: Block, position: Vector2):
    print("凸塊被放置：", block.object_name, " 位置：", position)
    # 執行凸塊效果
    _execute_block_effect(block)

func _execute_block_effect(block: Block):
    # 找到目標（通常是敵人）
    var targets = get_tree().get_nodes_in_group("enemies")
    if targets.size() > 0:
        var target = targets[0]  # 簡單選擇第一個敵人
        
        # 使用凸塊攻擊目標
        var success = block.use_on_target(target)
        if success:
            print("凸塊 ", block.object_name, " 攻擊了 ", target.object_name)

func _play_defeat_animation(enemy: Enemy):
    # 播放擊敗動畫
    var tween = create_tween()
    tween.tween_property(enemy, "modulate", Color.TRANSPARENT, 0.5)
    tween.tween_callback(enemy.queue_free)

func _handle_victory():
    print("=== 戰鬥勝利！ ===")
    EventBus.level_completed.emit("current_level", 100)
    
    # 清理戰鬥場景
    _cleanup_battle()

func _cleanup_battle():
    # 回收英雄
    if current_hero:
        ResourceManager.return_to_pool(current_hero)
        current_hero = null
    
    # 回收剩餘的凸塊
    for block in available_blocks:
        ResourceManager.return_to_pool(block)
    available_blocks.clear()
    
    print("戰鬥場景清理完成")
```

### 8.5 常見問題與解決方案

#### Q1: EventBus 事件沒有被觸發？

**解決方案**：
```gdscript
# 檢查事件連接是否成功
func _ready():
    if EventBus.battle_started.connect(_on_battle_started) != OK:
        push_error("Failed to connect battle_started signal")
    
    # 確認 EventBus 已經載入
    if not EventBus:
        push_error("EventBus not loaded!")
```

#### Q2: ResourceManager 創建物件失敗？

**解決方案**：
```gdscript
# 檢查資源是否存在
func create_hero_safe(hero_id: String) -> Hero:
    if not ResourceManager.hero_database.has(hero_id):
        push_error("Hero ID not found: " + hero_id)
        return null
    
    var hero = ResourceManager.create_hero(hero_id)
    if not hero:
        push_error("Failed to create hero: " + hero_id)
        return null
    
    return hero
```

#### Q3: 物件池回收時出現錯誤？

**解決方案**：
```gdscript
# 在 BaseGameObject 中添加池回收準備
func _cleanup_for_pool():
    # 清理所有效果
    for effect in effects:
        effect.interrupt("pool_cleanup")
    effects.clear()
    
    # 重置狀態
    if has_method("reset_to_default"):
        reset_to_default()
    
    # 斷開所有信號連接
    for connection in get_incoming_connections():
        connection.signal.disconnect(connection.callable)
```

#### Q4: 如何在編輯器中測試單例？

**解決方案**：
```gdscript
# 創建測試腳本 TestSingletons.gd
@tool
extends EditorScript

func _run():
    # 測試 ResourceManager
    print("Testing ResourceManager...")
    var heroes_data = ResourceManager.hero_database
    print("Heroes loaded: ", heroes_data.keys())
    
    # 測試事件發送
    print("Testing EventBus...")
    EventBus.battle_started.emit({"test": true})
```

#### Q5: 性能優化建議？

**最佳實踐**：
```gdscript
# 1. 批量創建物件
func create_multiple_enemies():
    var enemy_ids = ["slime_001", "slime_001", "slime_001"]
    var enemies = ResourceManager.create_enemies_batch(enemy_ids)
    # 比逐個創建效率更高

# 2. 及時清理事件監聽
func _exit_tree():
    EventBus.battle_started.disconnect(_on_battle_started)
    EventBus.enemy_defeated.disconnect(_on_enemy_defeated)

# 3. 使用物件池避免頻繁實例化
func get_projectile() -> Projectile:
    return ResourceManager.get_from_pool("projectile", "basic_arrow")
```

---

## 九、總結

本文檔建立了一個完整的物件導向架構，具備以下特點：

1. **模組化設計**：每個物件類型都有清晰的責任分工
2. **組件化架構**：使用組件系統實現靈活的能力擴展
3. **事件驅動**：通過 EventBus 實現低耦合的系統通訊
4. **資源管理**：完整的資源載入、池化和生命週期管理
5. **擴展性**：便於新增物件類型、能力組件和功能特性

**使用這些單例的核心原則**：
- ✅ **EventBus**：用於跨場景、跨物件的通訊
- ✅ **ResourceManager**：用於統一管理遊戲物件的創建和回收
- ✅ **遵循生命週期**：正確地連接和斷開事件，及時回收資源
- ✅ **錯誤處理**：添加適當的檢查和錯誤處理機制

這個架構為 Ninefold Fate 遊戲提供了堅實的技術基礎，能夠支援後續的功能迭代和內容擴展。

---

*本文件將隨開發進度持續更新和完善*