# Godot 單例設置指南

## 🚀 快速設置步驟

### 1. 配置 AutoLoad (必須按照順序!)

在 Godot 編輯器中：

1. 點擊 **Project** → **Project Settings**
2. 在左側選擇 **AutoLoad** 標籤
3. **按照以下順序**添加 AutoLoad 項目：

#### 第一個：EventBus
- **Path**: `res://singletons/EventBus.gd`
- **Node Name**: `EventBus`
- **Singleton**: ✅ 啟用
- 點擊 **Add** 添加

#### 第二個：ResourceManager  
- **Path**: `res://singletons/ResourceManager.gd`
- **Node Name**: `ResourceManager`
- **Singleton**: ✅ 啟用
- 點擊 **Add** 添加

#### 第三個：DebugManager
- **Path**: `res://singletons/DebugManager.gd` 
- **Node Name**: `DebugManager`
- **Singleton**: ✅ 啟用
- 點擊 **Add** 添加

### 2. 驗證設置

設置完成後，你的 AutoLoad 列表應該看起來像這樣：

```
0. EventBus          res://singletons/EventBus.gd
1. ResourceManager   res://singletons/ResourceManager.gd
2. DebugManager      res://singletons/DebugManager.gd
```

### 3. 測試單例是否正常工作

創建一個測試場景來驗證：

1. 在 Godot 中創建新場景 (Scene → New Scene)
2. 選擇 **2D Scene**
3. 將根節點重命名為 `TestScene`
4. 右鍵根節點 → **Attach Script**
5. 選擇 `res://test_scenes/TestSingletonsScene.gd`
6. 保存場景為 `TestSingletons.tscn`
7. 運行這個場景 (F6)

### 4. 預期結果

如果設置正確，你應該在輸出面板看到：

```
[EventBus] 事件系統已初始化
[ResourceManager] 資源管理系統初始化中...
[ResourceManager] 載入資源數據庫...
Database file not found: res://data/heroes.json - 創建空數據庫
Database file not found: res://data/enemies.json - 創建空數據庫  
Database file not found: res://data/blocks.json - 創建空數據庫
Database file not found: res://data/abilities.json - 創建空數據庫
[ResourceManager] 數據庫載入完成 - Heroes: 0 Enemies: 0
[ResourceManager] 預載入場景...
[ResourceManager] 場景不存在，跳過: res://scenes/Hero.tscn
[ResourceManager] 場景不存在，跳過: res://scenes/Enemy.tscn
[ResourceManager] 場景不存在，跳過: res://scenes/Block.tscn
[ResourceManager] 資源管理系統已就緒
[DebugManager] 除錯系統已啟用
=== 測試單例系統 ===
```

## ⚠️ 常見問題排除

### 問題 1: "Identifier EventBus not declared"
**原因**: AutoLoad 沒有正確設置或順序不對
**解決**: 檢查 Project Settings → AutoLoad 是否正確添加了所有單例

### 問題 2: 找不到數據文件
**原因**: 數據庫文件還沒創建 (這是正常的)
**解決**: 稍後我們會創建 `data/` 資料夾和 JSON 文件

### 問題 3: 找不到場景文件  
**原因**: 場景文件還沒創建 (這是正常的)
**解決**: 稍後我們會創建 `scenes/` 資料夾和場景文件

### 問題 4: 記憶體使用錯誤
**原因**: Godot 4.x API 變更
**解決**: 這個錯誤不會影響功能，可以忽略

## ✅ 下一步

一旦單例系統正常工作，你就可以：

1. 創建 `data/` 資料夾和 JSON 配置文件
2. 創建 `scenes/` 資料夾和物件場景
3. 開始使用 EventBus 進行事件通訊
4. 使用 ResourceManager 創建遊戲物件

## 🎯 使用範例

設置完成後，你可以在任何腳本中這樣使用：

```gdscript
# 發送事件
EventBus.battle_started.emit({"level_id": "level_001"})

# 創建物件
var hero = ResourceManager.create_hero("hero_001")
add_child(hero)

# 監聽事件
func _ready():
    EventBus.battle_started.connect(_on_battle_started)

func _on_battle_started(level_data: Dictionary):
    print("戰鬥開始: ", level_data.level_id)
```