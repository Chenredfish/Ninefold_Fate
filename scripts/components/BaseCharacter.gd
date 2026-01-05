# BaseCharacter.gd - 角色基礎類別（敵人和英雄的共同父類）
class_name BaseCharacter
extends Node2D

# === 基礎屬性 ===
@export var character_id: String = ""
@export var character_name: String = ""
@export var element: String = "neutral"
@export var current_hp: int = 100
@export var max_hp: int = 100
@export var level: int = 1

# === 狀態 ===
var is_alive: bool = true
var status_effects: Array = []
var tags: Array = []

# === 視覺組件 ===
@onready var health_bar: ColorRect = null  # 動態創建
@onready var sprite: Sprite2D = null
@onready var animation_player: AnimationPlayer = null

# === 信號 ===
signal character_died(character: BaseCharacter)
signal health_changed(character: BaseCharacter, old_hp: int, new_hp: int)

func _ready():
	# 連接到 EventBus
	_connect_events()
	
	# 初始化UI
	_update_ui()

func _connect_events():
	"""連接EventBus事件"""
	if EventBus:
		# 監聽傷害事件
		if not EventBus.damage_dealt.is_connected(_on_damage_received):
			EventBus.damage_dealt.connect(_on_damage_received)

# === 基礎戰鬥系統 ===
func take_damage(damage: int, damage_type: String = "normal", source: Node = null, emit_event: bool = true):
	"""受到傷害"""
	if not is_alive:
		return
	
	var old_hp = current_hp
	var actual_damage = _calculate_damage(damage, damage_type, source)
	current_hp = max(0, current_hp - actual_damage)
	
	print("[", get_character_type(), "] ", character_name, " 受到 ", actual_damage, " 點傷害，剩餘HP: ", current_hp)
	
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

func heal(amount: int, source: Node = null):
	"""治療"""
	if not is_alive:
		return
	
	var old_hp = current_hp
	current_hp = min(max_hp, current_hp + amount)
	var actual_heal = current_hp - old_hp
	
	print("[", get_character_type(), "] ", character_name, " 恢復 ", actual_heal, " 點生命值")
	
	# 更新UI
	_update_ui()
	
	# 觸發動畫
	_play_heal_animation()
	
	# 發送信號
	health_changed.emit(self, old_hp, current_hp)
	if EventBus:
		EventBus.healing_applied.emit(source, self, actual_heal)

func die():
	"""角色死亡"""
	if not is_alive:
		return
	
	is_alive = false
	print("[", get_character_type(), "] ", character_name, " 已死亡")
	
	# 播放死亡動畫
	_play_death_animation()
	
	# 發送事件和信號
	if EventBus:
		EventBus.emit_object_event("destroyed", get_character_type().to_lower(), self, {"id": character_id})
	character_died.emit(self)

# === 虛擬方法（子類重寫） ===
func get_character_type() -> String:
	"""獲取角色類型（子類重寫）"""
	return "Character"

func _calculate_damage(damage: int, damage_type: String, source: Node) -> int:
	"""計算實際傷害（子類可重寫以實現屬性剋制等）"""
	return damage

func get_character_info() -> Dictionary:
	"""獲取角色資訊（子類可重寫添加特定資訊）"""
	return {
		"id": character_id,
		"name": character_name,
		"element": element,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"level": level,
		"is_alive": is_alive,
		"status_effects": status_effects,
		"tags": tags
	}

# === UI 系統 ===
func _update_ui():
	"""更新UI顯示"""
	# 確保血條節點存在，如果不存在則創建
	if not health_bar:
		_create_health_bar()
	
	# 更新血條顯示（ColorRect版本）
	if health_bar:
		var health_ratio = float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
		health_bar.size.x = 60 * health_ratio  # 根據血量比例調整寬度

func _create_health_bar():
	"""創建血條UI"""
	if health_bar:
		return
		
	
	health_bar = ColorRect.new()
	health_bar.size = Vector2(60, 6)
	health_bar.position = Vector2(-30, -60)
	health_bar.color = _get_health_bar_color()
	add_child(health_bar)

func _get_health_bar_color() -> Color:
	"""獲取血條顏色（子類重寫）"""
	return Color.WHITE

# === 視覺系統 ===
func load_from_data(data: Dictionary):
	"""從數據載入角色資訊（子類重寫實現具體邏輯）"""
	character_id = data.get("id", "")
	character_name = _get_localized_name(data.get("name", {}))
	element = data.get("element", "neutral")
	level = data.get("level", 1)
	tags = data.get("tags", [])
	
	# 載入視覺資源
	_load_visual_resources(data)
	
	# 更新UI顯示
	_update_ui()

func _get_localized_name(name_data: Dictionary) -> String:
	"""獲取本地化名稱"""
	var language = "zh"  # 預設語言
	if ResourceManager:
		language = ResourceManager.current_language
	return name_data.get(language, name_data.get("zh", character_id))

func _load_visual_resources(data: Dictionary):
	"""載入視覺資源"""
	var sprite_path = data.get("sprite_path", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		if sprite:
			sprite.texture = load(sprite_path)
	else:
		# 使用預設外觀
		_create_default_appearance()

func _create_default_appearance():
	"""創建預設外觀"""
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
	color_rect.size = Vector2(60, 60)
	color_rect.position = Vector2(-30, -30)
	color_rect.color = element_colors.get(element, Color.GOLD)
	add_child(color_rect)

# === 動畫系統 ===
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

# === 狀態效果系統 ===
func add_status_effect(effect_id: String, duration: float = -1):
	"""添加狀態效果"""
	var effect = {
		"id": effect_id,
		"duration": duration,
		"start_time": Time.get_ticks_msec() / 1000.0
	}
	status_effects.append(effect)

func remove_status_effect(effect_id: String):
	"""移除狀態效果"""
	for i in range(status_effects.size() - 1, -1, -1):
		if status_effects[i].id == effect_id:
			status_effects.remove_at(i)

func has_status_effect(effect_id: String) -> bool:
	"""檢查是否有特定狀態效果"""
	for effect in status_effects:
		if effect.id == effect_id:
			return true
	return false

# === 事件處理 ===
func _on_damage_received(source: Node, target: Node, amount: int, damage_type: String):
	"""接收傷害事件"""
	if target == self:
		# 通過事件系統造成傷害時，設置 emit_event=false 避免遞迴
		take_damage(amount, damage_type, source, false)