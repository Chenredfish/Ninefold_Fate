# SkillComponent.gd - 英雄技能組件
extends Node

var skills: Array = []
var passive_skills: Array = []
var active_skills: Array = []

func _ready():
	skills = get_meta("skills", [])
	_categorize_skills()
	_setup_passive_skills()
	
	# 連接戰鬥事件
	var eb = get_node_or_null("/root/EventBus")
	if eb:
		eb.battle_started.connect(_on_battle_started)
		eb.turn_started.connect(_on_turn_started)
		eb.turn_ended.connect(_on_turn_ended)

func _categorize_skills():
	passive_skills.clear()
	active_skills.clear()
	
	for skill in skills:
		if skill.skill_type == "passive":
			passive_skills.append(skill)
		else:
			active_skills.append(skill)

func _setup_passive_skills():
	# 被動技能立即生效
	for passive_skill in passive_skills:
		print("[SkillComponent] 啟用被動技能: ", passive_skill.skill_name)

# 主動技能使用
func use_skill(skill_id: String, target: Node = null, position: Vector2 = Vector2.ZERO) -> bool:
	var skill = get_skill_by_id(skill_id)
	if not skill:
		push_warning("技能不存在: " + skill_id)
		return false
	
	return skill.activate(target, position)

func get_skill_by_id(skill_id: String) -> BaseSkill:
	for skill in skills:
		if skill.skill_id == skill_id:
			return skill
	return null

func get_skills() -> Array:
	return skills

func get_active_skills() -> Array:
	return active_skills

func get_passive_skills() -> Array:
	return passive_skills

# 傷害修正 - 被動技能介入點
func modify_outgoing_damage(damage_info: Dictionary) -> Dictionary:
	var modified_info = damage_info.duplicate()
	
	for passive_skill in passive_skills:
		modified_info = passive_skill.on_damage_dealt(modified_info)
	
	return modified_info

func modify_incoming_damage(damage_info: Dictionary) -> Dictionary:
	var modified_info = damage_info.duplicate()
	
	for passive_skill in passive_skills:
		modified_info = passive_skill.on_damage_received(modified_info)
	
	return modified_info

# 戰鬥事件回調
func _on_battle_started(level_data: Dictionary):
	for skill in skills:
		skill.on_battle_start()

func _on_turn_started(turn_number: int):
	for skill in skills:
		skill.on_turn_start()

func _on_turn_ended():
	for skill in skills:
		skill.on_turn_end()

# 技能升級
func upgrade_skill(skill_id: String) -> bool:
	var skill = get_skill_by_id(skill_id)
	if skill:
		return skill.level_up()
	return false

# 獲取技能資訊（供 UI 顯示）
func get_skills_info() -> Array:
	var info_array: Array = []
	
	for skill in skills:
		info_array.append(skill.get_skill_info())
	
	return info_array

# 檢查技能可用性
func can_use_skill(skill_id: String) -> bool:
	var skill = get_skill_by_id(skill_id)
	if skill:
		return skill.can_activate()
	return false