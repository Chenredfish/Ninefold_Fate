# SkillComponent.gd - 英雄技能組件，管理技能載入與事件路由
class_name SkillComponent
extends Node

var skills: Array = []


func _ready():
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.turn_started.connect(_on_turn_started)


# 從英雄 JSON 的 skills 陣列載入技能
func load_skills(skills_data: Array):
	skills.clear()
	for skill_entry in skills_data:
		var skill_id = skill_entry.get("id", "")
		if skill_id == "":
			push_warning("[SkillComponent] skill 缺少 id 欄位：%s" % str(skill_entry))
			continue
		var skill_data = SkillManager.get_skill_data(skill_id)
		if skill_data.is_empty():
			push_warning("[SkillComponent] 找不到技能資料：%s" % skill_id)
			continue
		var skill = BaseSkill.new(skill_data, get_parent())
		skills.append(skill)
		print("[SkillComponent] 載入技能：%s（trigger: %s）" % [skill_id, skill.trigger])


# 主動施放技能（by 技能按鈕）
func cast_skill(skill_id: String, context: Dictionary = {}) -> bool:
	var skill = _get_skill_by_id(skill_id)
	if not skill:
		push_warning("[SkillComponent] 找不到技能：%s" % skill_id)
		return false
	if skill.trigger != "on_cast":
		push_warning("[SkillComponent] 技能 %s 不是主動技能（trigger: %s）" % [skill_id, skill.trigger])
		return false
	return skill.activate(context)


# 傷害計算時呼叫，讓被動技能有機會修改傷害
func notify_damage_dealt(damage_info: Dictionary) -> Dictionary:
	return _notify_trigger("on_damage_dealt", {"damage_info": damage_info}).get("damage_info", damage_info)


func notify_damage_received(damage_info: Dictionary) -> Dictionary:
	return _notify_trigger("on_damage_received", {"damage_info": damage_info}).get("damage_info", damage_info)


# 通用觸發：找出所有符合 trigger 的技能，逐一檢查 conditions 後執行 effects
func _notify_trigger(trigger: String, context: Dictionary = {}) -> Dictionary:
	for skill in skills:
		if skill.trigger != trigger:
			continue
		if not skill.check_conditions(context):
			continue
		context = skill.execute_effects(context)
	return context


func _get_skill_by_id(skill_id: String) -> BaseSkill:
	for skill in skills:
		if skill.skill_id == skill_id:
			return skill
	return null


func get_active_skills() -> Array:
	return skills.filter(func(s): return s.trigger == "on_cast")


func get_skills_info() -> Array:
	return skills.map(func(s): return s.get_skill_info())


func can_cast_skill(skill_id: String) -> bool:
	var skill = _get_skill_by_id(skill_id)
	if not skill:
		return false
	return skill.check_conditions({})


# 戰鬥事件回調
func _on_battle_started(_level_data: Dictionary):
	_notify_trigger("on_battle_start")


func tick_cooldowns():
	for skill in skills:
		skill.tick_cooldown()


func _on_turn_started(turn_type: String):
	if turn_type == "player":
		tick_cooldowns()
		_notify_trigger("on_turn_start")
