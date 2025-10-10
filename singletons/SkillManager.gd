# SkillManager.gd - 简化版技能管理系统
extends Node

# 技能数据库
var skills_database: Dictionary = {}

func _ready():
	print("==========================================")
	print("[SkillManager] 简化版技能系统初始化中...")
	print("当前时间: ", Time.get_datetime_string_from_system())
	_load_skills_database()
	print("[SkillManager] 简化版技能系统已就绪")
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

# 创建基础技能实例 (简化版)
func create_skill(skill_id: String) -> Dictionary:
	var skill_data = skills_database.get(skill_id)
	if not skill_data:
		push_warning("Skill data not found: " + skill_id)
		return {}
	
	print("[SkillManager] 创建技能: ", skill_id)
	return skill_data.duplicate()

# 获取技能数据
func get_skill_data(skill_id: String) -> Dictionary:
	return skills_database.get(skill_id, {})

# 获取所有技能 ID
func get_all_skill_ids() -> Array:
	return skills_database.keys()

# 测试方法
func test_skill_system():
	print("[SkillManager] 测试简化版技能系统...")
	
	# 测试获取技能数据
	var skill_ids = get_all_skill_ids()
	print("可用技能: ", skill_ids)
	
	# 测试创建技能
	if skill_ids.size() > 0:
		var first_skill = create_skill(skill_ids[0])
		if first_skill.size() > 0:
			print("成功创建技能: ", first_skill.get("name", {}))
	
	print("[SkillManager] 简化版技能系统测试完成")