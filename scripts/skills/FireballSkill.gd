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
	
	# 計算傷害
	var base_damage = parameters.get("base_damage", 100)
	var damage_info = {
		"amount": base_damage,
		"element": "fire",
		"source": owner,
		"skill_id": skill_id,
		"type": "spell"
	}
	
	# 創建火球效果
	_create_fireball_effect(owner.global_position, target.global_position)
	
	# 等待一段時間後造成傷害（模擬飛行時間）
	await get_tree().create_timer(0.5).timeout
	
	# 對目標造成傷害
	if target and target.has_method("take_damage"):
		target.take_damage(damage_info)
	
	# 發送事件
	var scene_tree = Engine.get_main_loop() as SceneTree
	if scene_tree and scene_tree.current_scene:
		var eb = scene_tree.get_first_node_in_group("autoload_eventbus")
		if eb and eb.has_signal("ability_triggered"):
			eb.ability_triggered.emit(skill_id, owner, target)
			eb.damage_dealt.emit(owner, target, base_damage, "fire")
	
	print("[Fireball] ", owner.name, " 對 ", target.name, " 造成 ", base_damage, " 火焰傷害")
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