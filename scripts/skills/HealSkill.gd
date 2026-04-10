# HealSkill.gd - 治療術主動技能
class_name HealSkill
extends BaseSkill

func can_activate() -> bool:
	if not super.can_activate():
		return false
	
	# 檢查魔力是否足夠
	var mana_cost = parameters.get("mana_cost", 0)
	if owner and owner.has_method("get_current_mana"):
		return owner.get_current_mana() >= mana_cost
	
	return true

func execute(target: Node = null, position: Vector2 = Vector2.ZERO) -> bool:
	# 如果沒有指定目標，治療自己
	if not target:
		target = owner

	if not target:
		push_warning("HealSkill：沒有可治療的目標")
		return false

	# 消耗魔力
	var mana_cost = parameters.get("mana_cost", 0)
	if owner and owner.has_method("consume_mana"):
		if not owner.consume_mana(mana_cost):
			return false

	# 創建治療視覺效果
	_create_heal_effect(target.global_position)

	# 透過 EventBus 請求治療效果，由 BattleStateMachine 執行
	var heal_amount = parameters.get("heal_amount", 100)
	EventBus.skill_effect_requested.emit({
		"type": "heal",
		"amount": heal_amount,
		"source": owner,
		"target": target,
		"skill_id": skill_id
	})

	print("[Heal] ", owner.name if owner else "?", " 對 ", target.name, " 請求治療 ", heal_amount, " 點")
	return true

func _create_heal_effect(target_pos: Vector2):
	# 創建治療光效
	var heal_effect = Node2D.new()
	var sprite = ColorRect.new()
	sprite.size = Vector2(64, 64)
	sprite.color = Color.GREEN
	sprite.position = Vector2(-32, -32)
	heal_effect.add_child(sprite)
	
	# 添加到場景
	if owner and owner.get_parent():
		owner.get_parent().add_child(heal_effect)
		heal_effect.global_position = target_pos
		
		# 創建閃爍效果
		var tween = heal_effect.create_tween()
		tween.set_loops(3)
		tween.tween_property(sprite, "modulate:a", 0.3, 0.2)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
		tween.tween_callback(heal_effect.queue_free)