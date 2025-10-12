# 九重運命 - 狀態機系統使用說明書

## 📋 目錄
- [概述](#概述)
- [系統架構](#系統架構)
- [核心組件](#核心組件)
- [使用方法](#使用方法)
- [實戰範例](#實戰範例)
- [進階功能](#進階功能)
- [調試工具](#調試工具)
- [最佳實踐](#最佳實踐)
- [常見問題](#常見問題)

---

## 概述

九重運命的狀態機系統是一個多層次、事件驅動的狀態管理框架，專為複雜的遊戲流程設計。系統包含兩個主要狀態機：

- **遊戲場景狀態機** - 管理主選單、戰鬥、結算等場景切換
- **戰鬥狀態機** - 管理戰鬥內部的回合制流程

拖放功能由現有的 **DragDropManager** 單例處理，無需額外的狀態機。

## 系統架構

### 架構圖
```
StateManager (AutoLoad)
├── GameSceneStateMachine (場景管理)
│   ├── MainMenuState
│   ├── LevelSelectionState
│   ├── BattleState
│   ├── ResultState
│   └── SettingsState
└── BattleStateMachine (戰鬥管理，動態創建)
    ├── PreparingState
    ├── PlayerTurnState
    ├── CalculatingState
    ├── EnemyTurnState
    ├── VictoryState
    └── DefeatState

DragDropManager (AutoLoad) - 獨立處理拖放邏輯
├── 拖拽狀態管理
├── 拖拽預覽系統
├── 投放區域檢測
└── 動畫效果處理
```

### 事件流向
```
EventBus ←→ StateManager ←→ StateMachines ←→ Game Objects
            ↓                     ↑
     DragDropManager ←→ DraggableTiles & DropZones
```

---

## 核心組件

### 1. BaseState (基礎狀態類)
所有具體狀態的基類，提供狀態生命週期管理。

```gdscript
class_name BaseState extends RefCounted

# 主要方法
func enter(previous_state: BaseState = null, data: Dictionary = {})  # 進入狀態
func exit(next_state: BaseState = null)                             # 離開狀態
func update(delta: float)                                           # 每幀更新
func handle_input(event: InputEvent)                               # 處理輸入
func can_transition_to(next_state_id: String) -> bool              # 轉換檢查
func on_event(event_name: String, event_data: Dictionary = {})     # 事件處理
```

### 2. BaseStateMachine (基礎狀態機類)
狀態機核心邏輯，管理狀態轉換和生命週期。

```gdscript
class_name BaseStateMachine extends Node

# 主要方法
func add_state(state: BaseState) -> bool                           # 添加狀態
func transition_to(state_id: String, data: Dictionary = {}) -> bool # 狀態轉換
func get_current_state_id() -> String                              # 獲取當前狀態
func is_in_state(state_id: String) -> bool                        # 檢查狀態
func go_back(data: Dictionary = {}) -> bool                        # 返回上一狀態

# 信號
signal state_changed(previous_state_id: String, current_state_id: String)
signal transition_failed(from_state_id: String, to_state_id: String, reason: String)
```

### 3. StateManager (狀態機管理器 AutoLoad)
統一管理所有狀態機實例，提供全域控制接口。

```gdscript
# 主要屬性
var game_scene_state_machine: GameSceneStateMachine
var battle_state_machine: BattleStateMachine  # 動態創建

# 主要方法
func register_state_machine(name: String, state_machine: BaseStateMachine)
func get_state_machine(name: String) -> BaseStateMachine
func change_scene(scene_type, data: Dictionary = {})
func start_drag(object: Node, position: Vector2) -> bool  # 委託給DragDropManager
```

---

## 使用方法

### 項目設置

1. **配置 AutoLoad**
   在 `project.godot` 中添加：
   ```
   [autoload]
   EventBus="*res://singletons/EventBus.gd"
   StateManager="*res://singletons/StateManager.gd"
   ```

2. **確保腳本位置**
   ```
   scripts/state_machine/
   ├── BaseState.gd
   ├── BaseStateMachine.gd
   ├── GameSceneStateMachine.gd
   ├── BattleStateMachine.gd
   └── DragDropStateMachine.gd
   ```

### 基本使用

#### 場景切換
```gdscript
# 方法1：使用StateManager便利方法
StateManager.go_to_main_menu()
StateManager.go_to_battle("level_001")
StateManager.go_to_result("victory", [{"type": "gold", "amount": 100}])

# 方法2：使用場景類型枚舉
StateManager.change_scene(GameSceneStateMachine.SceneType.MAIN_MENU)

# 方法3：通過EventBus
EventBus.scene_transition_requested.emit("level_selection", {"chapter": 1})
```

#### 拖放操作（使用現有DragDropManager）
```gdscript
# 開始拖拽
func _on_tile_input_event(viewport: Node, event: InputEvent, shape_idx: int):
    if event is InputEventMouseButton and event.pressed:
        # 直接使用DragDropManager
        DragDropManager.start_drag(self, event.global_position)
        # 或通過StateManager委託
        StateManager.start_drag(self, event.global_position)

# 監聽拖放事件（使用DragDropManager的信號）
func _ready():
    DragDropManager.tile_drag_started.connect(_on_drag_started)
    DragDropManager.tile_drag_ended.connect(_on_drag_ended)
    DragDropManager.navigation_requested.connect(_on_navigation_requested)

func _on_drag_ended(tile_data: Dictionary, drop_zone, success: bool):
    if success:
        print("成功放置圖塊到 ", drop_zone.name if drop_zone else "未知區域")
    else:
        print("拖放失敗")
```

#### 戰鬥控制
```gdscript
# 開始戰鬥（自動創建戰鬥狀態機）
EventBus.battle_started.emit({
    "level_id": "level_001",
    "enemies": [...],
    "player_hp": 100
})

# 提交玩家回合
StateManager.submit_player_turn()

# 監聽戰鬥狀態
func _ready():
    EventBus.turn_started.connect(_on_turn_started)
    EventBus.damage_calculated.connect(_on_damage_calculated)

func _on_turn_started(turn_number: int):
    print("第 ", turn_number, " 回合開始")
```

---

## 實戰範例

### 範例1：自定義場景狀態

```gdscript
# 創建商店場景狀態
class ShopState extends BaseState:
    func _init():
        super._init("shop")
    
    func enter(previous_state: BaseState = null, data: Dictionary = {}):
        super.enter(previous_state, data)
        
        # 載入商店場景
        var shop_scene = load("res://scenes/Shop.tscn").instantiate()
        get_tree().root.add_child(shop_scene)
        
        # 初始化商店數據
        if shop_scene.has_method("initialize_shop"):
            shop_scene.initialize_shop(data)
        
        EventBus.emit_signal("scene_entered", "shop")
    
    func can_transition_to(next_state_id: String) -> bool:
        # 商店可以返回主選單或進入其他場景
        return next_state_id in ["main_menu", "battle", "level_selection"]

# 添加到場景狀態機
func _ready():
    var scene_sm = StateManager.get_state_machine("game_scene")
    scene_sm.add_state(ShopState.new())
```

### 範例2：自定義戰鬥狀態

```gdscript
# 創建技能選擇狀態
class SkillSelectionState extends BaseState:
    var available_skills: Array = []
    var selected_skill: String = ""
    
    func _init():
        super._init("skill_selection")
    
    func enter(previous_state: BaseState = null, data: Dictionary = {}):
        super.enter(previous_state, data)
        
        available_skills = data.get("skills", [])
        
        # 顯示技能選擇UI
        EventBus.emit_signal("ui_popup_requested", "skill_selection", {
            "skills": available_skills
        })
    
    func on_event(event_name: String, event_data: Dictionary = {}):
        super.on_event(event_name, event_data)
        
        match event_name:
            "skill_selected":
                selected_skill = event_data.get("skill_id", "")
                _confirm_skill_selection()
    
    func _confirm_skill_selection():
        # 執行技能並返回戰鬥狀態
        EventBus.emit_signal("skill_activated", selected_skill)
        state_machine.transition_to("calculating", {"skill_used": selected_skill})
```

### 範例3：高級拖放邏輯

```gdscript
# 擴展拖放狀態機支持多選
class MultiSelectDragState extends BaseState:
    var selected_objects: Array = []
    
    func _init():
        super._init("multi_dragging")
    
    func enter(previous_state: BaseState = null, data: Dictionary = {}):
        super.enter(previous_state, data)
        
        selected_objects = data.get("objects", [])
        
        # 創建多物件預覽
        _create_multi_preview()
    
    func handle_input(event: InputEvent):
        super.handle_input(event)
        
        if event is InputEventMouseMotion:
            _update_multi_preview_positions(event.global_position)
    
    func _create_multi_preview():
        # 為每個選中物件創建預覽
        for obj in selected_objects:
            # 實現多物件預覽邏輯
            pass
```

---

## 進階功能

### 狀態歷史追蹤

```gdscript
# 獲取狀態歷史
var scene_sm = StateManager.get_state_machine("game_scene")
var debug_info = scene_sm.get_debug_info()
print("狀態歷史: ", debug_info.state_history)

# 返回上一狀態
scene_sm.go_back()
```

### 條件狀態轉換

```gdscript
class ConditionalState extends BaseState:
    func can_transition_to(next_state_id: String) -> bool:
        match next_state_id:
            "battle":
                # 檢查是否有足夠體力
                return GameData.player_energy > 0
            "shop":
                # 檢查是否解鎖商店
                return GameData.shop_unlocked
            _:
                return true
```

### 狀態數據持久化

```gdscript
# 保存狀態數據
func save_state_data():
    var state_data = {
        "current_scene": StateManager.get_current_scene_state(),
        "scene_history": StateManager.game_scene_state_machine.state_history,
        "battle_state": StateManager.get_current_battle_state()
    }
    
    # 保存到文件或玩家數據
    GameData.save_state_machine_data(state_data)

# 恢復狀態數據
func restore_state_data():
    var state_data = GameData.load_state_machine_data()
    
    if state_data.has("current_scene"):
        StateManager.game_scene_state_machine.transition_to(state_data.current_scene)
```

---

## 調試工具

### 狀態機調試面板

```gdscript
# 顯示調試信息
StateManager.print_debug_info()

# 獲取詳細調試數據
var debug_data = StateManager.get_debug_info()
for sm_name in debug_data.state_machines:
    var sm_info = debug_data.state_machines[sm_name]
    print(sm_name, ": ", sm_info.current_state)
```

### 實時狀態監控

```gdscript
# 監聽所有狀態變化
func _ready():
    EventBus.state_changed.connect(_on_any_state_changed)

func _on_any_state_changed(sm_name: String, prev_state: String, current_state: String):
    print("[", sm_name, "] ", prev_state, " -> ", current_state)
```

### 錯誤診斷

```gdscript
# 監聽轉換失敗
func _ready():
    EventBus.transition_failed.connect(_on_transition_failed)

func _on_transition_failed(sm_name: String, from_state: String, to_state: String, reason: String):
    push_error("狀態轉換失敗: [" + sm_name + "] " + from_state + " -> " + to_state + " (" + reason + ")")
```

---

## 最佳實踐

### 1. 狀態設計原則
- **單一職責**: 每個狀態只負責一個明確的遊戲狀態
- **最小化數據**: 狀態間只傳遞必要的數據
- **避免循環依賴**: 狀態不應直接引用其他狀態

### 2. 事件驅動設計
```gdscript
# ✅ 好的做法：使用事件通信
func on_enemy_defeated():
    EventBus.emit_signal("enemy_defeated", enemy_id, rewards)

# ❌ 避免：直接調用狀態機方法
func on_enemy_defeated():
    battle_state_machine.transition_to("victory")  # 緊耦合
```

### 3. 錯誤處理
```gdscript
# 總是檢查狀態轉換結果
var success = state_machine.transition_to("next_state")
if not success:
    print("狀態轉換失敗，執行備用邏輯")
    # 執行備用邏輯
```

### 4. 性能優化
```gdscript
# 避免在update中執行複雜邏輯
func update(delta: float):
    # ✅ 輕量級操作
    time_remaining -= delta
    
    # ❌ 避免重複的複雜計算
    # calculate_complex_ai_behavior()  
```

---

## 常見問題

### Q: 如何添加新的遊戲場景？
A: 
1. 在 `GameSceneStateMachine.SceneType` 枚舉中添加新類型
2. 更新 `scene_paths` 和 `scene_state_mapping` 字典
3. 創建對應的狀態類
4. 在 `_initialize_scene_states()` 中添加狀態

### Q: 戰鬥狀態機何時創建和銷毀？
A: 戰鬥狀態機在收到 `battle_started` 事件時自動創建，在 `battle_ended` 事件時自動銷毀。這確保了記憶體的有效利用。

### Q: 如何擴展拖放功能支持新的操作？
A: 
1. 在 `DragDropStateMachine` 中添加新的狀態類
2. 擴展 `DragDropStateType` 枚舉
3. 實現具體的拖放邏輯
4. 通過EventBus發送相關事件

### Q: 狀態機之間如何通信？
A: 狀態機之間不應直接通信，而是通過EventBus發送事件。StateManager會協調不同狀態機的行為。

### Q: 如何調試狀態轉換問題？
A: 
1. 啟用調試模式：`StateManager.set_debug_enabled(true)`
2. 監聽 `transition_failed` 事件
3. 使用 `print_debug_info()` 查看狀態機狀態
4. 檢查 `can_transition_to()` 方法的邏輯

---

## 總結

九重運命的狀態機系統提供了：
- 🎯 **清晰的架構** - 分層設計，職責明確
- 🔄 **靈活的擴展** - 易於添加新狀態和功能  
- 🎭 **事件驅動** - 鬆耦合的組件通信
- 🛠️ **豐富的工具** - 完整的調試和監控功能
- 📚 **完善的文檔** - 詳細的使用指南和範例

通過合理使用這個狀態機系統，你可以輕鬆管理複雜的遊戲流程，讓代碼更加清晰、可維護和可擴展。