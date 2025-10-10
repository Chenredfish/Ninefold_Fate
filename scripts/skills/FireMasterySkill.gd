# FireMasterySkill.gd - 火焰精通被動技能
class_name FireMasterySkill
extends BaseSkill

func execute(target: Node = null, position: Vector2 = Vector2.ZERO) -> bool:
	# 被動技能不需要主動執行
	return true

func on_damage_dealt(damage_info: Dictionary) -> Dictionary:
	# 檢查是否為火屬性傷害
	var damage_element = damage_info.get("element", "")
	if damage_element == "fire":
		var multiplier = parameters.get("damage_multiplier", 1.0)
		var original_damage = damage_info.get("amount", 0)
		var boosted_damage = int(original_damage * multiplier)
		
		damage_info["amount"] = boosted_damage
		damage_info["was_boosted"] = true
		damage_info["boost_source"] = skill_name
		
		# 發送事件通知
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree and scene_tree.current_scene:
			var eb = scene_tree.get_first_node_in_group("autoload_eventbus")
			if eb and eb.has_signal("ability_triggered"):
				eb.ability_triggered.emit(skill_id, owner, null)
		
		print("[FireMastery] 火屬性傷害從 ", original_damage, " 提升到 ", boosted_damage)
	
	return damage_info