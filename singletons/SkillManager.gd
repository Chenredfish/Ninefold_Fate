# SkillManager.gd - 簡化版技能管理系統
extends Node

# 技能資料庫
var skills_database: Dictionary = {}

func _ready():
	print("==========================================")
	print("[SkillManager] 簡化版技能系統初始化中...")
	print("當前時間: ", Time.get_datetime_string_from_system())
	_load_skills_database()
	print("[SkillManager] 簡化版技能系統已就緒")
	print("==========================================")

func _load_skills_database():
	var file_path = "res://data/skills.json"
	if not FileAccess.file_exists(file_path):
		push_warning("Skills database not found: " + file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Cannot open skills database: " + file_path)
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Error parsing skills JSON")
		return
	
	skills_database = json.data
	print("[SkillManager] 載入 ", skills_database.size(), " 個技能數據")
	print("[SkillManager] 技能列表: ", skills_database.keys())

# 取得技能資料副本（簡化版）
func get_skill_data_copy(skill_id: String) -> Dictionary:
	var skill_data = skills_database.get(skill_id)
	if not skill_data:
		push_warning("Skill data not found: " + skill_id)
		return {}

	print("[SkillManager] 取得技能副本: ", skill_id)
	return skill_data.duplicate()

# 取得技能資料
func get_skill_data(skill_id: String) -> Dictionary:
	return skills_database.get(skill_id, {})

# 取得所有技能 ID
func get_all_skill_ids() -> Array:
	return skills_database.keys()

# 測試方法
func test_skill_system():
	print("[SkillManager] 測試簡化版技能系統...")

	# 測試取得技能資料
	var skill_ids = get_all_skill_ids()
	print("可用技能: ", skill_ids)

	# 測試取得技能副本
	if skill_ids.size() > 0:
		var first_skill = get_skill_data_copy(skill_ids[0])
		if first_skill.size() > 0:
			print("成功取得技能副本: ", first_skill.get("name", {}))

	print("[SkillManager] 簡化版技能系統測試完成")
