# Hero.gd - 英雄基礎類別
class_name Hero
extends Node2D

# 英雄基礎屬性
@export var hero_id: String = ""
@export var hero_name: String = ""
@export var element: String = "neutral"
@export var base_attack: int = 100
@export var current_hp: int = 1000
@export var max_hp: int = 1000
@export var level: int = 1

# 技能系統
@onready var skill_component: Node = $SkillComponent

# 視覺組件引用
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var animation_player: AnimationPlayer = $Visual/AnimationPlayer

# 狀態
var is_alive: bool = true
var status_effects: Array = []
var tags: Array = []

# 信號
signal hero_died(hero: Hero)
signal hero_healed(hero: Hero, amount: int)
signal skill_used(hero: Hero, skill_id: String)

func _ready():
	# 連接到 EventBus
	_connect_events()
	
	# 初始化UI
	_update_ui()

func _connect_events():
	if EventBus:
		# 連接戰鬥相關事件
		if not EventBus.damage_dealt.is_connected(_on_damage_received):
			EventBus.damage_dealt.connect(_on_damage_received)
		if not EventBus.healing_applied.is_connected(_on_healing_received):
			EventBus.healing_applied.connect(_on_healing_received)

func load_from_data(hero_data: Dictionary):
	"""從JSON數據載入英雄資訊"""
	hero_id = hero_data.get("id", "")
	hero_name = _get_localized_name(hero_data.get("name", {}))
	element = hero_data.get("element", "neutral")
	base_attack = hero_data.get("base_attack", 100)
	max_hp = hero_data.get("hp", 1000)
	current_hp = max_hp
	level = hero_data.get("level", 1)
	tags = hero_data.get("tags", [])
	
	# 載入技能
	_load_skills(hero_data.get("skills", []))
	
	# 載入視覺資源
	_load_visual_resources(hero_data)
	
	# 更新UI顯示
	_update_ui()

func _get_localized_name(name_data: Dictionary) -> String:
	# 直接使用 ResourceManager 全局變數，避免 get_node 錯誤
	var language = "zh"  # 預設語言
	if ResourceManager:
		language = ResourceManager.current_language
	return name_data.get(language, name_data.get("zh", hero_id))

func _load_skills(skills_data: Array):
	"""載入技能數據"""
	if skill_component and skill_component.has_method("load_skills"):
		skill_component.load_skills(skills_data)

func _load_visual_resources(hero_data: Dictionary):
	"""載入視覺資源"""
	var sprite_path = hero_data.get("sprite_path", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	else:
		# 使用預設外觀
		_create_default_appearance()

func _create_default_appearance():
	"""創建預設外觀"""
	if sprite:
		# 創建簡單的顏色方塊作為預設外觀
		var element_colors = {
			"fire": Color.ORANGE_RED,
			"water": Color.CYAN,
			"grass": Color.GREEN,
			"light": Color.YELLOW,
			"dark": Color.PURPLE,
			"neutral": Color.GOLD
		}
		
		# 創建簡單的ColorRect作為預設外觀
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(80, 80)
		color_rect.position = Vector2(-40, -40)
		color_rect.color = element_colors.get(element, Color.GOLD)
		add_child(color_rect)

func take_damage(damage: int, damage_type: String = "normal", source: Node = null):
	"""受到傷害"""
	if not is_alive:
		return
	
	# 技能系統介入傷害計算
	var damage_info = {
		"base_damage": damage,
		"damage_type": damage_type,
		"source": source,
		"target": self
	}
	
	if skill_component and skill_component.has_method("modify_incoming_damage"):
		damage_info = skill_component.modify_incoming_damage(damage_info)
	
	var actual_damage = damage_info.get("base_damage", damage)
	current_hp = max(0, current_hp - actual_damage)
	
	print("[Hero] ", hero_name, " 受到 ", actual_damage, " 點傷害，剩餘HP: ", current_hp)
	
	# 更新UI
	_update_ui()
	
	# 觸發動畫
	_play_damage_animation()
	
	# 檢查是否死亡
	if current_hp <= 0:
		die()

func heal(amount: int, source: Node = null):
	"""治療"""
	if not is_alive:
		return
	
	var old_hp = current_hp
	current_hp = min(max_hp, current_hp + amount)
	var actual_heal = current_hp - old_hp
	
	print("[Hero] ", hero_name, " 恢復 ", actual_heal, " 點生命值")
	
	# 更新UI
	_update_ui()
	
	# 觸發動畫
	_play_heal_animation()
	
	# 發送事件
	if EventBus:
		EventBus.healing_applied.emit(source, self, actual_heal)
	
	# 發送信號
	hero_healed.emit(self, actual_heal)

func die():
	"""英雄死亡"""
	if not is_alive:
		return
	
	is_alive = false
	print("[Hero] ", hero_name, " 已死亡")
	
	# 播放死亡動畫
	_play_death_animation()
	
	# 發送事件
	if EventBus:
		EventBus.emit_object_event("destroyed", "hero", self, {"id": hero_id})
	
	# 發送信號
	hero_died.emit(self)

func use_skill(skill_id: String, target: Node = null, position: Vector2 = Vector2.ZERO) -> bool:
	"""使用技能"""
	if not is_alive or not skill_component:
		return false
	
	if skill_component.has_method("use_skill"):
		var success = skill_component.use_skill(skill_id, target, position)
		if success:
			print("[Hero] ", hero_name, " 使用技能: ", skill_id)
			skill_used.emit(self, skill_id)
			_play_skill_animation(skill_id)
		return success
	
	return false

func _update_ui():
	"""更新UI顯示"""
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp

func _play_damage_animation():
	"""播放受傷動畫"""
	if animation_player and animation_player.has_animation("damage"):
		animation_player.play("damage")
	else:
		# 簡單的閃爍效果
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.RED, 0.1)
		tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func _play_heal_animation():
	"""播放治療動畫"""
	if animation_player and animation_player.has_animation("heal"):
		animation_player.play("heal")
	else:
		# 簡單的綠光效果
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.GREEN, 0.2)
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func _play_death_animation():
	"""播放死亡動畫"""
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
	else:
		# 簡單的淡出效果
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.3, 1.0)

func _play_skill_animation(skill_id: String):
	"""播放技能動畫"""
	var anim_name = "skill_" + skill_id
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		# 簡單的放大效果
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

# 事件處理
func _on_damage_received(source: Node, target: Node, amount: int, damage_type: String):
	"""接收傷害事件"""
	if target == self:
		take_damage(amount, damage_type, source)

func _on_healing_received(source: Node, target: Node, amount: int):
	"""接收治療事件"""
	if target == self:
		heal(amount, source)

# 獲取英雄資訊（供UI或系統使用）
func get_hero_info() -> Dictionary:
	return {
		"id": hero_id,
		"name": hero_name,
		"element": element,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"attack": base_attack,
		"level": level,
		"is_alive": is_alive,
		"status_effects": status_effects,
		"tags": tags
	}