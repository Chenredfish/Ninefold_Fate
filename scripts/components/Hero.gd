# Hero.gd - 英雄類別（繼承 BaseCharacter）
class_name Hero
extends BaseCharacter

# === 英雄特有屬性 ===
@export var base_attack: int = 100

# === 技能系統 ===
@onready var skill_component: Node = null

# === 英雄特有信號 ===
signal hero_died(hero: Hero)
signal hero_healed(hero: Hero, amount: int)
signal skill_used(hero: Hero, skill_id: String)

# === 向後兼容的屬性別名 ===
var hero_name: String:
	get: return character_name
	set(value): character_name = value

var hero_id: String:
	get: return character_id
	set(value): character_id = value

func _ready():
	super._ready()  # 調用父類的 _ready
	
	# 英雄特有的初始化
	_try_connect_skill_component()

# === 重寫父類方法 ===
func get_character_type() -> String:
	return "Hero"

func _get_health_bar_color() -> Color:
	return Color.GREEN

func take_damage(damage: int, damage_type: String = "normal", source: Node = null, emit_event: bool = true):
	"""英雄受到傷害（包含技能系統介入）"""
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
	
	# 調用父類的傷害處理（但跳過重複計算）
	var old_hp = current_hp
	current_hp = max(0, current_hp - actual_damage)
	
	print("[Hero] ", character_name, " 受到 ", actual_damage, " 點傷害，剩餘HP: ", current_hp)
	
	# 更新UI
	_update_ui()
	
	# 觸發動畫
	_play_damage_animation()
	
	# 發送信號和事件
	health_changed.emit(self, old_hp, current_hp)
	if emit_event and EventBus:
		EventBus.damage_dealt.emit(source, self, actual_damage, damage_type)
	
	# 檢查是否死亡
	if current_hp <= 0:
		die()

func get_character_info() -> Dictionary:
	"""獲取英雄資訊"""
	var base_info = super.get_character_info()
	base_info.merge({
		"base_attack": base_attack
	})
	return base_info

# 為了向後相容，保留舊的方法名
func get_hero_info() -> Dictionary:
	return get_character_info()

func load_from_data(hero_data: Dictionary):
	"""從JSON數據載入英雄資訊"""
	super.load_from_data(hero_data)  # 調用父類方法
	
	# 英雄特有的數據載入
	base_attack = hero_data.get("base_attack", 100)
	max_hp = hero_data.get("hp", 1000)
	current_hp = max_hp
	
	# 載入技能
	_load_skills(hero_data.get("skills", []))

# === 英雄特有功能 ===
func use_skill(skill_id: String, target: Node = null, position: Vector2 = Vector2.ZERO) -> bool:
	"""使用技能"""
	if not is_alive or not skill_component:
		return false
	
	if skill_component.has_method("use_skill"):
		var success = skill_component.use_skill(skill_id, target, position)
		if success:
			print("[Hero] ", character_name, " 使用技能: ", skill_id)
			skill_used.emit(self, skill_id)
			_play_skill_animation(skill_id)
		return success
	
	return false

func _try_connect_skill_component():
	"""嘗試連接技能組件"""
	skill_component = get_node_or_null("SkillComponent")
	if not skill_component:
		print("[Hero] Warning: SkillComponent not found for ", character_name)

func _load_skills(skills_data: Array):
	"""載入技能數據"""
	if skill_component and skill_component.has_method("load_skills"):
		skill_component.load_skills(skills_data)

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

# === 重寫信號連接 ===
func _connect_events():
	"""連接EventBus事件"""
	super._connect_events()  # 調用父類方法
	
	if EventBus:
		# 英雄特有的事件連接
		if EventBus.has_signal("healing_applied"):
			if not EventBus.healing_applied.is_connected(_on_healing_received):
				EventBus.healing_applied.connect(_on_healing_received)

func _on_healing_received(source: Node, target: Node, amount: int):
	"""接收治療事件"""
	if target == self:
		heal(amount, source)

# === 重寫父類的 die 方法以發送英雄特有信號 ===
func die():
	"""英雄死亡"""
	super.die()  # 調用父類方法
	hero_died.emit(self)  # 發送英雄特有信號

# === 重寫父類的 heal 方法以發送英雄特有信號 ===
func heal(amount: int, source: Node = null):
	"""治療"""
	super.heal(amount, source)  # 調用父類方法
	hero_healed.emit(self, amount)  # 發送英雄特有信號

# === 完全自訂英雄外觀與UI ===
func _create_health_bar():
	if health_bar and is_instance_valid(health_bar):
		return
	var existing_health_bar = get_node_or_null("HealthBar")
	if existing_health_bar:
		health_bar = existing_health_bar
		return
	health_bar = ColorRect.new()
	health_bar.size = Vector2(800, 24)
	health_bar.position = Vector2(-400, -100)
	health_bar.color = _get_health_bar_color()
	health_bar.name = "HealthBar"
	add_child(health_bar)

func _create_default_appearance():
	pass

func _update_ui():
	if not health_bar:
		_create_health_bar()
	if health_bar:
		var health_ratio = float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
		health_bar.size.x = 800 * health_ratio

func _load_visual_resources(data: Dictionary):
	# 只載入 sprite，不呼叫父類，不產生預設外觀
	var sprite_path = data.get("sprite_path", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		if sprite:
			sprite.texture = load(sprite_path)

func _play_damage_animation():
	# 可自訂英雄受傷動畫，預設不做任何事
	pass

func _play_heal_animation():
	# 可自訂英雄治療動畫，預設不做任何事
	pass

func _play_death_animation():
	# 可自訂英雄死亡動畫，預設不做任何事
	pass