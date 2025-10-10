# BaseSkill.gd - 技能基類
class_name BaseSkill
extends RefCounted

# 技能數據
var skill_id: String
var skill_name: String
var skill_type: String  # "active", "passive", "trigger"
var skill_category: String
var parameters: Dictionary
var current_level: int = 1
var max_level: int = 1
var owner: Node  # 技能持有者

# 狀態
var is_on_cooldown: bool = false
var cooldown_remaining: float = 0.0

func _init(skill_data: Dictionary, skill_owner: Node = null):
	setup_from_data(skill_data)
	owner = skill_owner

func setup_from_data(skill_data: Dictionary):
	skill_id = skill_data.get("id", "")
	skill_name = _get_localized_name(skill_data.get("name", {}))
	skill_type = skill_data.get("type", "passive")
	skill_category = skill_data.get("category", "")
	parameters = skill_data.get("parameters", {})
	max_level = skill_data.get("max_level", 1)
	
	# 從數據中設定等級相關的參數
	_apply_level_scaling(skill_data.get("level_scaling", {}))

func _get_localized_name(name_data: Dictionary) -> String:
	var scene_tree = Engine.get_main_loop() as SceneTree
	var rm = null
	if scene_tree:
		rm = scene_tree.get_nodes_in_group("autoload_resource_manager")
		rm = rm[0] if rm.size() > 0 else null
	var language = rm.current_language if rm else "zh"
	return name_data.get(language, name_data.get("zh", skill_id))

func _apply_level_scaling(scaling_data: Dictionary):
	# 根據當前等級設定參數
	for param_name in scaling_data:
		var scaling_array = scaling_data[param_name]
		if scaling_array is Array and current_level <= scaling_array.size():
			parameters[param_name] = scaling_array[current_level - 1]

# 虛擬方法 - 子類重寫
func can_activate() -> bool:
	if skill_type == "passive":
		return false  # 被動技能不能主動激活
	return not is_on_cooldown

func activate(target: Node = null, position: Vector2 = Vector2.ZERO) -> bool:
	if not can_activate():
		return false
	
	var success = execute(target, position)
	if success and skill_type == "active":
		start_cooldown()
	
	return success

func execute(target: Node = null, position: Vector2 = Vector2.ZERO) -> bool:
	# 子類重寫此方法實現具體功能
	push_warning("BaseSkill.execute() should be overridden in subclass")
	return false

func start_cooldown():
	var cooldown_time = parameters.get("cooldown", 0.0)
	if cooldown_time > 0:
		is_on_cooldown = true
		cooldown_remaining = cooldown_time
		
		# 創建計時器
		var timer = Timer.new()
		timer.wait_time = cooldown_time
		timer.one_shot = true
		timer.timeout.connect(_on_cooldown_finished)
		
		# 添加到場景樹中
		if owner and owner.is_inside_tree():
			owner.add_child(timer)
			timer.start()
		else:
			# 如果沒有 owner，直接結束冷卻
			_on_cooldown_finished()

func _on_cooldown_finished():
	is_on_cooldown = false
	cooldown_remaining = 0.0

# 被動技能相關方法
func on_damage_dealt(damage_info: Dictionary) -> Dictionary:
	# 子類可重寫此方法來修改傷害
	return damage_info

func on_damage_received(damage_info: Dictionary) -> Dictionary:
	# 子類可重寫此方法來修改接受的傷害
	return damage_info

func on_turn_start():
	# 回合開始時調用
	pass

func on_turn_end():
	# 回合結束時調用
	pass

func on_battle_start():
	# 戰鬥開始時調用
	pass

func on_battle_end():
	# 戰鬥結束時調用
	pass

# 技能升級
func level_up() -> bool:
	if current_level < max_level:
		current_level += 1
		# 重新應用等級縮放 - 暂时跳过动态重载，使用静态参数
		print("[BaseSkill] 技能 ", skill_id, " 升级到等级 ", current_level)
		return true
	return false

func get_skill_info() -> Dictionary:
	return {
		"id": skill_id,
		"name": skill_name,
		"type": skill_type,
		"category": skill_category,
		"level": current_level,
		"max_level": max_level,
		"is_on_cooldown": is_on_cooldown,
		"cooldown_remaining": cooldown_remaining,
		"parameters": parameters
	}