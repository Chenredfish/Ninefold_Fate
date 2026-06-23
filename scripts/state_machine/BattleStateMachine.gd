# BattleStateMachine.gd
# 戰鬥狀態機，管理戰鬥內部的各種狀態轉換

class_name BattleStateMachine
extends BaseStateMachine

# 戰鬥狀態枚舉
enum BattleStateType {
	PREPARING,      # 戰鬥準備
	PLAYER_TURN,    # 玩家回合
	CALCULATING,    # 計算傷害
	ENEMY_TURN,     # 敵人回合
	VICTORY,        # 勝利
	DEFEAT          # 失敗
}

# 戰鬥相關數據
var battle_data: Dictionary = {}
var turn_number: int = 0
var max_turns: int = ResourceManager.get_balance_value("max_turns", 100)

# 戰鬥狀態
var player_tiles_placed: int = 0
var max_tiles_per_turn: int = 100
var enemies_remaining: int = 0
var current_wave: int = 1
var hero_scene: Node = null        # 英雄場景實例 (Hero節點)
var enemies_scenes: Array[Node] = []    # 敵人場景實例 (Enemy節點)
var selected_target: Node = null        # 玩家選定的攻擊目標
var current_hands: Array[String] = []   # 當前手牌 (方塊ID字串陣列)
var deck_data: Array[String] = []       # 牌組數據 (可用方塊ID字串陣列)
var board_complete_count: int = 1       # 連續填滿棋盤的次數（跨回合累積）
var combo_multiplier: float = 1.0      # 當前 combo 倍率

func _init():
	super._init()
	name = "BattleStateMachine"
	
	# 初始化戰鬥狀態
	_initialize_battle_states()
	
	# 連接EventBus事件
	_connect_event_bus()

func _initialize_battle_states():
	add_state(PreparingState.new())
	add_state(PlayerTurnState.new())
	add_state(CalculatingState.new())
	add_state(EnemyTurnState.new())
	add_state(VictoryState.new())
	add_state(DefeatState.new())

func _connect_event_bus():
	# 連接戰鬥相關事件
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.block_placed.connect(_on_block_placed)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.skill_effect_requested.connect(_on_skill_effect_requested)
	EventBus.skill_cast_requested.connect(_on_skill_cast_requested)

# 開始戰鬥
func start_battle(level_data: Dictionary):
	battle_data = level_data
	turn_number = 0
	player_tiles_placed = 0
	enemies_scenes.clear()
	current_hands.clear()
	deck_data.clear()
	
	# enemies_remaining 將在敵人創建後設定，不在這裡計算
	enemies_remaining = 0
	
	transition_to("preparing", battle_data)

# 結束戰鬥
func end_battle(result: String, rewards: Array = []):
	EventBus.battle_ended.emit(result, rewards)
	
	# 清理敵人場景
	for enemy in enemies_scenes:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies_scenes.clear()
	
	# 重置戰鬥數據
	_battle_clean()

func _battle_clean():
	battle_data.clear()
	turn_number = 0
	player_tiles_placed = 0
	enemies_remaining = 0
	current_wave = 1
	current_hands.clear()
	deck_data.clear()
	hero_scene = null
	enemies_scenes.clear()
	selected_target = null
	board_complete_count = 1
	combo_multiplier = 1.0


# 下一回合
func next_turn():
	turn_number += 1
	player_tiles_placed = 0
	
	if turn_number > max_turns:
		# 回合數超限，視為失敗
		transition_to("defeat")
		return
	
	transition_to("player_turn", {"turn_number": turn_number})

func _connect_enemy_select_signals():
	for enemy in enemies_scenes:
		if enemy.has_signal("enemy_selected") and not enemy.enemy_selected.is_connected(_on_enemy_selected):
			enemy.enemy_selected.connect(_on_enemy_selected)

func _auto_select_first_enemy():
	for enemy in enemies_scenes:
		if enemy.is_alive:
			_on_enemy_selected(enemy)
			return
	selected_target = null
	EventBus.battle_target_changed.emit(null)
	EventBus.ui_lock_end_turn_button.emit()
	print("[BattleStateMachine] 目前無存活敵人，selected_target = null，鎖定回合結束按鈕")

func _on_enemy_selected(enemy: Node):
	selected_target = enemy
	EventBus.battle_target_changed.emit(enemy)
	print("[BattleStateMachine] 選取目標：", enemy.character_name, "（", enemy.character_id, "）")

# 檢查戰鬥的三個結果，勝利，失敗，載入下一波
func check_battle_end():
	#不能這樣看，因為敵人會留下屍體，要檢查 is_alive 屬性
	var alive_enemies_scenes = enemies_scenes.filter(func(enemy): return enemy.is_alive)
	print("[BattleStateMachine] 剩餘的敵人物件數量: ", alive_enemies_scenes.size(), ", 剩餘的敵人數量: ", enemies_remaining)
		
	if alive_enemies_scenes.size() == 0:
		if _has_more_waves():
			print("[BattleStateMachine] 準備載入下一波敵人")
			load_next_enemy_wave()
			return false
		else:
			var skipped = battle_data.get("enemies", []).filter(
				func(e): return e.get("wave", 1) > current_wave)
			if skipped.size() > 0:
				push_warning("[BattleStateMachine] %d 個敵人因波次跳號未出場，請檢查關卡資料" % skipped.size())
			transition_to("victory")
			return true
	
	# TODO: 檢查玩家是否失敗（血量為0等）
	var player_hp = hero_scene.get("current_hp")
	if player_hp <= 0:
		transition_to("defeat")
		return true
	
	return false

func _has_more_waves() -> bool:
	var level_id = battle_data.get("level_id", "")
	var enemies_data = ResourceManager.get_level_data(level_id).get("enemies", [])
	return enemies_data.any(func(e): return e.get("wave", 1) == current_wave + 1)

# 載入下一波敵人
func load_next_enemy_wave():

	await get_tree().create_timer(ResourceManager.get_balance_value("wave_transition_delay", 1.0)).timeout

	enemies_scenes = enemies_scenes.filter(func(enemy): return enemy.is_alive) #要先真的移除節點，才刪除陣列中的參考

	if enemies_scenes.size() != 0:
		push_warning("[BattleStateMachine] 出現邏輯錯誤：載入下一波前仍有存活敵人")
		return

	current_wave += 1
	var level_id = battle_data.get("level_id", "")
	var enemies_data = ResourceManager.get_level_data(level_id).get("enemies", [])
	enemies_scenes = create_enemies_from_data(enemies_data, current_wave)
	_connect_enemy_select_signals()
	_auto_select_first_enemy()
	enemies_remaining = enemies_scenes.size()

	print("[BattleStateMachine] 載入第 %d 波，共 %d 個敵人" % [current_wave, enemies_remaining])
	EventBus.ui_load_next_enemy_wave.emit(enemies_scenes)
	next_turn()



# EventBus 事件處理
func _on_battle_started(level_data: Dictionary):
	start_battle(level_data)

func _on_turn_started(turn_type: String):
	print("[BattleStateMachine] Turn started: ", turn_type)

func _on_skill_cast_requested():
	if not hero_scene or not hero_scene.skill_component:
		push_warning("[BattleStateMachine] 無法施放技能：hero 或 SkillComponent 不存在")
		return

	# 找第一個存活的敵人作為目標（之後有目標選擇 UI 再改）
	var target: Node = null
	for enemy in enemies_scenes:
		if enemy.is_alive:
			target = enemy
			break

	var context = {"target": target}
	var skill_component = hero_scene.skill_component

	var success = skill_component.cast_active_skill(context)
	if not success:
		print("[BattleStateMachine] 技能條件不滿足或無主動技能，無法施放")
	else:
		print("[BattleStateMachine] 施放技能成功")


func _on_skill_effect_requested(effect: Dictionary):
	var effect_type = effect.get("type", "")
	var target = effect.get("target") as Node
	var source = effect.get("source") as Node
	var amount = effect.get("amount", 0)
	var element = effect.get("element", "normal")

	if not is_instance_valid(target):
		push_warning("[BattleStateMachine] skill_effect_requested: 目標無效")
		return

	match effect_type:
		"damage":
			if target.has_method("take_damage"):
				target.take_damage(amount, element, source)
				if "is_alive" in target and not target.is_alive:
					EventBus.enemy_defeated.emit(target.name, {})
			else:
				push_warning("[BattleStateMachine] 目標沒有 take_damage 方法：" + target.name)
			check_battle_end()
		"heal":
			if target.has_method("heal"):
				target.heal(amount, source)
			else:
				push_warning("[BattleStateMachine] 目標沒有 heal 方法：" + target.name)
		_:
			push_warning("[BattleStateMachine] 未知的技能效果類型：" + effect_type)

func _update_combo_state(board_was_full: bool):
	if board_was_full:
		board_complete_count += 1
	else:
		board_complete_count = 1
	combo_multiplier = ResourceManager.get_combo_multiplier(board_complete_count)
	print("[BattleStateMachine] 棋盤填滿：", board_was_full, "，連續次數：", board_complete_count, "，combo_multiplier：x", combo_multiplier)

func _on_turn_ended(cards_in_ui: Array = [], board_was_full: bool = false, tiles_data: Array = []):
	_update_combo_state(board_was_full)
	battle_data["tiles_data"] = tiles_data
	print("[BattleStateMachine] Turn ended, cards remaining: ", cards_in_ui, "，tiles: ", tiles_data.size())
	
	# 處理已使用的卡片
	var used_cards: Array[String] = []
	for card_id in current_hands:
		if card_id not in cards_in_ui:
			used_cards.append(card_id)
	
	remove_used_cards(used_cards)
	refill_hand()
	
	battle_data["combo_multiplier"] = combo_multiplier
	
	transition_to("calculating", battle_data)

func _on_enemy_defeated(enemy_id: String, rewards: Dictionary):
	enemies_remaining -= 1
	print("[BattleStateMachine] Enemy defeated, remaining: ", enemies_remaining)
	if selected_target == null or not selected_target.is_alive:
		_auto_select_first_enemy()

func _on_block_placed(block_instance: Node, position: Vector2):
	player_tiles_placed += 1
	print("[BattleStateMachine] Tiles placed: ", player_tiles_placed, "/", max_tiles_per_turn)

func _on_damage_dealt(source: Node, target: Node, amount: int, type: String):
	print("[BattleStateMachine] Damage dealt: ", amount, " (", type, ")")

func handle_input(event: InputEvent):
	# 轉發給當前狀態
	if current_state:
		current_state.handle_input(event)

func create_hero_from_data(hero_data: Dictionary) -> Node:
	var hero_id = hero_data.get("hero_id", "")
	if hero_id == "":
		print("[BattleStateMachine] Error: No hero_id provided")
		return null
	
	var hero = ResourceManager.create_hero_with_overrides(hero_data)
	
	# 設置英雄位置（UI會負責添加到場景樹）
	hero.position = Vector2(540, 600)
	print("[BattleStateMachine] 創建英雄: ", hero_id, " 節點: ", hero)
	return hero

# 創建敵人場景
func create_enemies_from_data(enemies_data: Array, wave: int = 1) -> Array[Node]:
	var created_enemies: Array[Node] = []
	var number_of_enemies = 0
	
	for enemy_data in enemies_data:
		if enemy_data.has("wave") and enemy_data.get("wave") == wave:
			var enemy_id = enemy_data.get("enemy_id", "")
			if enemy_id != "":
				var enemy = ResourceManager.create_enemy_with_overrides(enemy_data)
				# 設置敵人位置（UI會負責添加到場景樹）
				enemy.position = Vector2(540 + number_of_enemies * 220 - ((enemies_data.size() - 1) * 110), 300)
				# 補上 instance index 確保 character_id 唯一
				enemy.character_id = enemy_id + "_" + str(number_of_enemies)
				#把它加入敵人群組
				enemy.add_to_group("enemy")
				created_enemies.append(enemy)
				number_of_enemies += 1
				print("[BattleStateMachine] 創建敵人: ", enemy.character_id, " 節點: ", enemy)
	
	print("[BattleStateMachine] 總共創建了 ", created_enemies.size(), " 個敵人，等待UI添加到場景樹")
	return created_enemies

# 初始化手牌
func setup_initial_hand(deck: Dictionary):
	var blocks_data = deck.get("block_ids", [])
	deck_data.clear()
	for block in blocks_data:
		deck_data.append(str(block))
	var deck_size = deck_data.size()
	current_hands.clear()
	
	var hand_size: int = ResourceManager.get_balance_value("hand_size", 4)
	while current_hands.size() < hand_size and deck_size > 0:
		var rand_index = randi() % deck_size
		var random_block = deck_data[rand_index]
		if not random_block in current_hands:
			current_hands.append(random_block)
	
	print("[BattleStateMachine] 初始手牌: ", current_hands)
	EventBus.hand_updated.emit(current_hands)

func refill_hand():
	var hand_size: int = ResourceManager.get_balance_value("hand_size", 4)
	while current_hands.size() < hand_size:
		var available_cards: Array[String] = []
		for card_id in deck_data:
			if card_id not in current_hands:
				available_cards.append(card_id)
		
		if available_cards.is_empty():
			print("[BattleStateMachine] 牌組已空，無法補充更多卡片")
			break
		
		var rand_index = randi() % available_cards.size()
		var drawn_card = available_cards[rand_index]
		current_hands.append(drawn_card)
		print("[BattleStateMachine] 抽到卡片: ", drawn_card)
	
	EventBus.hand_updated.emit(current_hands)

# 移除使用過的卡片
func remove_used_cards(used_cards: Array[String]):
	for card_id in used_cards:
		current_hands.erase(card_id)
		print("[BattleStateMachine] 移除已使用的卡片: ", card_id)

# 戰鬥狀態類定義

# 準備狀態
class PreparingState extends BaseState:
	func _init():
		super._init("preparing")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		
		# 載入關卡數據
		var level_id = data.get("level_id", "")
		if level_id.is_empty():
			print("[BattleStateMachine] Error: No level_id provided")
			state_machine.transition_to("defeat")
			return
		
		var active_deck: Dictionary = _get_active_deck()
		if active_deck.is_empty():
			print("[BattleStateMachine] Error: 無法取得卡組，請先建立卡組")
			state_machine.transition_to("defeat")
			return

		# 初始化戰場
		print("[BattleStateMachine] 準備關卡的UI, ID: ", level_id)
		print("[BattleStateMachine] 使用的牌組：", active_deck.get("name", "未命名"))

		await _setup_ui(level_id, active_deck)

		# 開始第一回合
		state_machine.next_turn()
	
	func can_transition_to(next_state_id: String) -> bool:
		return next_state_id in ["player_turn", "defeat"]

	#先把資料取出，之後把取出的資料用EventBus傳給UI去更新顯示
	func _get_level_data(level_id: String) -> Dictionary:
		var level_data = ResourceManager.get_level_data(level_id)
		#print("[BattleStateMachine] Retrieved level data: ", level_data)
		return level_data

	func _get_active_deck() -> Dictionary:
		var index: int = SaveManager.get_value("active_deck_index", -1)
		var decks: Array = SaveManager.get_value("decks", [])
		if index < 0 or index >= decks.size():
			return {}
		return decks[index]

	func _setup_ui(level_id: String, deck_data: Dictionary) -> void:
		var level_data: Dictionary = _get_level_data(level_id)

		#創建英雄場景
		var hero_id:String = level_data.get("hero_id", "") #關卡裡面的英雄只有ID
		#這裡要把String轉換成Dictionary
		var hero_data:Dictionary = {"hero_id": hero_id}
		state_machine.hero_scene = state_machine.create_hero_from_data(hero_data)
		
		# 先創建敵人場景實例
		var enemies_data = level_data.get("enemies", [])
		state_machine.enemies_scenes = state_machine.create_enemies_from_data(enemies_data)
		state_machine._connect_enemy_select_signals()
		state_machine._auto_select_first_enemy()

		# enemies_remaining = 當前波次場上的敵人數，_on_enemy_defeated 每次扣 1
		# 歸零時代表這一波全滅，由 current_wave 決定是否還有下一波
		state_machine.enemies_remaining = state_machine.enemies_scenes.size()
		
		# 設置初始手牌
		state_machine.setup_initial_hand(deck_data)

		
		# 發送UI設置信號
		EventBus.setup_battle_ui.emit(level_data, state_machine.enemies_scenes, state_machine.hero_scene)
		EventBus.setup_deck_ui.emit(state_machine.current_hands)
		
		# 加一點延遲確保UI有時間處理
		await state_machine.get_tree().process_frame

# 玩家回合狀態
class PlayerTurnState extends BaseState:
	var turn_timer: float = 30.0  # 30秒回合時間
	var time_remaining: float = 30.0
	
	func _init():
		super._init("player_turn")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		
		var turn_num = data.get("turn_number", 1)
		time_remaining = turn_timer
		
		print("[BattleStateMachine] Player turn ", turn_num, " started")
		
		# 通知UI更新
		EventBus.turn_started.emit("player")
		EventBus.ui_turn_timer_started.emit(turn_timer)
		EventBus.ui_unlock_end_turn_button.emit()
	
	func update(delta: float):
		super.update(delta)
		
		# 暫時移除倒數計時功能以便測試
		# time_remaining -= delta
		# 
		# # 更新UI倒數
		# EventBus.emit_signal("ui_turn_timer_updated", time_remaining)
		# 
		# # 時間到了自動結束回合
		# if time_remaining <= 0:
		# 	end_player_turn()
	
	func handle_input(event: InputEvent):
		super.handle_input(event)
		
		# 處理玩家輸入（圖塊放置等）
		if event is InputEventMouseButton and event.pressed:
			# 檢查是否點擊了送出按鈕
			if event.button_index == MOUSE_BUTTON_LEFT:
				# 這裡應該由UI系統處理，狀態機只監聽結果
				pass
	
	func on_event(event_name: String, event_data: Dictionary = {}):
		super.on_event(event_name, event_data)
		
		match event_name:
			"block_placed":
				# 檢查是否達到最大放置數量
				if state_machine.player_tiles_placed >= state_machine.max_tiles_per_turn:
					# 可以選擇自動結束回合或等待玩家確認
					pass

	func can_transition_to(next_state_id: String) -> bool:
		return next_state_id in ["calculating", "defeat", "victory", "player_turn"]

# 計算狀態
class CalculatingState extends BaseState:
	func _init():
		super._init("calculating")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		
		print("[BattleStateMachine] calculating damage with data: ", data)

		# 鎖住結束回合按鈕，進入玩家回合時再解鎖
		EventBus.ui_lock_end_turn_button.emit()

		await _calculate_damage()

		var alive = state_machine.enemies_scenes.filter(func(e): return e.is_alive)
		if alive.size() == 0:
			if state_machine._has_more_waves():
				state_machine.load_next_enemy_wave()  # async，結束後自己呼叫 next_turn()
			else:
				state_machine.transition_to("victory")
		else:
			state_machine.transition_to("enemy_turn")
	
	func _calculate_damage():
		var tiles_data: Array = state_machine.battle_data.get("tiles_data", [])
		var combo_multiplier: float = state_machine.battle_data.get("combo_multiplier", 1.0)
		var hero = state_machine.hero_scene
		var interval: float = ResourceManager.get_balance_value("tile_hit_interval", 0.3)

		if tiles_data.is_empty():
			print("[BattleStateMachine] 本回合沒有放置方塊，跳過傷害計算")
			EventBus.damage_calculated.emit({})
			return

		var base_attack: int = hero.get("base_attack") if hero else 0
		if base_attack <= 0:
			print("[BattleStateMachine] base_attack 為 0，跳過傷害計算")
			EventBus.damage_calculated.emit({})
			return

		print("[BattleStateMachine] 傷害計算開始，base_attack:", base_attack, " combo_multiplier:x", combo_multiplier, " tiles:", tiles_data.size())

		for tile in tiles_data:
			var element: String = tile.get("element", "neutral")
			var bonus_value: int = tile.get("bonus_value", 1)
			var target_type: String = tile.get("target_type", "single")
			var raw_damage: int = int(base_attack * bonus_value * combo_multiplier)

			if target_type == "all":
				var alive_enemies = state_machine.enemies_scenes.filter(func(e): return e.is_alive)
				for enemy in alive_enemies:
					_apply_damage_to_enemy(enemy, raw_damage, element, hero)
			else:
				var target = state_machine.selected_target
				if target and target.is_alive:
					_apply_damage_to_enemy(target, raw_damage, element, hero)
				else:
					print("[BattleStateMachine] 無有效目標，跳過此 tile (", element, " +", bonus_value, ")")

			await state_machine.get_tree().create_timer(interval).timeout

		EventBus.damage_calculated.emit({})

	func _apply_damage_to_enemy(enemy: Node, damage: int, element: String, source: Node):
		EventBus.ui_damage_animation_requested.emit(enemy, damage, element)
		var was_alive: bool = enemy.is_alive
		enemy.take_damage(damage, element, source)
		if was_alive and not enemy.is_alive:
			print("[BattleStateMachine] Enemy defeated: ", enemy.name)
			EventBus.enemy_defeated.emit(enemy.name, {})
	
	func can_transition_to(next_state_id: String) -> bool:
		return next_state_id in ["enemy_turn", "player_turn", "victory", "defeat"]

# 敵人回合狀態  
class EnemyTurnState extends BaseState:
	func _init():
		super._init("enemy_turn")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		
		print("[BattleStateMachine] Enemy turn started")

		#連接敵人行動處理
		if not EventBus.damage_dealt_to_hero.is_connected(_on_damage_dealt_to_hero):
			EventBus.damage_dealt_to_hero.connect(_on_damage_dealt_to_hero)
		
		await _process_enemy_actions()
		
		if not state_machine.check_battle_end():
			# 開始下一回合
			state_machine.next_turn()
	
	func _process_enemy_actions():
		var alive_enemies = state_machine.enemies_scenes.filter(func(enemy): return enemy.is_alive)
		if alive_enemies.size() > 0:
			print("[BattleStateMachine] 處理敵人倒數")
			for enemy in alive_enemies:
				enemy.tick_countdown()
	
	
	func can_transition_to(next_state_id: String) -> bool:
		return next_state_id in ["player_turn", "victory", "defeat"]

	func _on_damage_dealt_to_hero(source: Node, amount: int, damage_type: String):
		# 監聽對英雄的傷害事件
		state_machine.hero_scene.take_damage(amount, damage_type, source)
		var source_name = "環境傷害"
		if source and source.has_method("get_hero_info"):
			source_name = source.hero_name
		elif source and source.has_method("get_enemy_info"):
			source_name = source.enemy_name
		elif source:
			source_name = source.name

		#通知UI跳出傷害動畫
		EventBus.ui_damage_animation_requested.emit(state_machine.hero_scene, amount, damage_type)

		print("[BattleStateMachine] 英雄受到傷害事件: ", source_name, " → ", state_machine.hero_scene.hero_name, " (", amount, " ", damage_type, "傷害)")


# 勝利狀態
class VictoryState extends BaseState:
	func _init():
		super._init("victory")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		
		print("[BattleStateMachine] Victory!")
		
		# 計算獎勵
		var rewards = _calculate_rewards()
		
		# 結束戰鬥
		state_machine.end_battle("victory", rewards)
	
	func _calculate_rewards() -> Array:
		# TODO: 根據表現計算獎勵
		var rewards = []
		
		# 基礎獎勵
		rewards.append({"type": "gold", "amount": 100})
		rewards.append({"type": "exp", "amount": 50})
		
		# 根據回合數給予額外獎勵
		if state_machine.turn_number <= 5:
			rewards.append({"type": "perfect_bonus", "amount": 50})
		
		return rewards
	
	func can_transition_to(next_state_id: String) -> bool:
		return false  # 勝利狀態是終結狀態

# 失敗狀態
class DefeatState extends BaseState:
	func _init():
		super._init("defeat")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		
		print("[BattleStateMachine] Defeat...")
		
		# 結束戰鬥
		state_machine.end_battle("defeat", [])
	
	func can_transition_to(next_state_id: String) -> bool:
		return false  # 失敗狀態是終結狀態
