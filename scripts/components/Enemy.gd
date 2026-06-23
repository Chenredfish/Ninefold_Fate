# Enemy.gd - 敵人類別（繼承 BaseCharacter）
class_name Enemy
extends BaseCharacter

# === 敵人特有屬性 ===
@export var base_attack: int = 10
@export var max_countdown: int = 3
var current_countdown: int = 3
var attack_aim: Node = null  # 預留：多英雄場景下的指定攻擊目標

# === 敵人特有組件 ===
@onready var countdown_label: Label = null  # 動態創建
var _select_button: Button = null

# === 敵人特有信號 ===
signal enemy_attacked(enemy: Enemy, damage: int)
signal countdown_changed(enemy: Enemy, new_countdown: int)
signal enemy_selected(enemy: Enemy)

# === 向後兼容的屬性別名 ===
var enemy_name: String:
	get: return character_name
	set(value): character_name = value

var enemy_id: String:
	get: return character_id
	set(value): character_id = value

var base_hp: int:
	get: return max_hp
	set(value): max_hp = value

func _ready():
	super._ready()  # 調用父類的 _ready

	# 敵人特有的初始化
	current_countdown = max_countdown
	_create_countdown_label()
	_create_select_button()

	# 連接回合事件（修 B06）
	if not EventBus.turn_started.is_connected(_on_turn_started):
		EventBus.turn_started.connect(_on_turn_started)

# === 重寫父類方法 ===
func get_character_type() -> String:
	return "Enemy"

func _get_health_bar_color() -> Color:
	return Color.RED

func _calculate_damage(damage: int, damage_type: String, source: Node) -> int:
	"""應用屬性剋制計算（從 balance.json 讀取）"""
	var multiplier = 1.0

	# 從 ResourceManager 取得克制表
	var balance_data = ResourceManager.get_balance_data()
	if not balance_data:
		push_warning("[Enemy] Failed to load balance data, using neutral damage")
		return damage

	var advantage_table = balance_data.get("element_advantage_table", {})
	var advantage_mult = balance_data.get("advantage_multiplier", 1.5)
	var disadvantage_mult = balance_data.get("disadvantage_multiplier", 0.5)

	# 檢查我的屬性是否被傷害屬性克制（傷害減少）
	if element in advantage_table:
		var advantage_list = advantage_table[element]
		if damage_type in advantage_list:
			multiplier = disadvantage_mult

	# 檢查傷害屬性是否被我的屬性克制（傷害增加）
	if damage_type in advantage_table:
		var advantage_list = advantage_table[damage_type]
		if element in advantage_list:
			multiplier = advantage_mult

	return int(damage * multiplier)

func get_character_info() -> Dictionary:
	"""獲取敵人資訊"""
	var base_info = super.get_character_info()
	base_info.merge({
		"base_attack": base_attack,
		"countdown": current_countdown,
		"max_countdown": max_countdown
	})
	return base_info

# 為了向後相容，保留舊的方法名
func get_enemy_info() -> Dictionary:
	return get_character_info()

func load_from_data(enemy_data: Dictionary):
	"""從JSON數據載入敵人資訊"""
	super.load_from_data(enemy_data)  # 調用父類方法
	
	# 敵人特有的數據載入
	base_attack = enemy_data.get("base_attack", 10)
	max_hp = enemy_data.get("base_hp", 100)
	current_hp = max_hp
	max_countdown = enemy_data.get("countdown", 3)
	current_countdown = max_countdown

# === 敵人特有功能 ===
func attack():
	"""敵人攻擊"""
	if not is_alive:
		return
	
	print("[Enemy] ", character_name, " 發動攻擊，造成 ", base_attack, " 點傷害")
	
	# 播放攻擊動畫
	_play_attack_animation()
	
	# 發送攻擊事件
	if EventBus:
		EventBus.damage_dealt_to_hero.emit(self, base_attack, element)
	
	# 發送信號
	enemy_attacked.emit(self, base_attack)
	
	# 重置倒數
	current_countdown = max_countdown
	_update_countdown_ui()

func tick_countdown():
	"""倒數機制"""
	if not is_alive:
		return
	
	current_countdown = max(0, current_countdown - 1)
	_update_countdown_ui()
	
	# 發送倒數變化信號
	countdown_changed.emit(self, current_countdown)
	
	print("[Enemy] ", character_name, " 倒數: ", current_countdown)
	
	# 倒數結束時攻擊
	if current_countdown <= 0:
		attack()

func _create_countdown_label():
	"""創建倒數標籤"""
	if countdown_label:
		return
	
	countdown_label = Label.new()
	countdown_label.text = str(current_countdown)
	countdown_label.position = Vector2(-10, -80)
	countdown_label.size = Vector2(20, 20)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 16)  # 保持原大小，讓scene的scale處理放大
	add_child(countdown_label)
	
	_update_countdown_ui()

func _create_select_button():
	var ui = get_node_or_null("UI")
	if not ui:
		push_warning("[Enemy] _create_select_button: 找不到 UI 節點")
		return

	_select_button = Button.new()
	_select_button.name = "SelectButton"

	# 圓形透明樣式
	var radius := 40
	var size := radius * 2
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	_select_button.add_theme_stylebox_override("normal", style)
	_select_button.add_theme_stylebox_override("hover", style)
	_select_button.add_theme_stylebox_override("pressed", style)
	_select_button.add_theme_stylebox_override("focus", style)

	# 置中在 UI Control
	_select_button.anchor_left = 0.5
	_select_button.anchor_top = 0.5
	_select_button.anchor_right = 0.5
	_select_button.anchor_bottom = 0.5
	_select_button.offset_left = -radius
	_select_button.offset_top = -radius
	_select_button.offset_right = radius
	_select_button.offset_bottom = radius

	_select_button.flat = true
	_select_button.pressed.connect(_on_select_button_pressed)
	ui.add_child(_select_button)
	print("[Enemy] ", character_name, " 選取按鈕建立完成（半徑 ", radius, "）")

func _on_select_button_pressed():
	print("[Enemy] 點擊選取：", character_name, "（", character_id, "）")
	enemy_selected.emit(self)

func _update_countdown_ui():
	"""更新倒數UI"""
	if countdown_label:
		countdown_label.text = str(current_countdown)
		
		# 根據倒數改變顏色
		if current_countdown <= 1:
			countdown_label.add_theme_color_override("font_color", Color.RED)
		elif current_countdown <= 2:
			countdown_label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			countdown_label.add_theme_color_override("font_color", Color.WHITE)

func _play_attack_animation():
	"""播放攻擊動畫"""
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	else:
		# 簡單的攻擊效果
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(2.2, 2.2), 0.1)
		tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.1)

# === 事件處理 ===
func _on_turn_started(turn_type: String):
	"""回合開始事件"""
	if turn_type == "enemy" and is_alive:
		tick_countdown()
