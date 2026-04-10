# FireballSkill.gd - 火球術主動技能
class_name FireballSkill
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
	if not target:
		push_warning("FireballSkill需要目標")
		return false

	# 消耗魔力
	var mana_cost = parameters.get("mana_cost", 0)
	if owner and owner.has_method("consume_mana"):
		if not owner.consume_mana(mana_cost):
			return false

	# 創建火球視覺效果（動畫本身不阻塞邏輯）
	_create_fireball_effect(owner.global_position, target.global_position)

	# 透過 EventBus 請求傷害效果，由 BattleStateMachine 執行
	var base_damage = parameters.get("base_damage", 100)
	EventBus.skill_effect_requested.emit({
		"type": "damage",
		"amount": base_damage,
		"element": "fire",
		"source": owner,
		"target": target,
		"skill_id": skill_id
	})

	print("[Fireball] ", owner.name if owner else "?", " 對 ", target.name, " 請求造成 ", base_damage, " 火焰傷害")
	return true

func _create_fireball_effect(start_pos: Vector2, end_pos: Vector2):
	# 創建視覺效果
	var fireball = Node2D.new()
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.color = Color.ORANGE
	sprite.position = Vector2(-16, -16)
	fireball.add_child(sprite)
	
	# 添加到場景
	if owner and owner.get_parent():
		owner.get_parent().add_child(fireball)
		fireball.global_position = start_pos
		
		# 創建移動動畫
		var tween = fireball.create_tween()
		tween.tween_property(fireball, "global_position", end_pos, 0.5)
		tween.tween_callback(fireball.queue_free)