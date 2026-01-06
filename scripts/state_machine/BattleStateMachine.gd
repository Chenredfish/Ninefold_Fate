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
var max_turns: int = 100  # 防止無限戰鬥

# 戰鬥狀態
var player_tiles_placed: int = 0
var max_tiles_per_turn: int = 100
var enemies_remaining: int = 0
var hero_scene: Node = null        # 英雄場景實例 (Hero節點)
var enemies_scenes: Array[Node] = []    # 敵人場景實例 (Enemy節點)
var current_hands: Array[String] = []   # 當前手牌 (方塊ID字串陣列)
var deck_data: Array[String] = []       # 牌組數據 (可用方塊ID字串陣列)

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
	EventBus.emit_signal("battle_ended", result, rewards)
	
	# 清理敵人場景
	for enemy in enemies_scenes:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies_scenes.clear()
	
	# 重置戰鬥數據
	battle_data.clear()
	turn_number = 0
	player_tiles_placed = 0
	enemies_remaining = 0
	current_hands.clear()
	deck_data.clear()

# 下一回合
func next_turn():
	turn_number += 1
	player_tiles_placed = 0
	
	if turn_number > max_turns:
		# 回合數超限，視為失敗
		transition_to("defeat")
		return
	
	transition_to("player_turn", {"turn_number": turn_number})

# 檢查戰鬥是否應該結束
func check_battle_end():
	if enemies_remaining <= 0:
		transition_to("victory")
		return true
	
	# TODO: 檢查玩家是否失敗（血量為0等）
	var player_hp = battle_data.get("player_hp", 100)
	if player_hp <= 0:
		transition_to("defeat")
		return true
	
	return false

# EventBus 事件處理
func _on_battle_started(level_data: Dictionary):
	start_battle(level_data)

func _on_turn_started(turn_num: int):
	print("[BattleStateMachine] Turn ", turn_num, " started")

func _on_turn_ended(total_damage: int = 0, cards_in_ui: Array = []):
	print("[BattleStateMachine] Turn ended, damage dealt: ", total_damage, ", cards remaining: ", cards_in_ui)
	
	# 處理已使用的卡片
	var used_cards: Array[String] = []
	for card_id in current_hands:
		if card_id not in cards_in_ui:
			used_cards.append(card_id)
	
	remove_used_cards(used_cards)
	refill_hand()
	
	# 儲存UI傷害數據供計算狀態使用
	battle_data["ui_damage"] = total_damage
	
	transition_to("calculating", battle_data)

func _on_enemy_defeated(enemy_id: String, rewards: Dictionary):
	enemies_remaining -= 1
	print("[BattleStateMachine] Enemy defeated, remaining: ", enemies_remaining)
	
	# 檢查是否所有敵人都被擊敗
	if not check_battle_end():
		# 繼續戰鬥
		pass

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
func create_enemies_from_data(enemies_data: Array) -> Array[Node]:
	var created_enemies: Array[Node] = []
	var number_of_enemies = 0
	
	for enemy_data in enemies_data:
		if enemy_data.has("wave") and enemy_data.get("wave") == 1:
			var enemy_id = enemy_data.get("enemy_id", "")
			if enemy_id != "":
				var enemy = ResourceManager.create_enemy_with_overrides(enemy_data)
				# 設置敵人位置（UI會負責添加到場景樹）
				enemy.position = Vector2(540 + number_of_enemies * 220 - ((enemies_data.size() - 1) * 110), 300)
				created_enemies.append(enemy)
				number_of_enemies += 1
				print("[BattleStateMachine] 創建敵人: ", enemy_id, " 節點: ", enemy)
	
	print("[BattleStateMachine] 總共創建了 ", created_enemies.size(), " 個敵人，等待UI添加到場景樹")
	return created_enemies

# 初始化手牌
func setup_initial_hand(deck: Dictionary):
	var blocks_data = deck.get("blocks", [])
	deck_data.clear()
	for block in blocks_data:
		deck_data.append(str(block))
	var deck_size = deck_data.size()
	current_hands.clear()
	
	# 隨機抽4張卡
	while current_hands.size() < 4 and deck_size > 0:
		var rand_index = randi() % deck_size
		var random_block = deck_data[rand_index]
		if not random_block in current_hands:
			current_hands.append(random_block)
	
	print("[BattleStateMachine] 初始手牌: ", current_hands)
	EventBus.emit_signal("hand_updated", current_hands)

# 補充手牌到4張
func refill_hand():
	while current_hands.size() < 4:
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
	
	EventBus.emit_signal("hand_updated", current_hands)

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
		
		var deck_id = data.get("deck_id", "")
		if deck_id.is_empty():
			#先用預設deck
			deck_id = "deck00"
		
		# 初始化戰場
		print("[BattleStateMachine] 準備關卡的UI, ID: ", level_id)
		print("[BattleStateMachine] 使用的牌組UI, ID: ", deck_id)
		
		# 模擬載入時間（實際中可能需要載入資源）
		await _setup_ui(level_id, deck_id)
		# 等待 UI 更新完成
		await EventBus.battle_ui_update_complete.connect(func(): pass, Object.CONNECT_ONE_SHOT)
		
		# 開始第一回合
		state_machine.next_turn()
	
	func can_transition_to(next_state_id: String) -> bool:
		return next_state_id in ["player_turn", "defeat"]

	#先把資料取出，之後把取出的資料用EventBus傳給UI去更新顯示
	func _get_level_data(level_id: String) -> Dictionary:
		var level_data = ResourceManager.get_level_data(level_id)
		#print("[BattleStateMachine] Retrieved level data: ", level_data)
		return level_data

	func _get_deck_data(deck_id: String) -> Dictionary:
		var deck_data = ResourceManager.get_deck_data(deck_id)
		print("[BattleStateMachine] Retrieved deck data: ", deck_data)
		return deck_data

	func _setup_ui(level_id: String, deck_id: String) -> void:
		var level_data: Dictionary = _get_level_data(level_id)
		var deck_data: Dictionary = _get_deck_data(deck_id)

		#創建英雄場景
		var hero_id:String = level_data.get("hero_id", "") #關卡裡面的英雄只有ID
		#這裡要把String轉換成Dictionary
		var hero_data:Dictionary = {"hero_id": hero_id}
		state_machine.hero_scene = state_machine.create_hero_from_data(hero_data)
		
		# 先創建敵人場景實例
		var enemies_data = level_data.get("enemies", [])
		state_machine.enemies_scenes = state_machine.create_enemies_from_data(enemies_data)
		
		# 根據實際創建的敵人數量設定 enemies_remaining
		state_machine.enemies_remaining = state_machine.enemies_scenes.size()
		
		# 設置初始手牌
		state_machine.setup_initial_hand(deck_data)

		
		# 發送UI設置信號
		EventBus.emit_signal("setup_battle_ui", level_data, state_machine.enemies_scenes, state_machine.hero_scene)
		EventBus.emit_signal("setup_deck_ui", state_machine.current_hands)
		
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
		EventBus.emit_signal("turn_started", turn_num)
		EventBus.emit_signal("ui_turn_timer_started", turn_timer)
	
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
			"player_turn_submit":
				end_player_turn()
			"block_placed":
				# 檢查是否達到最大放置數量
				if state_machine.player_tiles_placed >= state_machine.max_tiles_per_turn:
					# 可以選擇自動結束回合或等待玩家確認
					pass
	
	func end_player_turn():
		print("[BattleStateMachine] Player turn ended")
		# 直接發送回合結束事件，由UI處理具體數據
		EventBus.emit_signal("turn_ended")
	
	func can_transition_to(next_state_id: String) -> bool:
		return next_state_id in ["calculating", "defeat", "victory"]

# 計算狀態
class CalculatingState extends BaseState:
	func _init():
		super._init("calculating")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		
		print("[BattleStateMachine] calculating damage with data: ", data)
		
		# 計算傷害
		_calculate_damage()
		
		# 短暫延遲顯示結果
		await state_machine.get_tree().create_timer(1.0).timeout
		
		# 檢查戰鬥是否結束
		if not state_machine.check_battle_end():
			# 戰鬥未結束，進入敵人回合
			state_machine.transition_to("enemy_turn")
	
	func _calculate_damage():
		# 使用從UI傳來的傷害數據
		var ui_damage = state_machine.battle_data.get("ui_damage", 0)
		var damage_info = {
			"total_damage": ui_damage,
			"combo_multiplier": 1.0,
			"element_bonus": 1.0,
			"targets": []
		}
		
		# 如果沒有傷害，直接跳過
		if ui_damage <= 0:
			print("[BattleStateMachine] No damage dealt this turn")
			EventBus.emit_signal("damage_calculated", damage_info)
			return
		
		# 對敵人造成傷害並檢查死亡
		var enemies_defeated = 0
		print("[BattleStateMachine] enemies_scenes 數組大小: ", state_machine.enemies_scenes.size())
		for i in range(state_machine.enemies_scenes.size()):
			var enemy = state_machine.enemies_scenes[i]
			print("[BattleStateMachine] 敵人 ", i, ": ", enemy, " 是否有效: ", enemy != null)
			if enemy and enemy.has_method("take_damage"):
				print("[BattleStateMachine] 對敵人 ", enemy.name, " 造成傷害: ", ui_damage)
				var was_alive = enemy.is_alive if "is_alive" in enemy else true
				enemy.take_damage(ui_damage)
				# 檢查敵人是否在這次攻擊後死亡
				var is_alive_now = enemy.is_alive if "is_alive" in enemy else true
				if was_alive and not is_alive_now:
					enemies_defeated += 1
					print("[BattleStateMachine] Enemy defeated: ", enemy.name)
					# 發送敵人被擊敗事件
					EventBus.emit_signal("enemy_defeated", enemy.name, {})
					damage_info.targets.append(enemy.name)
			else:
				print("[BattleStateMachine] 敵人 ", i, " 無法接收傷害或已無效")
		
		# 更新剩餘敵人數量
		state_machine.enemies_remaining -= enemies_defeated
		print("[BattleStateMachine] Enemies remaining after damage: ", state_machine.enemies_remaining)
		
		EventBus.emit_signal("damage_calculated", damage_info)
		print("[BattleStateMachine] Calculated damage: ", ui_damage, " to ", enemies_defeated, " enemies")
	
	func can_transition_to(next_state_id: String) -> bool:
		return next_state_id in ["enemy_turn", "victory", "defeat"]

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
		state_machine.hero_scene.take_damage(amount, damage_type, source)
		"""監聽對英雄的傷害事件"""
		var source_name = "環境傷害"
		if source and source.has_method("get_hero_info"):
			source_name = source.hero_name
		elif source and source.has_method("get_enemy_info"):
			source_name = source.enemy_name
		elif source:
			source_name = source.name

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
