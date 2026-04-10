# 九重運命 - 單例工具 API 說明書

## 概述

本文檔說明九重運命遊戲中四個核心單例的所有可用函數、參數和功能。這四個單例分別是：
- **EventBus** - 全局事件系統
- **ResourceManager** - 資源管理和物件創建  
- **SkillManager** - 技能數據管理 (簡化版)
- **DebugManager** - 除錯和開發工具

### 🚀 **最新更新 (2025.10.10)**
- ✅ 新增 **SkillManager** 簡化版技能系統
- ✅ 修復所有編譯錯誤和循環依賴問題
- ✅ 整合完整的測試框架 (SimpleTest)
- ✅ 支援 JSON 數據驅動的技能管理
- ✅ 簡化架構，提高系統穩定性
- ✅ 新增 `create_hero_with_skills()` 功能
- ✅ 完整的 API 文檔更新
- ✅ 清理冗餘測試文件，統一測試入口

### 📋 **變更摘要**

#### 新增功能
- **SkillManager 單例**: 完整的技能數據管理系統
- **技能與英雄整合**: 自動關聯技能數據到英雄物件
- **代理方法**: ResourceManager 提供 SkillManager 功能代理

#### 架構改進
- **簡化設計**: 移除複雜的類實例化，採用數據驅動
- **穩定性提升**: 解決所有循環依賴和編譯問題
- **測試整合**: 統一的測試框架，包含所有系統驗證

#### 文件結構
- **清理**: 移除 TestHero.gd, TestEnemy.gd 等冗餘文件
- **統一**: SimpleTest 成為唯一測試入口
- **文檔**: 完整更新 API 說明書

---

## 📡 EventBus (事件匯流排)

**文件位置:** `singletons/EventBus.gd`  
**用途:** 提供全局事件系統，實現解耦的組件間通信

### 🔔 事件信號 (Signals)

#### 戰鬥相關事件
- `battle_started(level_data: Dictionary)` - 戰鬥開始
- `battle_ended(result: String, rewards: Array)` - 戰鬥結束
- `turn_started(turn_number: int)` - 回合開始
- `turn_ended()` - 回合結束

#### 物件生命週期事件
- `hero_created(hero_instance: Node)` - 英雄創建
- `hero_destroyed(hero_id: String)` - 英雄銷毀
- `enemy_spawned(enemy_instance: Node)` - 敵人生成
- `enemy_defeated(enemy_id: String, rewards: Dictionary)` - 敵人被擊敗
- `block_placed(block_instance: Node, position: Vector2)` - 凸塊放置
- `block_removed(block_id: String)` - 凸塊移除

#### 能力與效果事件
- `ability_triggered(ability_id: String, caster: Node, target: Node)` - 技能觸發
- `effect_applied(effect_id: String, target: Node, duration: float)` - 效果套用
- `effect_expired(effect_id: String, target: Node)` - 效果到期
- `damage_dealt(source: Node, target: Node, amount: int, type: String)` - 傷害造成
- `healing_applied(source: Node, target: Node, amount: int)` - 治療套用

#### UI 事件
- `ui_tile_selected(tile_data: Dictionary)` - UI 方塊選中
- `ui_grid_updated(grid_state: Array)` - UI 格子更新
- `ui_popup_requested(popup_type: String, data: Dictionary)` - UI 彈窗請求

#### 系統事件
- `game_paused()` - 遊戲暫停
- `game_resumed()` - 遊戲恢復
- `level_completed(level_id: String, score: int)` - 關卡完成
- `resource_loaded(resource_type: String, resource_id: String)` - 資源載入

### 📤 公開函數

#### emit_battle_event()
```gdscript
func emit_battle_event(event_name: String, data: Dictionary = {})
```
**功能:** 發送戰鬥相關事件  
**輸入:**
- `event_name: String` - 事件名稱 ("started", "ended")
- `data: Dictionary` - 事件數據（可選）

**輸出:** 無  
**範例:**
```gdscript
EventBus.emit_battle_event("started", {"level_id": "level_001"})
```

#### emit_object_event()
```gdscript
func emit_object_event(event_name: String, object_type: String, instance: Node, data: Dictionary = {})
```
**功能:** 發送物件相關事件  
**輸入:**
- `event_name: String` - 事件名稱 ("created", "destroyed", "spawned", "defeated", "placed", "removed")
- `object_type: String` - 物件類型 ("hero", "enemy", "block")
- `instance: Node` - 物件實例
- `data: Dictionary` - 額外數據（可選）

**輸出:** 無  
**範例:**
```gdscript
EventBus.emit_object_event("created", "hero", hero_instance)
```

#### test_events()
```gdscript
func test_events()
```
**功能:** 測試事件系統功能  
**輸入:** 無  
**輸出:** 無  
**用途:** 開發期間驗證事件系統運作

---

## ⚔️ SkillManager (技能管理器) - 簡化版

**文件位置:** `singletons/SkillManager.gd`  
**用途:** JSON 數據驅動的技能數據管理系統 (簡化架構)

### 📊 數據庫變數

- `skills_database: Dictionary` - 技能數據庫，從 JSON 載入

### 🔧 系統函數

#### _load_skills_database()
```gdscript
func _load_skills_database()
```
**功能:** 從 `res://data/skills.json` 載入技能數據庫  
**輸入:** 無  
**輸出:** 無  
**自動調用:** 在 `_ready()` 時執行

### 📋 數據查詢函數

#### get_skill_data()
```gdscript
func get_skill_data(skill_id: String) -> Dictionary
```
**功能:** 獲取指定技能的完整數據  
**輸入:**
- `skill_id: String` - 技能 ID (例如: "S001")

**輸出:** `Dictionary` - 技能數據字典，包含名稱、類型、參數等  
**範例:**
```gdscript
var skill_data = SkillManager.get_skill_data("S001")
var skill_name = skill_data.get("name", {}).get("zh", "未知技能")
```

#### get_all_skill_ids()
```gdscript
func get_all_skill_ids() -> Array
```
**功能:** 獲取所有可用技能的 ID 列表  
**輸入:** 無  
**輸出:** `Array` - 技能 ID 字符串陣列  
**範例:**
```gdscript
var skill_list = SkillManager.get_all_skill_ids()
print("可用技能: ", skill_list)
```

#### create_skill()
```gdscript
func create_skill(skill_id: String) -> Dictionary
```
**功能:** 創建技能數據副本 (簡化版 - 僅返回數據)  
**輸入:**
- `skill_id: String` - 技能 ID

**輸出:** `Dictionary` - 技能數據的副本  
**範例:**
```gdscript
var skill = SkillManager.create_skill("S001")
if skill.size() > 0:
    print("技能創建成功: ", skill.get("name", {}))
```

### 🧪 測試函數

#### test_skill_system()
```gdscript
func test_skill_system()
```
**功能:** 測試技能系統的基本功能  
**輸入:** 無  
**輸出:** 無  
**測試內容:**
- 技能數據庫載入狀態
- 技能列表獲取
- 技能數據創建

**範例:**
```gdscript
SkillManager.test_skill_system()
```

### 💡 使用說明

#### JSON 數據格式
技能數據存儲在 `data/skills.json` 中：
```json
{
  "S001": {
    "id": "S001",
    "name": {
      "zh": "火焰精通",
      "en": "Fire Mastery"
    },
    "type": "passive",
    "category": "damage_boost",
    "parameters": {
      "element": "fire",
      "damage_multiplier": 1.1
    }
  }
}
```

#### 與英雄系統整合
```gdscript
# 通過 ResourceManager 創建帶技能的英雄
var hero = ResourceManager.create_hero_with_skills("H001")
var skills_data = hero.get_meta("skills_data", [])
```

### ⚠️ 重要說明

**簡化架構特點:**
- ✅ **數據導向:** 純粹的 JSON 數據管理
- ✅ **穩定可靠:** 無循環依賴問題
- ✅ **易於擴展:** 後續可添加更複雜功能
- ❌ **不包含:** 技能類實例化、自動效果觸發
- ❌ **不包含:** 複雜的技能組件系統

---

## 📦 ResourceManager (資源管理器)

**文件位置:** `singletons/ResourceManager.gd`  
**用途:** JSON 數據驅動的資源管理和遊戲物件創建系統

### 🗃️ 數據庫變數

- `hero_database: Dictionary` - 英雄數據庫
- `enemy_database: Dictionary` - 敵人數據庫  
- `block_database: Dictionary` - 凸塊數據庫
- `level_database: Dictionary` - 關卡數據庫
- `balance_data: Dictionary` - 平衡數據

### 🏗️ 物件創建函數

#### create_hero()
```gdscript
func create_hero(hero_id: String) -> Node2D
```
**功能:** 根據 JSON 數據創建英雄物件  
**輸入:**
- `hero_id: String` - 英雄 ID (例如: "H001")

**輸出:**
- `Node2D` - 英雄實例，失敗時返回佔位符

**範例:**
```gdscript
var hero = ResourceManager.create_hero("H001")
```

#### create_enemy()
```gdscript
func create_enemy(enemy_id: String) -> Node2D
```
**功能:** 根據 JSON 數據創建敵人物件  
**輸入:**
- `enemy_id: String` - 敵人 ID (例如: "E001")

**輸出:**
- `Node2D` - 敵人實例，失敗時返回佔位符

#### create_block()
```gdscript
func create_block(block_id: String) -> Node2D
```
**功能:** 根據 JSON 數據創建凸塊物件  
**輸入:**
- `block_id: String` - 凸塊 ID (例如: "B001")

**輸出:**
- `Node2D` - 凸塊實例，失敗時返回佔位符

#### create_hero_with_skills()
```gdscript
func create_hero_with_skills(hero_id: String) -> Node2D
```
**功能:** 創建帶有技能數據的英雄 (新增功能)  
**輸入:**
- `hero_id: String` - 英雄 ID (例如: "H001")

**輸出:**
- `Node2D` - 英雄實例，包含技能數據 meta

**技能數據存儲:**
- 技能數據存儲在 `hero.get_meta("skills_data", [])`
- 每個技能為完整的 Dictionary 數據

**範例:**
```gdscript
var hero = ResourceManager.create_hero_with_skills("H001")
var skills_data = hero.get_meta("skills_data", [])
for skill_data in skills_data:
    var skill_name = skill_data.get("name", {}).get("zh", "未知")
    print("技能: ", skill_name)
```

#### get_skill_data()
```gdscript
func get_skill_data(skill_id: String) -> Dictionary
```
**功能:** 通過 SkillManager 獲取技能數據 (代理方法)  
**輸入:**
- `skill_id: String` - 技能 ID

**輸出:** `Dictionary` - 技能數據  
**範例:**
```gdscript
var skill_data = ResourceManager.get_skill_data("S001")
```

### 📊 批量創建函數

#### create_heroes_batch()
```gdscript
func create_heroes_batch(hero_ids: Array) -> Array
```
**功能:** 批量創建多個英雄  
**輸入:**
- `hero_ids: Array` - 英雄 ID 陣列

**輸出:**
- `Array` - 英雄實例陣列

#### create_enemies_batch()
```gdscript
func create_enemies_batch(enemy_ids: Array) -> Array
```
**功能:** 批量創建多個敵人  
**輸入:**
- `enemy_ids: Array` - 敵人 ID 陣列

**輸出:**
- `Array` - 敵人實例陣列

### ⚖️ 平衡數據函數

#### get_balance_value()
```gdscript
func get_balance_value(key: String, default_value = null)
```
**功能:** 獲取平衡配置值  
**輸入:**
- `key: String` - 配置鍵名
- `default_value` - 預設值（可選）

**輸出:** 配置值或預設值

#### get_hero_base_attack()
```gdscript
func get_hero_base_attack() -> int
```
**功能:** 獲取英雄基礎攻擊力  
**輸入:** 無  
**輸出:** `int` - 基礎攻擊力值

#### get_tile_bonus()
```gdscript
func get_tile_bonus(element: String) -> int
```
**功能:** 獲取屬性方塊加成  
**輸入:**
- `element: String` - 元素類型 ("fire", "water", "grass", "light", "dark")

**輸出:** `int` - 加成值

#### get_element_multiplier()
```gdscript
func get_element_multiplier(relationship: String) -> float
```
**功能:** 獲取屬性相剋倍率  
**輸入:**
- `relationship: String` - 相剋關係 ("advantage", "disadvantage", "neutral")

**輸出:** `float` - 倍率值

#### get_combo_multiplier()
```gdscript
func get_combo_multiplier(combo_count: int) -> float
```
**功能:** 獲取連擊倍率  
**輸入:**
- `combo_count: int` - 連擊數

**輸出:** `float` - 連擊倍率

### 🗺️ 關卡數據函數

#### get_level_data()
```gdscript
func get_level_data(level_id: String) -> Dictionary
```
**功能:** 獲取關卡數據  
**輸入:**
- `level_id: String` - 關卡 ID

**輸出:** `Dictionary` - 關卡數據

#### get_all_level_ids()
```gdscript
func get_all_level_ids() -> Array
```
**功能:** 獲取所有關卡 ID  
**輸入:** 無  
**輸出:** `Array` - 關卡 ID 陣列

#### create_level_enemies()
```gdscript
func create_level_enemies(level_id: String) -> Array
```
**功能:** 創建關卡中的所有敵人  
**輸入:**
- `level_id: String` - 關卡 ID

**輸出:** `Array` - 敵人實例陣列

### 🧩 凸塊形狀函數

#### get_block_shape_pattern()
```gdscript
func get_block_shape_pattern(block_data: Dictionary) -> Array
```
**功能:** 獲取凸塊形狀模式  
**輸入:**
- `block_data: Dictionary` - 凸塊數據

**輸出:** `Array` - 二維陣列表示的形狀模式

#### get_block_dimensions()
```gdscript
func get_block_dimensions(block_data: Dictionary) -> Vector2
```
**功能:** 獲取凸塊尺寸  
**輸入:**
- `block_data: Dictionary` - 凸塊數據

**輸出:** `Vector2` - (寬度, 高度)

#### is_block_rotation_allowed()
```gdscript
func is_block_rotation_allowed(block_data: Dictionary) -> bool
```
**功能:** 檢查凸塊是否允許旋轉  
**輸入:**
- `block_data: Dictionary` - 凸塊數據

**輸出:** `bool` - 是否允許旋轉

#### is_block_flip_allowed()
```gdscript
func is_block_flip_allowed(block_data: Dictionary) -> bool
```
**功能:** 檢查凸塊是否允許翻轉  
**輸入:**
- `block_data: Dictionary` - 凸塊數據

**輸出:** `bool` - 是否允許翻轉

#### get_rotated_pattern()
```gdscript
func get_rotated_pattern(pattern: Array, rotations: int) -> Array
```
**功能:** 旋轉凸塊模式  
**輸入:**
- `pattern: Array` - 原始模式
- `rotations: int` - 旋轉次數（90度為單位）

**輸出:** `Array` - 旋轉後的模式

#### get_flipped_pattern()
```gdscript
func get_flipped_pattern(pattern: Array, flip_horizontal: bool = false, flip_vertical: bool = false) -> Array
```
**功能:** 翻轉凸塊模式  
**輸入:**
- `pattern: Array` - 原始模式
- `flip_horizontal: bool` - 是否水平翻轉
- `flip_vertical: bool` - 是否垂直翻轉

**輸出:** `Array` - 翻轉後的模式

### 🧪 測試和工具函數

#### return_to_pool()
```gdscript
func return_to_pool(object_instance: Node)
```
**功能:** 將物件歸還到對象池  
**輸入:**
- `object_instance: Node` - 要回收的物件

**輸出:** 無

#### reload_balance_data()
```gdscript
func reload_balance_data()
```
**功能:** 重新載入平衡數據（熱重載）  
**輸入:** 無  
**輸出:** 無

#### test_resource_creation()
```gdscript
func test_resource_creation()
```
**功能:** 測試資源創建功能  
**輸入:** 無  
**輸出:** 無

#### test_balance_data()
```gdscript
func test_balance_data()
```
**功能:** 測試平衡數據存取  
**輸入:** 無  
**輸出:** 無

#### test_block_shapes()
```gdscript
func test_block_shapes()
```
**功能:** 測試凸塊形狀系統  
**輸入:** 無  
**輸出:** 無

---

## 🐛 DebugManager (除錯管理器)

**文件位置:** `singletons/DebugManager.gd`  
**用途:** 提供開發期間的除錯和測試工具

### 🔧 狀態變數

- `debug_enabled: bool` - 除錯功能是否啟用（僅在 Debug 模式）
- `debug_panel_visible: bool` - 除錯面板是否顯示

### 🎮 用戶交互函數

#### toggle_debug_info()
```gdscript
func toggle_debug_info()
```
**功能:** 切換除錯資訊顯示  
**輸入:** 無  
**輸出:** 無  
**觸發方式:** F1 + Enter 鍵

### 📊 除錯資訊函數

#### show_debug_info()
```gdscript
func show_debug_info()
```
**功能:** 顯示系統除錯資訊  
**輸入:** 無  
**輸出:** 無  
**顯示內容:**
- FPS (每秒幀率)
- 記憶體使用量
- ResourceManager 狀態
- 數據庫載入狀態

#### hide_debug_info()
```gdscript
func hide_debug_info()
```
**功能:** 隱藏除錯資訊面板  
**輸入:** 無  
**輸出:** 無

### 🔍 物件檢查函數

#### log_object_creation()
```gdscript
func log_object_creation(object: Node)
```
**功能:** 記錄物件創建日誌  
**輸入:**
- `object: Node` - 被創建的物件

**輸出:** 無  
**用途:** 追蹤物件創建過程

#### log_event_emission()
```gdscript
func log_event_emission(event_name: String, data: Dictionary = {})
```
**功能:** 記錄事件發送日誌  
**輸入:**
- `event_name: String` - 事件名稱
- `data: Dictionary` - 事件數據（可選）

**輸出:** 無

#### inspect_object()
```gdscript
func inspect_object(object: Node)
```
**功能:** 深度檢查物件資訊  
**輸入:**
- `object: Node` - 要檢查的物件

**輸出:** 無  
**顯示內容:**
- 物件名稱和類型
- 位置資訊
- 子節點資訊

### 🧪 系統測試函數

#### test_singletons()
```gdscript
func test_singletons()
```
**功能:** 測試所有單例系統  
**輸入:** 無  
**輸出:** 無  
**測試內容:**
- EventBus 功能測試
- ResourceManager 功能測試

---

## 📋 使用範例

### 創建遊戲物件
```gdscript
# 創建基礎英雄
var hero = ResourceManager.create_hero("H001")
add_child(hero)
hero.position = Vector2(200, 300)

# 創建帶技能的英雄 (新功能)
var skilled_hero = ResourceManager.create_hero_with_skills("H001")
var skills_data = skilled_hero.get_meta("skills_data", [])
print("英雄擁有 ", skills_data.size(), " 個技能")

# 創建敵人並監聽事件
EventBus.enemy_spawned.connect(_on_enemy_spawned)
var enemy = ResourceManager.create_enemy("E001")
```

### 技能系統使用
```gdscript
# 獲取技能數據
var skill_data = SkillManager.get_skill_data("S001")
var skill_name = skill_data.get("name", {}).get("zh", "未知技能")
var skill_type = skill_data.get("type", "未知類型")

# 獲取所有技能列表
var all_skills = SkillManager.get_all_skill_ids()
print("遊戲中共有 ", all_skills.size(), " 個技能")

# 測試技能系統
SkillManager.test_skill_system()

# 技能數據處理範例
func process_hero_skills(hero: Node2D):
    var skills_data = hero.get_meta("skills_data", [])
    for skill_data in skills_data:
        var name = skill_data.get("name", {}).get("zh", "")
        var params = skill_data.get("parameters", {})
        print("技能: ", name, " 參數: ", params)
```

### 獲取平衡數據
```gdscript
# 獲取攻擊力
var base_attack = ResourceManager.get_hero_base_attack()

# 計算屬性加成
var fire_bonus = ResourceManager.get_tile_bonus("fire")
var combo_multiplier = ResourceManager.get_combo_multiplier(5)
```

### 除錯功能
```gdscript
# 檢查物件（僅在 Debug 模式）
DebugManager.inspect_object(my_hero)

# 記錄事件
DebugManager.log_event_emission("battle_started", {"level": "001"})
```

### 事件系統
```gdscript
# 監聽事件
EventBus.battle_started.connect(_on_battle_started)
EventBus.hero_created.connect(_on_hero_created)

# 發送事件
EventBus.emit_battle_event("started", {"level_id": "level_001"})
EventBus.emit_object_event("defeated", "enemy", enemy_instance, {"rewards": rewards_data})
```

---

## 💡 最佳實踐

### 🏗️ 架構原則
1. **簡化優先:** 採用簡化架構，避免過度設計和循環依賴
2. **數據驅動:** 所有配置通過 JSON 文件管理，便於調整和擴展
3. **漸進開發:** 從基礎功能開始，逐步添加複雜特性

### 🔧 系統使用
4. **事件系統:** 使用 EventBus 進行模組間通信，避免直接引用
5. **資源管理:** 優先使用 `create_hero_with_skills()` 創建完整英雄
6. **技能數據:** 通過 meta 數據存取技能信息，保持數據完整性
7. **除錯工具:** 開發期間運行 `SimpleTestScene.tscn` 驗證系統狀態

### ⚠️ 注意事項
8. **錯誤處理:** 所有 create 函數都有失敗保護，會返回佔位符物件
9. **效能考量:** SkillManager 僅處理數據，避免複雜的實時計算
10. **測試驗證:** 定期運行完整系統測試，確保各組件正常協作

### 🚀 擴展建議
- **技能效果:** 基於數據的計算系統，而非複雜的類實例化
- **UI 整合:** 使用技能數據創建 UI 元素和說明文字
- **戰鬥系統:** 在戰鬥邏輯中引用技能參數進行計算

---

## 🧪 測試與驗證

### 系統測試
運行 `test_scenes/SimpleTestScene.tscn` 進行完整系統測試：
- ✅ 檢查所有 AutoLoad 載入狀態
- ✅ 驗證數據庫大小和內容
- ✅ 測試物件創建功能
- ✅ 驗證技能數據整合

### 快速驗證
```gdscript
# 在任何場景中快速測試
func quick_test():
    print("SkillManager: ", SkillManager.skills_database.size(), " 技能")
    print("ResourceManager: ", ResourceManager.hero_database.size(), " 英雄")
    var hero = ResourceManager.create_hero_with_skills("H001")
    print("技能數據: ", hero.get_meta("skills_data", []).size())
```

---

**文檔版本:** 2.0 (簡化架構版)  
**最後更新:** 2025年10月10日  
**適用版本:** Godot 4.5 / GDScript  
**架構狀態:** ✅ 穩定 - 無編譯錯誤 - 完整測試覆蓋