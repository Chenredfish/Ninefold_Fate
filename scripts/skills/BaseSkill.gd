# BaseSkill.gd - 技能容器，從 JSON 讀取 trigger/conditions/effects 執行
class_name BaseSkill
extends RefCounted

var skill_id: String
var skill_name: String
var owner: Node

var trigger: String
var conditions: Array = []
var effects: Array = []

var current_level: int = 1
var max_level: int = 1
var max_uses: int = -1        # -1 表示無限制
var uses_remaining: int = -1

var is_on_cooldown: bool = false
var cooldown_remaining: float = 0.0


func _init(skill_data: Dictionary, skill_owner: Node = null):
	owner = skill_owner
	_setup_from_data(skill_data)


func _setup_from_data(skill_data: Dictionary):
	skill_id = skill_data.get("id", "")
	skill_name = _get_localized_name(skill_data.get("name", {}))
	max_level = skill_data.get("max_level", 1)

	trigger = skill_data.get("trigger", "")
	if trigger == "":
		push_warning("[BaseSkill] 技能 %s 缺少 trigger 欄位" % skill_id)

	conditions = skill_data.get("conditions", [])
	effects = skill_data.get("effects", []).duplicate(true)

	if skill_data.has("max_uses"):
		max_uses = skill_data.get("max_uses")
		uses_remaining = max_uses

	_apply_level_scaling(skill_data.get("level_scaling", {}))


func _get_localized_name(name_data: Dictionary) -> String:
	var language = ResourceManager.current_language if ResourceManager else "zh"
	return name_data.get(language, name_data.get("zh", skill_id))


func _apply_level_scaling(scaling: Dictionary):
	for path in scaling:
		var values = scaling[path]
		if not values is Array:
			push_warning("[BaseSkill] %s level_scaling[%s] 不是陣列" % [skill_id, path])
			continue
		if current_level > values.size():
			push_warning("[BaseSkill] %s level_scaling[%s] 陣列長度不足，需要 %d 個值" % [skill_id, path, current_level])
			continue
		_set_scaling_value(path, values[current_level - 1])


func _set_scaling_value(path: String, value):
	# 解析 "effects[0].amount" 格式
	var regex = RegEx.new()
	regex.compile("^(\\w+)\\[(\\d+)\\]\\.(\\w+)$")
	var result = regex.search(path)
	if not result:
		push_warning("[BaseSkill] %s level_scaling 路徑格式錯誤：%s（應為 effects[0].field）" % [skill_id, path])
		return
	var array_name = result.get_string(1)
	var index = int(result.get_string(2))
	var field = result.get_string(3)
	match array_name:
		"effects":
			if index >= effects.size():
				push_warning("[BaseSkill] %s level_scaling 路徑 %s 索引超出範圍（effects 共 %d 個）" % [skill_id, path, effects.size()])
				return
			effects[index][field] = value
		_:
			push_warning("[BaseSkill] %s level_scaling 不支援的陣列名稱：%s" % [skill_id, array_name])


# 檢查所有 conditions，context 帶入當前情境（target、damage_info 等）
func check_conditions(context: Dictionary = {}) -> bool:
	for c in conditions:
		if not c.has("type"):
			push_warning("[BaseSkill] %s 有一個 condition 缺少 type 欄位：%s" % [skill_id, str(c)])
			return false
		var passed = _check_single_condition(c, context)
		if not passed:
			return false
	return true


func _check_single_condition(c: Dictionary, context: Dictionary) -> bool:
	match c.get("type"):
		"not_on_cooldown":
			return not is_on_cooldown
		"has_mana":
			if not c.has("value"):
				push_warning("[BaseSkill] %s has_mana 缺少 value" % skill_id)
				return false
			if not owner or owner.get("current_mana") == null:
				return true  # owner 沒有 mana 系統，略過
			return owner.current_mana >= c.get("value", 0)
		"has_target":
			return context.get("target") != null
		"has_uses_remaining":
			return max_uses == -1 or uses_remaining > 0
		"damage_element_is":
			if not c.has("value"):
				push_warning("[BaseSkill] %s damage_element_is 缺少 value" % skill_id)
				return false
			var damage_info = context.get("damage_info", {})
			return damage_info.get("element", "") == c.get("value")
		"damage_above":
			if not c.has("value"):
				push_warning("[BaseSkill] %s damage_above 缺少 value" % skill_id)
				return false
			var damage_info = context.get("damage_info", {})
			return damage_info.get("amount", 0) > c.get("value", 0)
		"hp_below":
			if not owner or owner.max_hp <= 0:
				push_warning("[BaseSkill] %s hp_below 無法取得 owner HP" % skill_id)
				return false
			return float(owner.current_hp) / float(owner.max_hp) < c.get("percent", 0.3)
		"hp_above":
			if not owner or owner.max_hp <= 0:
				push_warning("[BaseSkill] %s hp_above 無法取得 owner HP" % skill_id)
				return false
			return float(owner.current_hp) / float(owner.max_hp) > c.get("percent", 0.5)
		_:
			push_warning("[BaseSkill] %s 未知的 condition type：%s" % [skill_id, c.get("type", "")])
			return false


# 執行所有 effects，回傳可能被修改的 context（供 multiply_damage 等被動使用）
func execute_effects(context: Dictionary = {}) -> Dictionary:
	for e in effects:
		if not e.has("type"):
			push_warning("[BaseSkill] %s 有一個 effect 缺少 type 欄位：%s" % [skill_id, str(e)])
			continue
		context = _execute_single_effect(e, context)
	return context


func _execute_single_effect(e: Dictionary, context: Dictionary) -> Dictionary:
	match e.get("type"):
		"damage":
			if not e.has("amount"):
				push_warning("[BaseSkill] %s damage effect 缺少 amount" % skill_id)
				return context
			EventBus.skill_effect_requested.emit({
				"type": "damage",
				"amount": e.get("amount"),
				"element": e.get("element", ""),
				"source": owner,
				"target": context.get("target"),
				"skill_id": skill_id
			})
		"damage_all_enemies":
			if not e.has("amount"):
				push_warning("[BaseSkill] %s damage_all_enemies effect 缺少 amount" % skill_id)
				return context
			EventBus.skill_effect_requested.emit({
				"type": "damage_all_enemies",
				"amount": e.get("amount"),
				"element": e.get("element", ""),
				"source": owner,
				"skill_id": skill_id
			})
		"damage_percent":
			if not e.has("percent"):
				push_warning("[BaseSkill] %s damage_percent effect 缺少 percent" % skill_id)
				return context
			var target = context.get("target")
			if target and target.get("current_hp") != null:
				var amount = int(float(target.current_hp) * e.get("percent", 0.0))
				EventBus.skill_effect_requested.emit({
					"type": "damage",
					"amount": amount,
					"element": "",
					"source": owner,
					"target": target,
					"skill_id": skill_id
				})
		"heal":
			if not e.has("amount"):
				push_warning("[BaseSkill] %s heal effect 缺少 amount" % skill_id)
				return context
			var target = context.get("target", owner)
			EventBus.skill_effect_requested.emit({
				"type": "heal",
				"amount": e.get("amount"),
				"source": owner,
				"target": target,
				"skill_id": skill_id
			})
		"heal_percent":
			if not e.has("percent"):
				push_warning("[BaseSkill] %s heal_percent effect 缺少 percent" % skill_id)
				return context
			var target = context.get("target", owner)
			if target and target.get("max_hp") != null:
				var amount = int(float(target.max_hp) * e.get("percent", 0.0))
				EventBus.skill_effect_requested.emit({
					"type": "heal",
					"amount": amount,
					"source": owner,
					"target": target,
					"skill_id": skill_id
				})
		"consume_mana":
			if not e.has("value"):
				push_warning("[BaseSkill] %s consume_mana effect 缺少 value" % skill_id)
				return context
			if owner and owner.has_method("consume_mana"):
				owner.consume_mana(e.get("value", 0))
		"restore_mana":
			if not e.has("value"):
				push_warning("[BaseSkill] %s restore_mana effect 缺少 value" % skill_id)
				return context
			if owner and owner.has_method("restore_mana"):
				owner.restore_mana(e.get("value", 0))
		"start_cooldown":
			_start_cooldown(e.get("duration", 0.0))
		"consume_use":
			if uses_remaining > 0:
				uses_remaining -= 1
		"gain_extra_turn":
			EventBus.skill_effect_requested.emit({
				"type": "gain_extra_turn",
				"source": owner,
				"skill_id": skill_id
			})
		"multiply_damage":
			if not e.has("value"):
				push_warning("[BaseSkill] %s multiply_damage effect 缺少 value" % skill_id)
				return context
			var damage_info = context.get("damage_info", {})
			if damage_info.is_empty():
				return context
			damage_info["amount"] = int(damage_info.get("amount", 0) * e.get("value", 1.0))
			damage_info["was_boosted"] = true
			damage_info["boost_source"] = skill_id
			context["damage_info"] = damage_info
		"multiply_healing":
			if not e.has("value"):
				push_warning("[BaseSkill] %s multiply_healing effect 缺少 value" % skill_id)
				return context
			var heal_info = context.get("heal_info", {})
			if heal_info.is_empty():
				return context
			heal_info["amount"] = int(heal_info.get("amount", 0) * e.get("value", 1.0))
			context["heal_info"] = heal_info
		"reduce_damage_taken":
			if not e.has("percent"):
				push_warning("[BaseSkill] %s reduce_damage_taken effect 缺少 percent" % skill_id)
				return context
			var damage_info = context.get("damage_info", {})
			if damage_info.is_empty():
				return context
			damage_info["amount"] = int(damage_info.get("amount", 0) * (1.0 - e.get("percent", 0.0)))
			context["damage_info"] = damage_info
		"apply_status", "add_tile_to_hand", "add_tile_to_deck", "affect_tile", "affect_board":
			push_warning("[BaseSkill] %s effect type '%s' 尚未實作" % [skill_id, e.get("type")])
		_:
			push_warning("[BaseSkill] %s 未知的 effect type：%s" % [skill_id, e.get("type", "")])
	return context


# 主動技能入口：檢查 conditions 後執行 effects
func activate(context: Dictionary = {}) -> bool:
	if not check_conditions(context):
		return false
	execute_effects(context)
	return true


func _start_cooldown(duration: float):
	if duration <= 0:
		return
	is_on_cooldown = true
	cooldown_remaining = duration
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_on_cooldown_finished)
	if owner and owner.is_inside_tree():
		owner.add_child(timer)
		timer.start()
	else:
		_on_cooldown_finished()


func _on_cooldown_finished():
	is_on_cooldown = false
	cooldown_remaining = 0.0


func level_up() -> bool:
	if current_level >= max_level:
		return false
	current_level += 1
	return true


func get_skill_info() -> Dictionary:
	return {
		"id": skill_id,
		"name": skill_name,
		"trigger": trigger,
		"level": current_level,
		"max_level": max_level,
		"uses_remaining": uses_remaining,
		"max_uses": max_uses,
		"is_on_cooldown": is_on_cooldown,
		"cooldown_remaining": cooldown_remaining
	}
