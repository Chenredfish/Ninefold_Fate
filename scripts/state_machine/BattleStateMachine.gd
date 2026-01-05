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
	enemies_remaining = level_data.get("enemies", []).size()
	
	transition_to("preparing", battle_data)

# 結束戰鬥
func end_battle(result: String, rewards: Array = []):
	EventBus.emit_signal("battle_ended", result, rewards)
	
	# 重置戰鬥數據
	battle_data.clear()
	turn_number = 0
	player_tiles_placed = 0
	enemies_remaining = 0

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

func _on_turn_ended():
	print("[BattleStateMachine] Turn ended, transitioning to calculation")
	transition_to("calculating")

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
		EventBus.emit_signal("setup_battle_ui", level_data)
		EventBus.emit_signal("setup_deck_ui", deck_data)
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
		
		time_remaining -= delta
		
		# 更新UI倒數
		EventBus.emit_signal("ui_turn_timer_updated", time_remaining)
		
		# 時間到了自動結束回合
		if time_remaining <= 0:
			end_player_turn()
	
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
		EventBus.emit_signal("turn_ended")
	
	func can_transition_to(next_state_id: String) -> bool:
		return next_state_id in ["calculating", "defeat", "victory"]

# 計算狀態
class CalculatingState extends BaseState:
	func _init():
		super._init("calculating")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		
		print("[BattleStateMachine] Calculating damage...")
		
		# 計算傷害
		_calculate_damage()
		
		# 短暫延遲顯示結果
		await state_machine.get_tree().create_timer(1.0).timeout
		
		# 檢查戰鬥是否結束
		if not state_machine.check_battle_end():
			# 戰鬥未結束，進入敵人回合
			state_machine.transition_to("enemy_turn")
	
	func _calculate_damage():
		# TODO: 實際的傷害計算邏輯
		# 這裡應該：
		# 1. 分析玩家放置的圖塊
		# 2. 計算連擊和屬性加成
		# 3. 對敵人造成傷害
		# 4. 觸發技能效果
		
		# 模擬傷害計算
		var damage_info = {
			"total_damage": 100,
			"combo_multiplier": 1.5,
			"element_bonus": 1.2,
			"targets": ["enemy_1"]
		}
		
		EventBus.emit_signal("damage_calculated", damage_info)
		print("[BattleStateMachine] Calculated damage: ", damage_info.total_damage)
	
	func can_transition_to(next_state_id: String) -> bool:
		return next_state_id in ["enemy_turn", "victory", "defeat"]

# 敵人回合狀態  
class EnemyTurnState extends BaseState:
	func _init():
		super._init("enemy_turn")
	
	func enter(previous_state: BaseState = null, data: Dictionary = {}):
		super.enter(previous_state, data)
		
		print("[BattleStateMachine] Enemy turn started")
		
		# 處理所有敵人的行動
		_process_enemy_actions()
		
		# 敵人行動完成後，檢查戰鬥狀態
		await state_machine.get_tree().create_timer(2.0).timeout
		
		if not state_machine.check_battle_end():
			# 開始下一回合
			state_machine.next_turn()
	
	func _process_enemy_actions():
		# TODO: 處理敵人行動
		# 1. 更新敵人倒數
		# 2. 執行攻擊（倒數為0的敵人）
		# 3. 應用狀態效果
		
		var enemies = state_machine.battle_data.get("enemies", [])
		for enemy_data in enemies:
			var enemy_id = enemy_data.get("id", "")
			var cooldown = enemy_data.get("cooldown", 3)
			
			# 倒數減1
			cooldown -= 1
			enemy_data["cooldown"] = cooldown
			
			if cooldown <= 0:
				# 敵人攻擊
				_enemy_attack(enemy_data)
				# 重置倒數
				enemy_data["cooldown"] = enemy_data.get("max_cooldown", 3)
		
		EventBus.emit_signal("enemies_updated", enemies)
	
	func _enemy_attack(enemy_data: Dictionary):
		var damage = enemy_data.get("attack", 10)
		var enemy_id = enemy_data.get("id", "")
		
		print("[BattleStateMachine] Enemy ", enemy_id, " attacks for ", damage, " damage")
		
		# 對玩家造成傷害
		EventBus.emit_signal("damage_dealt", null, null, damage, "enemy_attack")
		
		# 更新玩家血量
		var current_hp = state_machine.battle_data.get("player_hp", 100)
		current_hp -= damage
		state_machine.battle_data["player_hp"] = current_hp
		
		EventBus.emit_signal("player_hp_changed", current_hp)
	
	func can_transition_to(next_state_id: String) -> bool:
		return next_state_id in ["player_turn", "victory", "defeat"]

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
