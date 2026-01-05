# Enemy.gd - 敵人基礎類別
class_name Enemy
extends Node2D

# 敵人基礎屬性
@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export var element: String = "neutral"
@export var base_hp: int = 100
@export var current_hp: int = 100
@export var base_attack: int = 10
@export var max_countdown: int = 3
@export var current_countdown: int = 3

# 狀態
var is_alive: bool = true
var status_effects: Array = []
var tags: Array = []

# 視覺組件引用
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var countdown_label: Label = $UI/CountdownLabel
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var animation_player: AnimationPlayer = $Visual/AnimationPlayer

# 信號
signal enemy_died(enemy: Enemy)
signal enemy_attacked(enemy: Enemy, damage: int)
signal countdown_changed(enemy: Enemy, new_countdown: int)

func _ready():
	# 初始化UI
	_update_ui()
	
	# 設置初始狀態
	current_hp = base_hp
	current_countdown = max_countdown
	
	# 連接到 EventBus（只在 _ready 時執行）
	_connect_events()

func _connect_events():
	if EventBus:
		# 連接戰鬥相關事件
		if not EventBus.turn_started.is_connected(_on_turn_started):
			EventBus.turn_started.connect(_on_turn_started)
		if not EventBus.damage_dealt.is_connected(_on_damage_received):
			EventBus.damage_dealt.connect(_on_damage_received)

func load_from_data(enemy_data: Dictionary):
	"""從JSON數據載入敵人資訊"""
	enemy_id = enemy_data.get("id", "")
	enemy_name = _get_localized_name(enemy_data.get("name", {}))
	element = enemy_data.get("element", "neutral")
	base_hp = enemy_data.get("base_hp", 100)
	base_attack = enemy_data.get("base_attack", 10)
	max_countdown = enemy_data.get("countdown", 3)
	tags = enemy_data.get("tags", [])
	
	# 設置當前值
	current_hp = base_hp
	current_countdown = max_countdown
	
	# 載入視覺資源
	_load_visual_resources(enemy_data)
	
	# 更新UI顯示
	_update_ui()

func _get_localized_name(name_data: Dictionary) -> String:
	# 直接使用 ResourceManager 全局變數，避免 get_node 錯誤
	var language = "zh"  # 預設語言
	if ResourceManager:
		language = ResourceManager.current_language
	return name_data.get(language, name_data.get("zh", enemy_id))

func _load_visual_resources(enemy_data: Dictionary):
	"""載入視覺資源"""
	var sprite_path = enemy_data.get("sprite_path", "")
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
			"fire": Color.RED,
			"water": Color.BLUE,
			"grass": Color.GREEN,
			"light": Color.YELLOW,
			"dark": Color.PURPLE,
			"neutral": Color.GRAY
		}
		
		# 創建簡單的ColorRect作為預設外觀
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(64, 64)
		color_rect.position = Vector2(-32, -32)
		color_rect.color = element_colors.get(element, Color.GRAY)
		add_child(color_rect)

func take_damage(damage: int, damage_type: String = "normal", source: Node = null, emit_event: bool = true):
	"""受到傷害"""
	if not is_alive:
		return
	
	# 應用屬性剋制
	var actual_damage = _apply_element_resistance(damage, damage_type)
	
	current_hp = max(0, current_hp - actual_damage)
	
	print("[Enemy] ", enemy_name, " 受到 ", actual_damage, " 點傷害，剩餘HP: ", current_hp)
	
	# 更新UI
	_update_ui()
	
	# 觸發動畫
	_play_damage_animation()
	
	# 只在 emit_event 為 true 時發送事件，避免遞迴
	if emit_event and EventBus:
		EventBus.damage_dealt.emit(source, self, actual_damage, damage_type)
	
	# 檢查是否死亡
	if current_hp <= 0:
		die()

func _apply_element_resistance(damage: int, damage_type: String) -> int:
	"""應用屬性剋制計算"""
	# 簡化版屬性剋制
	var resistance_table = {
		"fire": {"water": 1.5, "fire": 0.5},
		"water": {"grass": 1.5, "water": 0.5},
		"grass": {"fire": 1.5, "grass": 0.5},
		"light": {"dark": 1.5, "light": 0.5},
		"dark": {"light": 1.5, "dark": 0.5}
	}
	
	var multiplier = 1.0
	if element in resistance_table and damage_type in resistance_table[element]:
		multiplier = resistance_table[element][damage_type]
	
	return int(damage * multiplier)

func die():
	"""敵人死亡"""
	if not is_alive:
		return
	
	is_alive = false
	print("[Enemy] ", enemy_name, " 已死亡")
	
	# 播放死亡動畫
	_play_death_animation()
	
	# 計算獎勵
	var rewards = _calculate_death_rewards()
	
	# 發送事件
	if EventBus:
		EventBus.enemy_defeated.emit(enemy_id, rewards)
	
	# 發送信號
	enemy_died.emit(self)
	
	# 延遲移除（等動畫播完）
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _calculate_death_rewards() -> Dictionary:
	"""計算死亡獎勵"""
	return {
		"gold": base_hp / 10,
		"exp": base_attack,
		"items": []
	}

func attack():
	"""敵人攻擊"""
	if not is_alive:
		return
	
	print("[Enemy] ", enemy_name, " 發動攻擊，造成 ", base_attack, " 點傷害")
	
	# 播放攻擊動畫
	_play_attack_animation()
	
	# 發送攻擊事件
	if EventBus:
		EventBus.damage_dealt.emit(self, null, base_attack, "enemy_attack")
	
	# 發送信號
	enemy_attacked.emit(self, base_attack)
	
	# 重置倒數
	current_countdown = max_countdown
	_update_ui()

func tick_countdown():
	"""倒數減1"""
	if not is_alive:
		return
	
	current_countdown = max(0, current_countdown - 1)
	print("[Enemy] ", enemy_name, " 倒數: ", current_countdown)
	
	# 更新UI
	_update_ui()
	
	# 發送信號
	countdown_changed.emit(self, current_countdown)
	
	# 倒數到0時攻擊
	if current_countdown <= 0:
		attack()

func _update_ui():
	"""更新UI顯示"""
	if health_bar:
		health_bar.max_value = base_hp
		health_bar.value = current_hp
	
	if countdown_label:
		countdown_label.text = str(current_countdown)
		
		# 根據倒數改變顏色
		if current_countdown <= 1:
			countdown_label.add_theme_color_override("font_color", Color.RED)
		elif current_countdown <= 2:
			countdown_label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			countdown_label.add_theme_color_override("font_color", Color.WHITE)

func _play_damage_animation():
	"""播放受傷動畫"""
	if animation_player and animation_player.has_animation("damage"):
		animation_player.play("damage")
	else:
		# 簡單的閃爍效果
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.RED, 0.1)
		tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func _play_attack_animation():
	"""播放攻擊動畫"""
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	else:
		# 簡單的放大縮小效果
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

func _play_death_animation():
	"""播放死亡動畫"""
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
	else:
		# 簡單的淡出效果
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)

# 事件處理
func _on_turn_started(turn_number: int):
	"""回合開始時處理"""
	if is_alive:
		tick_countdown()

func _on_damage_received(source: Node, target: Node, amount: int, damage_type: String):
	"""接收傷害事件"""
	if target == self:
		# 通過事件系統造成傷害時，設置 emit_event=false 避免遞迴
		take_damage(amount, damage_type, source, false)

# 狀態效果系統
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

# 獲取敵人資訊（供UI或系統使用）
func get_enemy_info() -> Dictionary:
	return {
		"id": enemy_id,
		"name": enemy_name,
		"element": element,
		"current_hp": current_hp,
		"max_hp": base_hp,
		"attack": base_attack,
		"countdown": current_countdown,
		"max_countdown": max_countdown,
		"is_alive": is_alive,
		"status_effects": status_effects,
		"tags": tags
	}