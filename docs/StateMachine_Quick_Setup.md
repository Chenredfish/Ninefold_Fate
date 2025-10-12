# 狀態機系統快速設置指南

## 🚀 快速開始

### 1. 項目設置

#### 添加 AutoLoad
在 Godot 編輯器中：
1. 打開 `Project -> Project Settings`
2. 切換到 `AutoLoad` 選項卡
3. 添加以下 AutoLoad（按順序）：

```
名稱: EventBus        路徑: res://singletons/EventBus.gd        啟用: ✓
名稱: StateManager    路徑: res://singletons/StateManager.gd    啟用: ✓
```

#### 檢查文件結構
確保以下文件存在：
```
singletons/
├── EventBus.gd
└── StateManager.gd

scripts/state_machine/
├── BaseState.gd
├── BaseStateMachine.gd
├── GameSceneStateMachine.gd
└── BattleStateMachine.gd

test_scenes/
├── StateMachineTest.gd
└── StateMachineTestScene.tscn

docs/
└── StateMachine_Usage_Guide.md
```

### 2. 運行測試

1. **自動測試**：
   - 運行項目，狀態機系統會自動初始化
   - 檢查控制台輸出確認初始化成功

2. **手動測試**：
   - 在場景樹中添加 `StateMachineTestScene.tscn`
   - 運行場景查看測試結果

### 3. 基本集成

#### 在主場景中使用
```gdscript
# Main.gd
extends Node

func _ready():
    # 等待狀態機初始化
    await get_tree().process_frame
    
    # 開始使用狀態機
    StateManager.go_to_main_menu()

# 場景切換示例
func go_to_battle():
    StateManager.go_to_battle("level_001")

func go_to_settings():
    StateManager.go_to_settings()
```

#### 在UI中使用拖放
```gdscript
# DraggableTile.gd
extends Control

func _gui_input(event: InputEvent):
    if event is InputEventMouseButton and event.pressed:
        # 直接使用現有的DragDropManager
        DragDropManager.start_drag(self, event.global_position)
        # 或通過StateManager委託（內部調用DragDropManager）
        # StateManager.start_drag(self, event.global_position)
```

#### 監聽狀態事件
```gdscript
# GameUI.gd
extends Control

func _ready():
    # 場景和戰鬥事件
    EventBus.scene_entered.connect(_on_scene_entered)
    EventBus.battle_started.connect(_on_battle_started)
    
    # 拖放事件（使用DragDropManager）
    DragDropManager.tile_drag_ended.connect(_on_drag_ended)

func _on_scene_entered(scene_name: String):
    print("進入場景: ", scene_name)

func _on_battle_started(level_data: Dictionary):
    print("戰鬥開始: ", level_data.level_id)

func _on_drag_ended(tile_data: Dictionary, drop_zone, success: bool):
    print("拖放", "成功" if success else "失敗")
```

### 4. 驗證安裝

運行以下代碼來驗證安裝：
```gdscript
# 在任意腳本中運行
func verify_state_machine_setup():
    print("=== 狀態機系統驗證 ===")
    
    # 檢查AutoLoad
    if StateManager == null:
        print("❌ StateManager 未正確載入")
        return false
    
    if EventBus == null:
        print("❌ EventBus 未正確載入")
        return false
    
    # 檢查狀態機
    var scene_sm = StateManager.get_state_machine("game_scene")
    var drag_sm = StateManager.get_state_machine("drag_drop")
    
    if scene_sm == null:
        print("❌ 遊戲場景狀態機未創建")
        return false
    
    # 檢查DragDropManager（取代拖放狀態機）
    if DragDropManager == null:
        print("❌ DragDropManager 未正確載入")
        return false
    
    print("✅ 狀態機系統安裝成功！")
    print("當前場景狀態: ", StateManager.get_current_scene_state())
    print("當前拖放狀態: ", StateManager.get_current_drag_drop_state())
    print("DragDropManager狀態: ", "空閒" if DragDropManager.current_dragging_tile == null else "拖拽中")
    
    return true
```

## 🔧 常見設置問題

### 問題1：AutoLoad 載入失敗
**症狀**: 控制台提示找不到腳本文件
**解決**: 檢查文件路徑是否正確，確保所有依賴的類文件存在

### 問題2：狀態機未初始化
**症狀**: `StateManager.get_state_machine()` 返回 null
**解決**: 確保在 `_ready()` 後等待一幀再使用狀態機

### 問題3：事件未觸發
**症狀**: EventBus 事件沒有回應
**解決**: 檢查信號連接是否正確，確保使用正確的事件名稱

## 📝 項目集成清單

- [ ] 添加 AutoLoad 設定
- [ ] 複製所有狀態機腳本文件
- [ ] 更新現有場景腳本以使用狀態機
- [ ] 測試場景切換功能
- [ ] 測試拖放功能（與現有DragDropManager整合）
- [ ] 測試戰鬥流程
- [ ] 添加錯誤處理
- [ ] 配置調試選項

## 🎯 下一步

1. **閱讀完整文檔**: 查看 `StateMachine_Usage_Guide.md` 了解詳細用法
2. **自訂狀態**: 根據項目需求添加新的遊戲狀態
3. **擴展功能**: 實現項目特定的狀態轉換邏輯
4. **性能優化**: 根據實際使用情況調整狀態機配置

狀態機系統現在已經準備就緒，可以開始構建你的遊戲邏輯了！