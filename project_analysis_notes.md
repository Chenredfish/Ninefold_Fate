# 九重命運 (Ninefold Fate) — 專案分析筆記

> 此檔案由排程自動維護，每小時讀取一批程式檔案後更新。
> 最後更新：2026-04-08（Batch 6，全部完成）

---

## 進度追蹤

**✅ 所有 Batch 已完成**

| Batch | 內容 | 狀態 |
|-------|------|------|
| Batch 1 | `singletons/` (6 個 .gd) | ✅ 完成 |
| Batch 2 | `scripts/components/` + root files | ✅ 完成 |
| Batch 3 | `scripts/scenes/` (battle, menu, level_selection) | ✅ 完成 |
| Batch 4 | `scripts/skills/` + `scripts/state_machine/` | ✅ 完成 |
| Batch 5 | `scripts/ui/` (BattleBoard, DraggableTile 等) | ✅ 完成 |
| Batch 6 | `data/` JSON + `test_scenes/` | ✅ 完成 |

---

## 已知結構（來自目錄掃描）

### 專案概述
- 引擎：Godot 4.5 / GDScript
- 類型：手機策略遊戲，棋盤拼圖戰鬥
- 平台：Android（MVP）

### 資料夾結構
```
E:\Ninefold_Fate\
├── project.godot
├── main.gd / main.tscn
├── debug_state.gd
├── singletons/         ← EventBus, ResourceManager, SkillManager, StateManager, DragDropManager, DebugManager
├── scripts/
│   ├── components/     ← BaseCharacter, Hero, Enemy, SkillComponent (含 .tscn)
│   ├── scenes/         ← main_menu, level_selection, battle, battle_old
│   ├── skills/         ← BaseSkill, FireMasterySkill, FireballSkill, HealSkill
│   ├── state_machine/  ← BaseState, BaseStateMachine, BattleStateMachine, GameSceneStateMachine
│   └── ui/             ← BattleBoard, DraggableTile, DropZone, tiles/(BattleTile, LevelTile, NavigationTile)
├── data/               ← balance.json, blocks.json, decks.json, enemies.json, heroes.json, levels.json, skills.json
├── test_scenes/        ← DragDropTest, EnemyTest, LevelTileTest, StateMachineTest, SimpleTest
└── docs/               ← 10 個設計文件 .md
```

### 重要觀察
- `battle_old.gd` 存在，代表戰鬥場景已重構過一次
- 六個 Singleton 全部已建立
- 所有 JSON 資料檔已存在
- 有完整的 test_scenes 測試場景

---

## Batch 1 — singletons/ 分析

### EventBus.gd
**主要功能**：全域事件總線，採用純訊號宣告架構，是整個專案的通訊核心。所有系統間溝通均透過此單例進行，避免直接引用。

**訊號分類**（共約 40 個訊號）：
- **戰鬥**：`battle_started`、`battle_ended`、`turn_started`、`turn_ended`、`setup_battle_ui`、`player_turn_submit`
- **物件生命週期**：`hero_created`、`hero_destroyed`、`enemy_spawned`、`enemy_defeated`、`block_placed`、`block_removed`
- **能力/效果**：`ability_triggered`、`effect_applied`、`damage_dealt`、`damage_dealt_to_hero`、`healing_applied`
- **UI**：`ui_tile_selected`、`hand_updated`、`request_used_cards`、`used_cards_response`、`ui_damage_animation_requested`、`ui_unlock_end_turn_button`
- **狀態機**：`state_machine_created`、`state_changed`、`transition_failed`
- **場景切換**：`scene_transition_requested`、`scene_entered`、`scene_exited`

**重要方法**：`emit_battle_event(event_name, data)`、`emit_object_event(event_name, object_type, instance, data)` — 提供語意化包裝，內部用 `match` 分派對應訊號。

**依賴關係**：無外部依賴，被所有其他系統依賴。`BaseStateMachine` 為型別參考。

**注意事項**：
- `used_cards_response` 訊號暗示手牌有請求-回應機制，設計較特殊。
- 訊號 `setup_deck_ui(deck_id: Dictionary)` 參數名為 `deck_id` 但型別是 `Dictionary`，命名易混淆。

---

### ResourceManager.gd
**主要功能**：資源管理中心，從 JSON 載入所有遊戲資料（英雄、敵人、方塊、關卡、牌組、平衡數值），並負責動態創建角色和物件實例。

**重要方法**：
- `create_hero(hero_id)`、`create_enemy(enemy_id)`、`create_block(block_id)` — 基本創建
- `create_hero_with_overrides(hero_data)`、`create_enemy_with_overrides(enemy_data)` — 支援關卡特定數值覆蓋
- `create_hero_with_skills(hero_id)` — 建立英雄並附帶技能資料列表（存為 meta）
- `get_combo_multiplier(combo_count)` — 連擊倍率計算，11連以上公式：`2.0 + (n-11) * 0.5`
- `get_block_shape_pattern(block_data)`、`get_rotated_pattern(pattern, rotations)`、`get_flipped_pattern(...)` — 凸塊形狀/旋轉/翻轉系統

**依賴關係**：依賴 `SkillManager.get_skill_data()`、`EventBus`（創建物件後發送事件）。

**注意事項**：
- 所有視覺元素均為 `ColorRect + Label` 佔位符，**尚未整合真實美術資源**。
- `return_to_pool()` 實際只是 `queue_free()`，物件池**尚未真正實作**。
- `create_block()` 有注釋說「實際遊戲建議使用 `BattleTile.create_from_block_data()`」，此方法主要供測試使用。

---

### SkillManager.gd
**主要功能**：簡化版技能管理器，從 `res://data/skills.json` 載入技能資料，提供查詢介面。

**重要方法**：`get_skill_data(skill_id)`、`create_skill(skill_id)`（回傳 Dictionary 副本）、`get_all_skill_ids()`。

**依賴關係**：無外部 Singleton 依賴。由 `ResourceManager.create_hero_with_skills()` 呼叫。

**注意事項**：
- **不包含任何技能執行邏輯**，實際技能效果在 `scripts/skills/` 各類別中。
- `create_skill()` 回傳 Dictionary 而非 Node 實例，與 `BaseSkill.gd` 的物件導向設計可能不一致。
- 注釋混用繁/簡體中文，顯示有不同時期的修改。

---

### StateManager.gd
**主要功能**：統一管理所有狀態機實例，維護 `game_scene_state_machine`（全域場景切換）和動態創建的 `battle_state_machine`。

**重要方法**：
- `register_state_machine(name, sm)` / `unregister_state_machine(name)` — 狀態機生命週期管理
- `create_battle_state_machine()` / `destroy_battle_state_machine()` — 戰鬥狀態機動態管理
- `go_to_main_menu()` / `go_to_level_selection()` / `go_to_battle(level_id)` / `go_to_result(...)` — 場景切換快捷方法
- `submit_player_turn()` — 提交玩家回合

**初始化流程**：`_ready()` → `await process_frame` → 創建 `GameSceneStateMachine` → `transition_to("main_menu")`。

**注意事項**：
- 多處使用 `EventBus.emit_signal("event_name", ...)` 字串形式，是 GDScript 3 遺留寫法，**存在 GDScript 4 相容性風險**（應改為 `EventBus.event_name.emit(...)`）。
- `pause_all_state_machines()` 呼叫 `set_auto_process()` / `set_auto_physics_process()`，Godot 4 正確 API 應為 `set_process(false)`。

---

### DragDropManager.gd
**主要功能**：拖放系統核心，管理拖拽預覽節點、投放區域列表、高亮效果、成功/失敗動畫。

**訊號**：`tile_drag_started(tile_data, source_scene)`、`tile_drag_ended(tile_data, drop_zone, success)`、`navigation_requested(target_scene, tile_type)`

**重要方法**：
- `start_drag(tile, global_pos)` — 開始拖拽，設定半透明效果並 `create_drag_preview()`
- `update_drag(global_pos)` — 更新預覽位置並呼叫 `update_drop_zone_highlights()`
- `end_drag(global_pos)` — 判斷結果，呼叫 `perform_drop_action()` 或 `play_drop_fail_animation()`
- `register_drop_zone(zone)` / `unregister_drop_zone(zone)` — 投放區域生命週期
- `perform_drop_action(tile, zone)` — 將 tile 實例塞入 `tile_data["__tile_instance"]` 再呼叫 `zone.on_tile_dropped()`

**注意事項**：
- `play_drop_fail_animation()` 的 tween 回調呼叫 `cleanup_drag()`，但 `end_drag()` 本身也呼叫 `cleanup_drag()`，**存在雙重清理風險**。
- `create_drag_preview()` 直接加到 `get_tree().current_scene`，場景切換時若預覽未清理會殘留。

---

### DebugManager.gd
**主要功能**：開發期調試工具，`OS.is_debug_build()` 為 `true` 時才啟用，提供 F1 熱鍵切換、FPS/記憶體顯示、物件檢查器。

**重要方法**：`toggle_debug_info()`、`show_debug_info()`、`inspect_object(object)`、`test_singletons()`（呼叫 `EventBus.test_events()` 和 `ResourceManager.test_resource_creation()`）。

**注意事項**：
- `hide_debug_info()` 函式體僅為 `pass`，**尚未實作**。
- F1 熱鍵偵測條件為 `event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_F1)`，`ui_accept` 通常對應 Enter/Space，**邏輯有誤**，應直接偵測 `KEY_F1` 的 `InputEventKey`。
- `show_debug_info()` 只輸出到 `print`，**尚無實際 UI 面板**。

---

**Batch 1 總結**：六個 Singleton 架構清晰，分工明確。EventBus 達到完全解耦，StateManager 統一管理狀態機生命週期，DragDropManager 封裝完整拖放流程。主要技術債：① GDScript 3 遺留的 `emit_signal()` 字串寫法、② 視覺元素全為 ColorRect 佔位符、③ `hide_debug_info`、`return_to_pool` 等方法尚未實作。

## Batch 2 — scripts/components/ + root files 分析

### BaseCharacter.gd

**主要功能與職責：**
`Enemy` 和 `Hero` 的共同父類，繼承 `Node2D`，定義了所有角色共用的核心邏輯：HP 系統、傷害/治療、死亡、狀態效果、視覺動畫，以及 UI（血條）。

**重要屬性：**
- `@export` 屬性：`character_id`、`character_name`、`element`（預設 "neutral"）、`current_hp`、`max_hp`、`level`
- 狀態陣列：`status_effects`、`tags`
- `@onready` 視覺節點：`health_bar`（ColorRect）、`sprite`（Sprite2D）、`animation_player`

**重要函式：**
- `take_damage(damage, damage_type, source, emit_event)` — 處理受傷、呼叫 `_calculate_damage()`、更新 UI、發射 `health_changed` 信號、呼叫 `die()`
- `heal(amount, source)` — 恢復 HP，發射 `health_changed` 與 EventBus 的 `healing_applied`
- `die()` — 設置 `is_alive=false`，播放死亡動畫，透過 `EventBus.emit_object_event()` 廣播，發射 `character_died`
- `load_from_data(data)` — 從 Dictionary 設定角色資料，呼叫 `_load_visual_resources()`
- `get_character_info()` — 回傳完整的角色狀態 Dictionary
- `_calculate_damage()` — 虛擬方法，預設直接回傳原始傷害，子類可重寫
- `_create_health_bar()` — 動態建立 ColorRect 血條（60×6px，位置 -30,-60）
- `_update_ui()` — 依 HP 比例縮放血條寬度
- `add_status_effect()` / `remove_status_effect()` / `has_status_effect()` — 狀態效果管理

**信號：**
- `character_died(character: BaseCharacter)`
- `health_changed(character: BaseCharacter, old_hp: int, new_hp: int)`

**與其他系統的依賴：**
- `EventBus`：監聽 `damage_dealt` 信號（`_on_damage_received`），發射 `damage_dealt`、`healing_applied`、`emit_object_event`
- `ResourceManager`：取得 `current_language` 做本地化

**值得注意的問題：**
- `_connect_events()` 中監聽了 `EventBus.damage_dealt`，表示每個角色都訂閱了全域傷害事件，在 `_on_damage_received` 中再用 `if target == self` 過濾。場面上若有大量角色，這個模式可能造成效能問題。
- `@onready var health_bar: ColorRect = null` — 使用 `@onready` 但同時又有 `_create_health_bar()` 動態建立，兩者混用容易混淆。
- `_create_default_appearance()` 在 `Hero` 中被空實作覆寫（`pass`），意味著父類預設外觀只用於 Enemy。

---

### Hero.gd

**主要功能與職責：**
`BaseCharacter` 的子類，代表玩家英雄。覆寫了傷害計算流程以允許 `SkillComponent` 介入，並擴充了技能使用邏輯與英雄專用信號。另外還提供了向後相容的屬性別名（`hero_name`、`hero_id`）。

**重要函式：**
- `take_damage()` — **完全重寫**父類流程：先呼叫 `skill_component.modify_incoming_damage()` 修改傷害值，再手動執行傷害邏輯（未呼叫 `super.take_damage()`），存在程式碼重複問題。
- `use_skill(skill_id, target, position)` — 委派給 `SkillComponent.use_skill()`，成功後發射 `skill_used` 信號
- `_try_connect_skill_component()` — `get_node_or_null("SkillComponent")` 尋找子節點，找不到會印警告
- `load_from_data()` — 呼叫 `super.load_from_data()`，再設定 `base_attack`、`max_hp`，並呼叫 `_load_skills()`
- `_create_health_bar()` — 覆寫為 800×24px 的大型血條（位置 -400,-100），適合螢幕底部血條展示

**信號：**
- `hero_died(hero: Hero)`
- `hero_healed(hero: Hero, amount: int)`
- `skill_used(hero: Hero, skill_id: String)`

**與其他系統的依賴：**
- `BaseCharacter`（父類）
- `SkillComponent`（子節點，非必需）
- `EventBus`：額外監聽 `healing_applied` 信號

**值得注意的問題：**
- `take_damage()` 沒有呼叫 `super.take_damage()`，而是把父類邏輯複製貼上，造成維護困難——若父類傷害邏輯更新，Hero 不會自動同步。
- `_play_damage_animation()`、`_play_heal_animation()`、`_play_death_animation()` 全部是 `pass`，動畫尚未實作。
- `_create_default_appearance()` 是 `pass`，英雄若無 sprite 資源將顯示空白。

---

### Enemy.gd

**主要功能與職責：**
`BaseCharacter` 的子類，代表敵人。核心機制是「倒數攻擊」（countdown）：每輪減少 1，歸零時自動攻擊英雄並重置。覆寫 `_calculate_damage()` 實作屬性剋制系統。

**重要屬性：**
- `base_attack: int` — 攻擊力
- `max_countdown` / `current_countdown` — 攻擊倒數
- `attack_aim: Node` — 攻擊目標（需外部設定，**目前未被使用**）
- `countdown_label: Label` — 動態建立的倒數顯示標籤

**重要函式：**
- `attack()` — 攻擊時發射 `EventBus.damage_dealt_to_hero`，重置倒數
- `tick_countdown()` — 每回合減 1，歸零觸發 `attack()`
- `_calculate_damage(damage, damage_type, source)` — 實作屬性剋制表（如水系對火系 ×1.5，同系 ×0.5）
- `_on_turn_started(turn_type)` — 監聽 EventBus 的 `turn_started`，敵人回合時呼叫 `tick_countdown()`
- `_create_countdown_label()` — 建立倒數 Label，位置 -10,-80，字型 16px
- `_update_countdown_ui()` — 倒數 ≤1 變紅，≤2 變橘，其他白色

**信號：**
- `enemy_attacked(enemy: Enemy, damage: int)`
- `countdown_changed(enemy: Enemy, new_countdown: int)`

**與其他系統的依賴：**
- `BaseCharacter`（父類）
- `EventBus`：發射 `damage_dealt_to_hero(source, damage, element)`；監聽 `turn_started`（透過 `_on_turn_started` 但**連接方式不明**——`_on_turn_started` 只是一個方法，在 `_ready` 中並未看到明確連接 EventBus.turn_started 信號的程式碼，可能存在 Bug）

**值得注意的問題：**
- `attack_aim` 屬性定義了但從未在攻擊邏輯中使用——`attack()` 改用 EventBus 廣播，此屬性為死碼（dead code）。
- `_on_turn_started` 方法存在，但 `_ready()` 中未連接 `EventBus.turn_started` 信號，可能遺漏了訂閱邏輯（潛在 Bug：敵人可能永遠不會自動觸發倒數）。
- 屬性剋制表寫死在 `_calculate_damage()`，若未來要調整平衡需直接改程式碼，建議改從 `data/balance.json` 讀取。

---

### SkillComponent.gd

**主要功能與職責：**
作為 `Hero` 的子節點，管理英雄的所有技能（主動和被動）。負責技能的分類、激活、被動效果介入傷害計算，以及技能升級。

**重要函式：**
- `_categorize_skills()` — 按 `skill.skill_type == "passive"` 分類到 `passive_skills` 和 `active_skills`
- `use_skill(skill_id, target, position)` — 呼叫 `skill.activate()`
- `modify_outgoing_damage(damage_info)` / `modify_incoming_damage(damage_info)` — 讓所有被動技能介入傷害計算
- `upgrade_skill(skill_id)` — 呼叫 `skill.level_up()`
- `get_skills_info()` — 聚合所有技能的 `get_skill_info()` 供 UI 使用
- `can_use_skill(skill_id)` — 呼叫 `skill.can_activate()`

**與其他系統的依賴：**
- `EventBus`：訂閱 `battle_started`、`turn_started`、`turn_ended`（透過 `get_node_or_null("/root/EventBus")` 取得）
- `BaseSkill`（技能物件）：期待技能有 `activate()`、`on_battle_start()`、`on_turn_start()`、`on_turn_end()`、`on_damage_dealt()`、`on_damage_received()`、`level_up()`、`get_skill_info()` 等方法

**值得注意的問題：**
- `_ready()` 中用 `get_meta("skills", [])` 取得技能清單，這是非標準的初始化方式，需要由外部在場景建立前設好 Meta 資料，否則技能陣列將是空的。
- `EventBus.turn_started` 的回調簽名是 `_on_turn_started(turn_number: int)`，但 Enemy 中同名方法的簽名是 `_on_turn_started(turn_type: String)`，信號的格式不一致，需確認 EventBus 中 `turn_started` 實際發射的參數型別。
- 未設 `class_name`，不影響功能但命名一致性較差。

---

### main.gd

**主要功能與職責：**
遊戲的根場景腳本（`extends Node2D`），作為啟動入口。邏輯非常精簡：等待一幀確保 autoload 初始化後，交由 `StateManager` 的狀態機接手；若 `StateManager` 不存在，fallback 直接載入 `main_menu.tscn`。

**重要邏輯：**
- `await get_tree().process_frame` — 確保所有 autoload singleton 初始化完成
- 依賴 `StateManager.game_scene_state_machine` 自動切換場景
- 備用方案：`get_tree().change_scene_to_file("res://scripts/scenes/main_menu.tscn")`

**值得注意的問題：**
- 有一大段被 `#` 註解掉的測試場景切換按鍵說明（F1~F4），顯示開發過程中有大量手動測試流程。
- 若 `StateManager` 初始化失敗，fallback 直接呼叫 `change_scene_to_file` 而不是回報錯誤，可能使問題難以排查。

---

### debug_state.gd

**主要功能與職責：**
掛載於場景中的調試工具（`extends Control`）。按 F9 鍵印出 `StateManager` 與 `EventBus` 的詳細狀態，包括當前狀態機狀態、信號連接數量、Scene Tree 根節點子元素列表。

**重要函式：**
- `print_state_debug_info()` — 列印 StateManager（game_scene_state_machine 狀態、current_state_id、current_scene）、EventBus（`scene_transition_requested` 連接數）、Scene Tree 根子節點

**值得注意的問題：**
- 純調試用途，不影響遊戲邏輯。
- 使用 `has_method()`、`"scene_loading" in gsm` 等防禦性存取，對 API 變動有一定容忍度。
- 縮排使用空格（而 `BaseCharacter.gd` 等使用 Tab），專案縮排風格不一致。

## Batch 3 — scripts/scenes/ 分析

### main_menu.gd
**主要功能**：主選單場景，extends Control，解析度 1080×1920（手機直立屏）。完全用 GDScript 代碼動態構建 UI，無使用 .tscn 場景節點。

**UI 三層結構**：
- `create_upper_UI()`（y:0~1000）：Logo 標題「Nine Folds Fate」（96px）、副標題（48px）、遊戲介紹文字（24px，自動換行）、版本標籤「Version 0.1 Alpha」
- `create_middle_UI()`（y:800~1400）：3×3 的 `DropZone` 九宮格，只有中心格 (i=1, j=1) 連接了 `_on_start_tile_dropped`（以略微高亮顯示），其餘格接受 `["level_select", "shop", "deck", "settings"]` 類型的 tile
- `create_lower_UI()`（y:1600~1920）：`ScrollContainer + HBoxContainer` 橫向排列四個 `NavigationTile`：battle、shop、deck、settings

**依賴關係**：`NavigationTile`（靜態工廠方法）、`DropZone`（投放區域）、`StateManager`（調試用）。

**注意事項**：
- `_on_start_tile_dropped(dropped_tile)` 只有 `print`，**尚未實作**任何切換邏輯。
- shop/deck/settings 的目標場景路徑（`res://scripts/scenes/shop_scene.tscn`、`deck_scene.tscn`、`settings_scene.tscn`）**在專案中可能尚不存在**，會導致 NavigationTile 創建失敗。
- F9 熱鍵 `print_debug_info()` 正確使用 `event is InputEventKey and event.pressed and event.keycode == KEY_F9`。

---

### level_selection.gd
**主要功能**：關卡選擇場景，extends Control，實作多層關卡樹狀導航（chapter_tree）的基礎框架，目前只支援一層深度。

**核心資料結構**：
- `chapter_tree: Dictionary = {"deep0": "main_menu"}` — 記錄導航深度與各層選中的關卡
- `available_levels: Array` — 從 `ResourceManager.get_all_level_ids()` 載入
- `selected_level_id: String` — 當前選中的關卡 ID

**UI 四層結構**：
- 背景、主資訊區（章節標題 + 關卡詳情 Panel）、3×3 確認九宮格（`unified_confirm_grid`）、關卡圖塊列表（`level_tile_container`）+ 操控圖塊列表（`level_control_tile_container`）

**重要流程**：
- `load_chapter_levels()` → `ResourceManager.get_all_level_ids()` → 每個關卡建立 `LevelTile.create_from_level_id(chapter, id)` 並連接 `gui_input`
- `_on_level_tile_input()` → 選中後呼叫 `update_level_details()`，顯示敵人名稱（查 ResourceManager）
- `_on_tile_dropped()` → `match tile_data["function"]` 分派 back/main_menu/confirm，若無 function 則視為關卡 tile，從 `tile_data["__tile_instance"].level_data` 取得 `level_id`
- `start_level(level_id)` → 更新 `confirm_level_control_tile.set_navigation_data(battle.tscn, "confirm_level", {level_id, deck_data})` — 由 NavigationTile 自行處理場景切換

**注意事項**：
- `progress_bar` 已注釋，`_on_back_tile_dropped()` 和 `_on_main_menu_tile_dropped()` 皆為 `pass`，**多層關卡導航尚未實作**。
- `_on_confirm_level_tile_dropped()` 也是 `pass`，因為確認邏輯在 NavigationTile 內部處理。
- `create_confirm_grid()` 中 DropZone 的迴圈以 `(i, j)` 設位置但 x/y 相反（`x = i*200, y = j*200`），與 main_menu.gd 的 `(j*200, i*200)` 不一致，可能有佈局 bug。

---

### battle.gd（重構版，現行版本）
**主要功能**：戰鬥場景，extends Control，明確定位為「只負責 UI 顯示，不處理遊戲邏輯」，所有狀態由 BattleStateMachine 透過 EventBus 驅動。

**EventBus 連接**：`setup_battle_ui`、`setup_deck_ui`、`hand_updated`、`ui_damage_animation_requested`、`ui_unlock_end_turn_button`、`ui_load_next_enemy_wave`

**UI 組件**：
- `bottom_right_container`：「結束回合」+ 「技能」按鈕（右下錨點）
- 「暫停」按鈕（右上錨點）
- `drop_board`（BattleBoard）：棋盤，位置 (240, 750)，由 `setup_battle_ui()` 動態創建
- `tile_container` / `hand_hbox`：手牌區，位置 (40, 1420)，由 `update_hand_display()` 動態重建

**重要方法**：
- `setup_battle_ui(level_data, enemies_scenes, hero_scene)` — 創建棋盤，加入敵人/英雄節點，發送 `battle_ui_update_complete`
- `update_hand_display(current_hands)` — 清空並重建手牌，每張牌呼叫 `BattleTile.create_from_id(tile_id)`
- `_on_end_turn_pressed()` — 計算棋盤傷害（`drop_board.calculate_total_damage()`）、收集手牌中剩餘卡片、鎖按鈕、發送 `EventBus.emit_signal("turn_ended", total_damage, cards_in_ui)`
- `_on_ui_damage_animation_requested()` — 彈出傷害浮字（48px），用 `await damage_label.resized` + tween 實現彈跳縮小動畫，顏色依屬性區分（火橙、水藍、草綠等）
- `_on_ui_load_next_enemy_wave()` — 清除 group "enemy" 的子節點

**注意事項**：
- `setup_battle_ui` 的函式簽名有 `enemies_scenes: Array = []` 和 `hero_scene: Node = null`，但 `EventBus.setup_battle_ui` 定義只有 `level_data: Dictionary`，**訊號連接時參數不匹配**，額外參數會被忽略。
- `_on_skill_pressed()` 為 `pass`，**技能按鈕尚未實作**。
- 「暫停」按鈕無任何連接處理。

---

### battle_old.gd（舊版，已廢棄）
**主要功能**：重構前的戰鬥場景，在 UI 層自行管理 `current_hands` 和 `deck_data`（遊戲狀態與 UI 耦合），是重構分離的對照版本。

**與新版的主要差異**：
- `_on_end_turn_pressed()` 在 UI 層自行計算使用的卡片、補充手牌（隨機從 deck_data 抽），呼叫 `update_tile_container()`（此方法在讀取的代碼中未定義，可能在未展示部分）
- `setup_battle_ui(level_data: Dictionary)` 舊版只接受一個參數，自行讀取敵人數據並呼叫 `_setup_enemies()`
- `EventBus.emit_signal("turn_ended")` 無參數，**與 EventBus 定義的 `turn_ended(total_damage: int, cards_in_ui: Array)` 不符**

**注意事項**：此文件可作為理解重構動機的參考，但**應在確認新版穩定後移除**，避免混淆。

---

**Batch 3 總結**：三個場景（主選單、關卡選擇、戰鬥）均確立了以 NavigationTile 拖放驅動場景切換的核心互動模式。戰鬥場景新版成功實現 UI 與邏輯分離。待辦事項：① 主選單九宮格的確認邏輯未實作；② 商店/構築/設定場景尚不存在；③ 多層關卡導航框架已規劃但未實作；④ 技能和暫停按鈕功能為空。

## Batch 4 — scripts/skills/ + scripts/state_machine/ 分析

### BaseSkill.gd
**主要功能與職責：**
所有技能類的抽象基類，繼承 `RefCounted`（非 Node）。定義技能的核心資料結構、生命週期方法（進入戰鬥、回合開始/結束、傷害介入），以及主動技能的冷卻計時器機制。

**重要屬性：**
- `skill_id`、`skill_name`、`skill_type`（"active" / "passive" / "trigger"）、`skill_category`、`parameters`（Dictionary）
- `current_level`、`max_level` — 技能等級系統
- `owner: Node` — 技能持有者節點引用
- `is_on_cooldown`、`cooldown_remaining` — 冷卻狀態

**重要方法：**
- `setup_from_data(skill_data)` — 從 JSON Dictionary 初始化技能，呼叫 `_apply_level_scaling()`
- `activate(target, position)` → `execute()` — 激活流程；`execute()` 是虛擬方法，子類必須重寫
- `start_cooldown()` — 動態建立 `Timer` 子節點附加到 `owner`，計時結束後重置冷卻
- `on_damage_dealt()` / `on_damage_received()` — 被動技能介入傷害計算的鉤子方法
- `on_turn_start()` / `on_turn_end()` / `on_battle_start()` / `on_battle_end()` — 事件鉤子（預設 pass）
- `level_up()` — 升等，但有注釋「暫時跳過動態重載」，升等後 parameters **不會**重新套用等級縮放

**依賴關係：**
- 透過 `Engine.get_main_loop()` 取得 SceneTree，再用 `get_nodes_in_group("autoload_resource_manager")` 存取 ResourceManager（用於本地化名稱），是非標準的 autoload 存取方式。
- `start_cooldown()` 依賴 `owner` 在場景樹中才能運作。

**值得注意的問題：**
- `extends RefCounted` 表示技能不是 Node，但 `start_cooldown()` 的 Timer 需要掛在 `owner` 下，FireballSkill/HealSkill 的 `execute()` 中直接呼叫 `get_tree()`——RefCounted 並無此方法，**會在執行時崩潰**（必須改用 `Engine.get_main_loop() as SceneTree`）。
- `_apply_level_scaling()` 在 `level_up()` 時不被再次呼叫，技能升等實際上**不生效**。
- `_get_localized_name()` 用 group 查詢 ResourceManager，但 ResourceManager 可能並未加入該 group，應直接存取 autoload。

---

### FireMasterySkill.gd
**主要功能與職責：**
被動技能，繼承 `BaseSkill`。監聽傷害輸出，若屬性為 "fire" 則乘上 `parameters["damage_multiplier"]` 提升傷害值。

**重要方法：**
- `on_damage_dealt(damage_info)` — 讀取 `damage_info["element"]`，若為 "fire" 則放大 `damage_info["amount"]`，並設置 `was_boosted = true`
- `execute()` — 直接回傳 `true`（被動技能不需主動執行）

**依賴關係：**
- 透過 `scene_tree.get_first_node_in_group("autoload_eventbus")` 發送 `ability_triggered` 信號，與其他地方直接使用 `EventBus.xxx.emit()` 的方式**不一致**。

**值得注意的問題：**
- 如果 EventBus 沒有加入 group `"autoload_eventbus"`，則 `eb` 為 null，事件靜默失敗（無錯誤提示）。
- 放大傷害後只 `print`，未更新任何 UI 顯示傷害加成效果。

---

### FireballSkill.gd
**主要功能與職責：**
主動法術技能，繼承 `BaseSkill`。需要目標，消耗魔力，飛行 0.5 秒後對目標造成火系傷害，並建立 ColorRect 火球視覺效果。

**重要方法：**
- `can_activate()` — 額外檢查 `owner.get_current_mana() >= mana_cost`；若 owner 無此方法則直接通過（防禦性設計但邏輯寬鬆）
- `execute(target, position)` — 呼叫 `_create_fireball_effect()`，`await get_tree().create_timer(0.5).timeout`，再呼叫 `target.take_damage(damage_info)`
- `_create_fireball_effect()` — 建立橘色 ColorRect（32×32）並用 Tween 移動至目標位置

**值得注意的問題：**
- `await get_tree().create_timer(...)` — RefCounted 無 `get_tree()` 方法，**執行時必定崩潰**。
- `Hero` 未實作 `get_current_mana()` / `consume_mana()`，魔力機制完全無效（始終視為魔力足夠）。
- `take_damage(damage_info)` 傳入 Dictionary，但 `BaseCharacter.take_damage()` 簽名為 `take_damage(damage, damage_type, source, emit_event)`，**型別不匹配**，會導致執行時錯誤。

---

### HealSkill.gd
**主要功能與職責：**
主動治療技能，繼承 `BaseSkill`。無目標時預設治療自身；建立綠色 ColorRect 閃爍效果，呼叫 `target.heal(heal_amount)`。

**重要方法：**
- `execute(target, position)` — 若無目標則 `target = owner`；呼叫 `_create_heal_effect()`，再 `target.heal(heal_amount)`
- `_create_heal_effect()` — 建立綠色 ColorRect（64×64），用 Tween 三次閃爍後 `queue_free`

**依賴關係：**
- 同 FireballSkill，透過 `get_first_node_in_group("autoload_eventbus")` 發送事件。

**值得注意的問題：**
- 同樣存在 `get_tree()` 呼叫問題（不過 HealSkill 本身無 `await get_tree()`，但 `_create_heal_effect()` 呼叫 `heal_effect.create_tween()` 是在 Node2D 上呼叫，這部分無問題）。
- `target.heal(heal_amount)` 假設回傳實際治療量 `actual_healed`，但 `BaseCharacter.heal()` 的回傳值需確認是否與此一致。

---

### BaseState.gd
**主要功能與職責：**
所有狀態的抽象基類，繼承 `RefCounted`。定義狀態 ID、持有狀態機引用、附帶資料，以及六個虛擬生命週期方法。

**重要方法：**
- `enter(previous_state, data)` / `exit(next_state)` — 進入/離開狀態，父類各自 `print` 一行 log
- `update(delta)` / `physics_update(delta)` — 幀更新鉤子（預設 pass）
- `handle_input(event)` — 輸入處理鉤子（預設 pass）
- `can_transition_to(next_state_id)` — 預設回傳 `true`，子類可限制合法轉換目標
- `on_event(event_name, event_data)` — EventBus 事件整合介面（預設 pass）
- `get_state_info()` — 取得狀態 ID、類別名稱（`get_script().get_global_name()`）、資料，供調試使用

**依賴關係：**
- 持有 `state_machine: BaseStateMachine` 引用（由 `BaseStateMachine.add_state()` 設定）

**值得注意的問題：**
- 設計簡潔，作為抽象基類架構合理。子類定義在具體狀態機檔案內部（inner class），耦合度稍高但方便管理。

---

### BaseStateMachine.gd
**主要功能與職責：**
所有狀態機的通用基類，繼承 `Node`（與 BaseState/BaseSkill 不同，狀態機是 Node）。管理狀態集合（Dictionary）、當前/上一狀態、轉換邏輯、歷史記錄，以及 EventBus 整合介面。

**重要方法：**
- `add_state(state)` / `remove_state(state_id)` — 狀態生命週期
- `transition_to(state_id, data)` — 核心轉換，呼叫 `current_state.exit()` → `next_state.enter()` → 發射 `state_changed` 信號
- `go_back(data)` — 回到歷史中上一個狀態（移除最後兩筆歷史後重新轉換）
- `on_event(event_name, event_data)` — 轉發事件給 current_state
- `set_auto_process()` / `set_auto_physics_process()` — 自訂包裝，內部呼叫 Godot 4 正確 API `set_process()` / `set_physics_process()`

**值得注意的問題：**
- `_input()` 中硬編碼了 F1~F4 快捷鍵切換測試場景（DragDropTest、SimpleTest、LevelTileTest、EnemyTest）。這段代碼存在於**基類**，意味著每個繼承的狀態機實例都會搶攔這四個按鍵，應改移到 DebugManager 或只在開發版本啟用。
- `go_back()` 手動修改 `state_history` 切片後再呼叫 `transition_to()`，而 `transition_to()` 又會呼叫 `_update_history()` 添加新記錄，歷史管理邏輯存在潛在不一致。
- `_ready()` 印出 `[Global Shortcuts] F1:SimpleTest F2:StateMachine F3:DragDrop F4:Enemy`，這段訊息帶有錯誤標籤（應為 F2:DragDrop F3:LevelTile），顯示代碼已過時。

---

### BattleStateMachine.gd
**主要功能與職責：**
繼承 `BaseStateMachine`，管理完整戰鬥流程，包含六個內部狀態類：`PreparingState`、`PlayerTurnState`、`CalculatingState`、`EnemyTurnState`、`VictoryState`、`DefeatState`。此外存有戰鬥核心資料（英雄、敵人、手牌、牌組）並提供創建角色、管理手牌的工具方法。

**狀態轉換流程：**
`preparing` → `player_turn` → `calculating` → `enemy_turn` → `player_turn`（循環）→ `victory` 或 `defeat`

**重要方法：**
- `start_battle(level_data)` → `transition_to("preparing", battle_data)` — 戰鬥入口
- `end_battle(result, rewards)` — 發送 `battle_ended`，清理敵人節點，重置資料
- `check_battle_end()` — 以 `enemy.is_alive` 過濾陣列判斷是否全滅，再檢查玩家 HP；若還有波次則呼叫 `load_next_enemy_wave()`
- `load_next_enemy_wave()` — 等待 1 秒後發送 `ui_load_next_enemy_wave` 信號（僅通知 UI 清除敵人顯示，新波次敵人的建立邏輯**尚未完成**）
- `create_hero_from_data()` / `create_enemies_from_data()` — 委派給 ResourceManager 建立節點
- `setup_initial_hand()` / `refill_hand()` / `remove_used_cards()` — 手牌管理

**PreparingState 細節：**
- `_setup_ui()` 中有注釋 `# 這個是錯誤的，因為敵人不會一次全部出現`，`enemies_remaining` 被設為全部敵人數量而非第一波數量，**波次系統存在已知 Bug**。
- 等待 `battle_ui_update_complete` 的方式為 `await EventBus.battle_ui_update_complete.connect(func(): pass, CONNECT_ONE_SHOT)`，**語義奇怪**，應改為 `await EventBus.battle_ui_update_complete`。

**EnemyTurnState 細節：**
- `_on_damage_dealt_to_hero()` 有一段文字說明用三引號包裹放在代碼**之後**（`""" 監聽... """`），GDScript 中三引號字串只是運算式，不是文件注釋，位置也錯誤。

**值得注意的問題：**
- 多處仍使用 `EventBus.emit_signal("event_name", ...)` 舊式寫法（`end_battle()`、`PlayerTurnState.end_player_turn()`、`refill_hand()` 等），GDScript 4 風格應為 `EventBus.event_name.emit(...)`。
- `PlayerTurnState.end_player_turn()` 呼叫 `EventBus.emit_signal("turn_ended")` **無任何參數**，但 `_on_turn_ended(total_damage: int, cards_in_ui: Array)` 期待兩個參數 — 參數通過 UI 的 `battle.gd._on_end_turn_pressed()` 發送，而非狀態機，兩路徑邏輯混亂。
- `VictoryState._calculate_rewards()` 有 `# TODO: 根據表現計算獎勵`，目前只有固定金幣/經驗獎勵。
- `load_next_enemy_wave()` 清除 `enemies_scenes` 死亡者後傳送 UI 信號，但**沒有實際建立新波次敵人的代碼**，整個功能是半成品。

---

### GameSceneStateMachine.gd
**主要功能與職責：**
繼承 `BaseStateMachine`，管理全遊戲六個場景狀態（主選單、關卡選擇、戰鬥、結算、設定、構築）。包含場景路徑配置、`load_scene()` 方法（負責卸載舊場景並載入新場景），以及對應的六個內部狀態類。

**重要方法：**
- `change_scene_to(scene_type, data)` — 透過 `scene_state_mapping` 找到 state_id，呼叫 `transition_to()`
- `load_scene(scene_type)` — 卸載 `current_scene`（`queue_free` + `await tree_exited`），載入新 `PackedScene`，替換 `get_tree().current_scene`
- `_on_scene_transition_requested(target_scene, data)` — 從 EventBus 收到字串型場景名，反查 `scene_state_mapping` 找到 SceneType 枚舉後呼叫 `change_scene_to()`

**六個場景狀態簡述：**
- `MainMenuState` / `LevelSelectionState` / `BattleState` / `ResultState` / `SettingsState` / `DeckBuildState` — 各自在 `enter()` 中呼叫 `state_machine.load_scene(SceneType.XXX)`
- `BattleState.enter()` 載入場景後呼叫 `scene.initialize_battle(data.level_id)`，但 `battle.gd` **沒有此方法**（戰鬥初始化透過 EventBus 的 `battle_started` 驅動），此呼叫靜默失敗
- `DeckBuildState` 和 `SettingsState` 對應的場景檔（`deck_build.tscn`、`settings.tscn`、`result.tscn`）**很可能尚不存在**，切換至這些場景將導致 `load_scene()` 回傳 null

**值得注意的問題：**
- `LevelSelectionState.can_transition_to()` 限制只能到 `["main_menu", "battle"]`，若未來需要從關卡選擇直接進入設定，需修改白名單。
- `_on_scene_transition_requested()` 用 for 迴圈遍歷 `SceneType.values()` 查找場景，效率較低但場景數量少不是問題，可改用反向 Dictionary 優化。
- `BattleState.exit()` 發送 `battle_cleanup_requested` 信號，但 EventBus 中**沒有定義此信號**，訊號名稱不一致。

---

**Batch 4 總結：**
技能系統架構完整但有嚴重的執行時 Bug：`FireballSkill` / `HealSkill` 在 RefCounted 子類中呼叫 `get_tree()`，**必定在實際使用時崩潰**。魔力系統（`mana`）已預留接口但英雄類未實作，技能升等的等級縮放也未生效。狀態機架構設計優秀，`BaseStateMachine` 的 `transition_to()` 流程清晰，`BattleStateMachine` 的狀態轉換邏輯完整。主要技術債：① 大量 `emit_signal()` 舊式寫法；② 波次系統（`load_next_enemy_wave`）是半成品；③ `PlayerTurnState.end_player_turn()` 與 `battle.gd._on_end_turn_pressed()` 的回合結束邏輯路徑重複；④ `result.tscn`、`settings.tscn`、`deck_build.tscn` 等場景尚未建立。

## Batch 5 — scripts/ui/ 分析

### BattleBoard.gd

**主要功能與職責：**
3×3 棋盤式戰鬥系統的核心，繼承 `DropZone`。管理方塊的放置、多格支援、連擊傷害計算、撤銷機制，提供視覺反饋（脈動/震動動畫）。

**重要屬性：**
- `board_size: int = 3` — 棋盤大小
- `grid_cells: Array = []` — 儲存 9 個 Control 格子節點
- `placed_tiles: Dictionary = {}` — 已放置的方塊 `{Vector2i位置 → tile_data}`
- `drop_history: Array = []` — 投放紀錄供撤銷使用
- `current_tween: Tween` — 追蹤當前動畫

**重要方法：**
- `setup_battle_board()` → `create_grid_layout()` — 初始化 3×3 格子容器，每格 200×200px
- `can_place_multi_tile_at(base_pos, shape_pattern)` — 檢查多格方塊是否可放置（邊界+佔用檢查）
- `place_multi_tile_at_position()` — 將方塊佔據的所有位置添加至 `placed_tiles`
- `undo_last_tile_drop()` — 撤銷最後投放，重建 BattleTile 並放回棋盤下方
- `calculate_combo_damage()` — 統計各屬性方塊，套用公式 `1.0 + (count-1) × 0.5` 計算傷害
- `check_board_completion()` — 滿格觸發 `on_board_completed()`，3+個方塊觸發連擊傷害計算
- `start_shake_animation()` / `start_pulse_animation()` — 無效/有效高亮動畫
- `stop_all_animations()` — 正確停止 Tween 並恢復位置

**依賴關係：**
- `DropZone`（父類）
- `BattleTile.create_from_block_data()` — 撤銷時重建方塊

**值得注意的問題：**
- `handle_tile_drop()` 成功放置後呼叫 `check_board_completion()`，但該方法未發送任何信號，上層 UI（`battle.gd`）無法感知棋盤狀態變化——**遊戲邏輯與 UI 分離不夠**。
- `calculate_total_damage()` 只回傳數值，未更新任何 UI 顯示。
- 格子編號標籤（0~8）為調試用途，應在正式版本隱藏。
- `drop_history` 中的 `tile_data` 是 `duplicate()`，若原 `tile_data` 有複雜型別（如內嵌物件），深拷貝可能不完整。

---

### DraggableTile.gd

**主要功能與職責：**
所有可拖拽 UI 圖塊的抽象基類，繼承 `Control`。處理觸控/滑鼠輸入、委派給 `DragDropManager`、提供虛擬方法掛鉤、視覺效果（半透明、縮放、懸停）。

**重要屬性：**
- `tile_type: String` — 圖塊類型（"navigation"、"battle_block"、"level"）
- `tile_data: Dictionary` — 圖塊相關資料
- `is_dragging: bool`、`original_position`、`original_modulate` — 狀態追蹤

**重要方法：**
- `_on_gui_input(event)` — 統一入口，分派 `InputEventScreenTouch` / `InputEventMouseButton` / `InputEventScreenDrag` / `InputEventMouseMotion`
- `start_dragging(local_pos)` → `DragDropManager.start_drag()` — 啟動拖拽流程
- `update_dragging(local_pos)` → `DragDropManager.update_drag()` — 實時更新拖拽預覽位置
- `end_dragging(local_pos)` → `DragDropManager.end_drag()` — 結束拖拽
- `on_drag_started()` / `on_drag_ended(success)` — 虛擬方法，子類可重寫
- `set_dragging_visual(dragging)` — 半透明 50%、縮放 0.95
- `set_hover_effect(enabled)` — 亮度 120%、縮放 1.05
- `_mouse_entered()` / `_mouse_exited()` — 自動連接懸停事件

**依賴關係：**
- `DragDropManager` — 全域拖放管理器

**值得注意的問題：**
- `_on_gui_input()` 的 `InputEventMouseMotion` 判斷依賴 `Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)`，在某些邊界情況下可能漏掉移動事件（應改為 `InputEventMouseMotion` 時直接檢查 `button_mask`）。
- `setup_base_style()` 只在 `_ready()` 呼叫一次，若子類修改了樣式後無法自動還原。
- 沒有明確清理資源的 `_exit_tree()` 方法，拖拽中若節點被移除可能留下懸浮的拖拽預覽。

---

### DropZone.gd

**主要功能與職責：**
所有投放區域的抽象基類，繼承 `Control`。定義接受圖塊的規則、高亮效果管理（有效綠色脈動/無效紅色震動）、投放成功粒子效果、訊號發送。

**重要屬性：**
- `accepted_tile_types: Array[String]` — 接受的圖塊類型白名單
- `zone_type: String` — 區域類型（"battle_board"、"hand"、"confirm_grid"）
- `highlight_overlay: ColorRect` — 高亮覆蓋層（z_index=10）

**訊號：**
- `tile_dropped(tile_data)` — 投放成功
- `tile_hover_enter(tile_data)` / `tile_hover_exit()` — 懸停事件（暫未使用）

**重要方法：**
- `_ready()` → `setup_highlight_overlay()` / `setup_base_style()` / `DragDropManager.register_drop_zone()` — 初始化
- `_exit_tree()` → `DragDropManager.unregister_drop_zone()` — 清理
- `can_accept_tile(tile)` — 檢查 `tile.tile_type` 是否在 `accepted_tile_types` 中（空數組視為接受所有）
- `set_highlight_valid(enabled)` / `set_highlight_invalid(enabled)` — 更新邊框顏色、觸發脈動/震動
- `on_tile_dropped(tile_data)` → `play_drop_success_effect()` → `emit tile_dropped` → `handle_tile_drop()` — 投放流程
- `handle_tile_drop()` — 虛擬方法，子類實作具體邏輯
- `start_pulse_animation()` / `start_shake_animation()` — 無限迴圈 Tween
- `create_drop_particles()` — 創建 8 個綠色粒子星形擴散

**依賴關係：**
- `DragDropManager` — 在 `_ready()` 時註冊
- `EventBus`（可選）— 子類可能需要監聽

**值得注意的問題：**
- `set_highlight_valid/invalid()` 都呼叫 `start_pulse_animation()` / `start_shake_animation()` 但未保存 Tween 引用，若動畫進行中再次呼叫 `set_highlight_valid()` 會建立多個 Tween 導致動畫疊加。
- `stop_all_animations()` 只恢復 `highlight_overlay.modulate.a = 1.0`，但 Tween 因無引用而無法 kill，動畫繼續進行。
- `create_hint_label()` 在 `setup_base_style()` 時呼叫，但 `highlight_overlay` 尚未建立（在 `setup_highlight_overlay()` 中），可能造成字層疊問題。

---

### BattleTile.gd

**主要功能與職責：**
戰鬥方塊 UI 節點，繼承 `DraggableTile`。從 `blocks.json` 載入資料，支援多格形狀、旋轉/翻轉屬性、屬性克制計算、動態樣式（顏色/邊框按屬性）。

**重要屬性：**
- `block_id`、`element`（fire/water/grass/light/dark/neutral）、`bonus_value`、`rarity`、`shape_pattern`
- `rotation_allowed` / `flip_allowed` — 控制變形
- `background_rect: ColorRect`、`element_label`、`bonus_label` — 視覺節點

**重要工廠方法：**
- `create_from_block_data(block_id)` — 靜態工廠，查詢 ResourceManager 取得數據
- `create_from_element(element)` — 動態查找指定屬性的第一個方塊
- `create_by_criteria(criteria)` — 按多條件查詢
- `create_random()` — 隨機選擇
- `get_ids_by_element(element)` — 列舉屬性相關方塊

**重要方法：**
- `setup_from_resource_manager()` — 從 ResourceManager 載入完整資料，更新 `tile_data`
- `can_place_multi_tile_at()` — 檢查多格方塊邊界與佔用
- `is_multi_grid_tile()` → 計算 `shape_pattern` 中有效格子數量
- `create_multi_grid_content()` → `calculate_multi_grid_scale()` — 計算縮放參數，將多格方塊縮放到 160px 顯示區
- `check_element_advantage(target_element)` — 返回克制倍率（1.5/0.75/1.0）
- `get_element_color()` / `get_element_border_color()` — match 分派顏色

**依賴關係：**
- `ResourceManager.block_database` — 方塊資料庫

**值得注意的問題：**
- `create_from_block_data()` 使用 `BattleTile.new()` 而非 `BattleTile.instantiate()`，不經過 `_ready()` — **必定崩潰**。應改為 `var tile = BattleTile.new(); add_child(tile)` 或使用預製場景。
- `setup_from_resource_manager()` 呼叫 `setup_battle_tile_style()` 時檢查 `if is_inside_tree()`，但 `_ready()` 中已經呼叫一次，可能造成重複初始化。
- `create_grid_cell()` 中創建的 `Panel` 節點未加入 parent 的子列表（應為 `parent.add_child(cell_panel)`），但代碼最後確實有 `parent.add_child(cell_panel)`，邏輯正確。
- 多格方塊的視覺縮放基於 `standard_cell_size = 66.67`（棋盤 200÷3），但實際棋盤格子可能 resize，數值應參數化。

---

### LevelTile.gd

**主要功能與職責：**
關卡選擇圖塊，繼承 `DraggableTile`。從 ResourceManager 載入關卡資料，顯示解鎖狀態、難度指示、敵人屬性、星級評分。支援拖拽互動驅動場景切換。

**重要屬性：**
- `level_id`、`chapter_id` — 關卡識別
- `unlock_status: String` — "locked" / "available" / "completed"
- `difficulty: String` — "normal" / "hard" / "hell"
- `star_rating: int` — 0~3
- `level_data: Dictionary` — 從 ResourceManager 載入的完整關卡資料（包含敵人列表）

**重要方法：**
- `create_from_level_id(chapter, level_id)` — 靜態工廠，載入 ResourceManager 資料
- `can_start_drag()` — 僅 "available" 和 "completed" 可拖拽，"locked" 不可動
- `setup_self_data()` — 從 `level_data` 提取 `unlock_status`、`difficulty`、`star_rating`
- `setup_level_tile_style()` — 按解鎖狀態設定背景色：灰(鎖)/藍(可用)/綠(完成)；按難度設邊框寬度和顏色
- `create_level_content()` — 三層佈局：上(編號+難度文字)、中(狀態+敵人屬性)、下(標題+星級)
- `get_element_text()` / `get_element_color()` — 從 `enemies[0]` 查詢敵人屬性

**依賴關係：**
- `ResourceManager.get_level_data(level_id)` 和 `get_enemy_data(enemy_id)` — 資料查詢

**值得注意的問題：**
- `get_element_text()` 假設 `enemies[0]` 為首敵，但關卡資料中可能不存在或格式不統一（純字串 vs 字典），需防禦性編程。
- `create_level_content()` 中的敵人屬性查詢 `ResourceManager.get_enemy_data(enemy_id)` 每次都調用，若敵人眾多會有效能問題。
- `can_start_drag()` 方法定義但 `_on_gui_input()` 中未呼叫，拖拽檢查實際由 `DragDropManager` 的 `can_accept_tile()` 負責，此方法形同虛設。

---

### NavigationTile.gd

**主要功能與職責：**
場景導航圖塊，繼承 `DraggableTile`。根據 `function_name`（battle/shop/deck/settings/level_select）驅動場景切換，透過 EventBus 發送轉換請求至 GameSceneStateMachine。

**重要屬性：**
- `target_scene_path: String` — 目標場景檔路徑
- `function_name: String` — 功能識別（驅動轉換邏輯）
- `navigation_data: Dictionary` — 轉換參數（如關卡 ID）
- `icon_texture: Texture2D` — 功能圖標（可選）

**重要工廠方法：**
- `create_battle_tile()` / `create_shop_tile()` / `create_deck_tile()` / `create_settings_tile()` / `create_level_select_tile()` — 靜態工廠
- `create_back_tile(chapter_tree)` — 回上一頁（用於關卡選擇多層導航）
- `create_confirm_tile()` — 確認關卡並進入戰鬥

**重要方法：**
- `set_navigation_data(scene_path, func_name, data)` — 設定導航資訊
- `on_drag_ended(success)` — 拖拽成功後 `await 0.5秒` 再呼叫 `perform_scene_transition()`
- `perform_scene_transition()` — 透過 `EventBus.emit_signal("scene_transition_requested", state_name, navigation_data)` 驅動轉換
- `_get_scene_type_from_function(func_name)` — 對應至 `GameSceneStateMachine.SceneType` 列舉（但此方法返回值未使用）
- `get_state_name_from_function(func_name)` — 對應至狀態機狀態名（"level_selection"、"battle" 等）

**依賴關係：**
- `EventBus.scene_transition_requested` 訊號
- `GameSceneStateMachine` 狀態機

**值得注意的問題：**
- `_get_scene_type_from_function()` 返回 `SceneType` 列舉值（int），但呼叫者 `perform_scene_transition()` 未使用此回傳值，整個方法實際是多餘的。
- `perform_scene_transition()` 硬編碼呼叫 `EventBus.emit_signal()`（字串形式），應改為 `EventBus.scene_transition_requested.emit()`。
- `on_drag_ended()` 使用 `await get_tree().create_timer(0.5).timeout`，但拖拽中若節點被刪除會導致 await 懸掛；應檢查 `is_instance_valid(self)`。
- `set_navigation_data()` 後呼叫 `setup_navigation_style()` 會重新創建所有內容，若頻繁呼叫造成效能浪費。

---

**Batch 5 總結：** UI 層實現了完整的拖放架構（DraggableTile → DropZone + DragDropManager）、多格方塊系統（BattleBoard 支援撤銷）、場景導航驅動（NavigationTile 對接狀態機）。主要問題：① BattleTile 工廠方法使用 `new()` 會跳過 `_ready()`；② DropZone 動畫管理無法正確停止（Tween 無引用）；③ BattleBoard 無訊號反饋給上層 UI；④ NavigationTile 混合 GDScript 3/4 寫法；⑤ 多數方法存在防禦性編程漏洞（如敵人資料格式不統一）。

## Batch 6 — data/ JSON + test_scenes/ 分析

### balance.json

**主要功能**：遊戲全域平衡數值配置，統一管理所有影響傷害計算的關鍵參數。

**重要欄位：**
- `hero_base_attack: 100` — 英雄基礎攻擊力基準值
- `tile_bonus` — 各屬性方塊加成係數（fire/water/grass/light/dark 均為 2，**目前完全一致，無差異化**）
- `element_multiplier` — 屬性克制倍率：同屬 1.0、優勢 1.1、劣勢 0.9、中性 1.0（**克制差異僅 ±10%，設計上偏保守**）
- `combo_multiplier_table` — 連擊數 1~11 的倍率查找表（1.0 → 2.0，每連擊 +0.1）
- `combo_multiplier_formula: "11連之後每+1連擊，倍率+0.5"` — 超過 11 連後加速增長

**注意事項：**
- `ResourceManager.get_combo_multiplier()` 中硬編碼了此表格邏輯，但沒有從此 JSON 讀取，兩處計算**可能出現不一致**（JSON 記錄的是設計意圖，程式碼是實際生效的）。
- `tile_bonus` 所有屬性均為 2，若未來做屬性差異化需要修改，需同步更新讀取此 JSON 的邏輯。
- 缺少敵人防禦、迴避率、爆擊等進階數值定義，平衡系統仍屬初階。

---

### blocks.json

**主要功能**：所有方塊的資料定義，共 9 個方塊（B001~B005 單格 + B101~B104 多格 + B201 稀有）。

**方塊分類：**
- **單格 common（B001~B005）**：火/水/草/光/暗，`shape_pattern: [[1]]`，`bonus_value: 2`，不可旋轉/翻轉
- **多格 uncommon（B101~B104）**：L型火焰（3格）、直線水流（橫3格）、T型草葉（4格）、方形暗影（2×2，4格），`bonus_value: 6~8`，L/直線/T型可旋轉
- **稀有 rare（B201）**：十字聖光（cross，5格），`bonus_value: 10`，不可旋轉

**注意事項：**
- 所有 `icon_path` 均指向 `res://art/blocks/` 下的圖片，但藝術資源極可能尚未存在（前面分析已確認全為 ColorRect 佔位符）。
- 稀有度層次完整（common/uncommon/rare），但**沒有 epic 或 legendary 等級**，擴展空間預留。
- `rotation_allowed` 在程式碼中有 `ResourceManager.get_rotated_pattern()` 對應，但在 `BattleTile` 或 `BattleBoard` 中**沒有看到觸發旋轉的 UI**，功能存在資料但流程未串通。

---

### enemies.json

**主要功能**：敵人資料定義，目前共 2 個敵人（E001、E002）。

**敵人概覽：**
- **E001「水之史萊姆」**：element=water，HP 800，ATK 80，倒數 3（基礎型）
- **E002「火之哥布林」**：element=fire，HP 1200，ATK 100，倒數 3（進階型）

**欄位結構：**`id`、`name`（多語言）、`element`、`base_hp`、`base_attack`、`countdown`（攻擊倒數）、`sprite_path`、`icon_path`、`tags`

**注意事項：**
- 目前只有 2 個敵人，MVP 關卡只用了這 2 個，**敵人多樣性極度不足**。
- `tags` 欄位（如 `["basic", "slime"]`）定義了但在程式碼中**找不到任何使用**，為預留機制。
- 缺少特殊技能（`skills` 或 `abilities` 欄位）、掉落物、對話等進階設計。
- 缺少「地(earth)」和「風(wind)」屬性的敵人，而 `LevelTile.get_element_display_name()` 中已有這兩個屬性的顯示名稱，**顯示資料和程式支援存在超前設計**。

---

### heroes.json

**主要功能**：英雄資料定義，目前只有 1 個英雄（H001「火之勇者」）。

**欄位結構：**`id`、`name`、`element`、`base_attack: 100`、`hp: 1000`、`level`、`exp`、`growth_curve: "linear"`、`skills`（技能列表）、`passives`、`icon_path`、`sprite_path`、`animation_set`、`tags`、`unlock_level`

**技能定義：**H001 擁有技能 S001（fire mastery 被動），skills 陣列格式為 `{id, type, desc}`。

**注意事項：**
- 只有 1 個英雄，**多英雄選擇、英雄解鎖系統完全尚未建立**。
- `growth_curve: "linear"` 存在但 `ResourceManager` 中沒有根據此值計算成長的邏輯，屬性隨等級提升**尚未實作**。
- `passives` 欄位是空陣列，與 `skills` 欄位功能重疊，結構冗餘。
- `animation_set` 指向 `.tres` 資源但藝術資產尚未建立。

---

### levels.json

**主要功能**：關卡定義，共 3 個關卡（level_000~002）。

**關卡概覽：**
- **level_000「測試過關顯示」**：無敵人，`unlock_status: completed`，`star_rating: 3`，純 UI 測試用途
- **level_001「初試啼聲」**：E001×2（wave 1 + wave 2），`unlock_status: available`，標準入門關卡
- **level_002「火焰考驗」**：E002×1，`unlock_status: locked`，解鎖條件 `["level_001"]`，hard 難度，推薦戰力 1500

**欄位結構（每關）：**`id`、`name`、`description`、`difficulty`、`unlock_status`、`star_rating`、`bgm`、`background`、`rewards`、`objectives`、`turn_limit`、`special_rules`、`events`、`tutorial_steps`、`unlock_conditions`、`recommended_power`、`board`（3×3棋盤設定）、`hero_id`、`enemies`（含 wave、hp_override、atk_override、cd_override）、`win_condition`

**注意事項：**
- 欄位設計**非常完整**，已預留 `bgm`、`background`、`rewards`、`objectives`、`turn_limit`、`events`、`tutorial_steps` 等進階功能欄位，但**全部為空值**。
- `unlock_conditions` 和 `recommended_power` 已設計，但程式碼中**沒有讀取 `unlock_conditions` 來自動解鎖下一關**的邏輯。
- level_001 的敵人 enemies 陣列中有 `wave: 1` 和 `wave: 2`，表示支援波次系統，但 `BattleStateMachine.load_next_enemy_wave()` 是半成品（Batch 4 分析已指出）。
- `board.blocked` 可設定障礙格子，但 `BattleBoard` 中沒有實作此功能。

---

### skills.json

**主要功能**：技能定義，共 3 個技能（S001~S003）。

**技能概覽：**
- **S001「火焰精通」**：passive，category=damage_boost，`damage_multiplier: 1.1`，對應 `FireMasterySkill`，max_level 5
- **S002「火球術」**：active，category=spell，`base_damage: 150`、`mana_cost: 30`、`cooldown: 2`，對應 `FireballSkill`，max_level 10
- **S003「治療術」**：active，category=support，`heal_amount: 200`、`mana_cost: 25`、`cooldown: 3`，對應 `HealSkill`，max_level 8

**欄位結構：**`id`、`name`、`type`、`category`、`desc`、`parameters`、`script_class`、`icon_path`、`unlock_level`、`max_level`、`level_scaling`（每級參數陣列）

**注意事項：**
- `script_class` 欄位（如 `"FireMasterySkill"`）設計用於動態實例化，但 `SkillManager.create_skill()` 回傳的是 Dictionary 而非 Node 實例，**此欄位實際未被使用**。
- `level_scaling` 格式良好（每級數值陣列），但 Batch 4 已確認 `BaseSkill.level_up()` 不重新套用縮放，**升等完全無效**。
- 魔力系統（`mana_cost`）完整設計於資料中，但 `Hero` 類沒有 `current_mana` / `consume_mana()` 方法。

---

### SimpleTest.gd

**主要功能**：全系統 Autoload 驗證腳本，繼承 `Node2D`。逐一確認 EventBus / ResourceManager / DebugManager / SkillManager 是否正常載入，並呼叫創建測試物件。

**測試流程：**
1. `test_autoloads()` — 用 `get_node_or_null("/root/XXX")` 驗證各 Autoload
2. `create_test_objects()` — 呼叫 `resource_manager.test_balance_data()`、`create_hero("H001")`、`create_enemy("E001")`、`BattleTile.create_from_block_data("B001")`，並顯示 meta 資料

**注意事項：**
- 使用 `Enter` 重新測試、`ESC` 退出，適合快速迴歸驗證。
- `BattleTile.create_from_block_data("B001")` 在 Batch 5 已確認使用 `new()` 會跳過 `_ready()`，此測試**實際上會產生初始化不完整的物件**。
- 以 `get_meta("element")` 取值（而非直接用屬性），表示 ResourceManager 創建的物件是透過 meta 傳遞資料而非直接設定屬性，與 BaseCharacter 的 `@export` 設計**略有落差**。

---

### DragDropTest.gd

**主要功能**：拖放系統完整測試場景，繼承 `Node2D`。建立含 NavigationTile（4個）、BattleBoard、多格 BattleTile（5種形狀）的完整拖放測試環境。

**測試內容：**
- 導航圖塊（battle/shop/deck/settings）→ 主 DropZone
- 單格火焰方塊 + L型/直線/T型/十字/方形多格方塊 → BattleBoard
- 「送出方塊」按鈕：計算 `calculate_total_damage()`，清空棋盤，重新生成多格方塊

**重要流程：**
1. `_ready()` → `check_dependencies()` → `create_test_ui()` → `connect_signals()`
2. 訊號偵聽：`DragDropManager.tile_drag_started/ended`、`DropZone.tile_dropped`
3. `_on_submit_button_pressed()` — 結算傷害、清空、補充方塊（用 `get_node_or_null("BattleTile_" + id)` 防止重複創建）

**注意事項：**
- 場景路徑使用 `res://scenes/BattleScene.tscn` 等**不存在的路徑**（正確路徑應為 `res://scripts/scenes/battle.tscn`），NavigationTile 拖入後切換場景會失敗。
- 連接 `secondary_drop_zone.board_completed` 的程式碼被注釋掉，表示**棋盤完成訊號尚未接通**（呼應 Batch 5 的分析）。
- `_on_navigation_requested` 只 `print`，不執行實際場景切換，是正確的測試設計（避免測試場景中意外跳轉）。

---

**Batch 6 總結：** JSON 資料層設計嚴謹，欄位規劃超前（波次、tutorial、bgm、unlock_conditions 等），但大部分欄位目前為空值尚未發揮作用。資料量非常少（1 英雄、2 敵人、3 技能、3 關卡、9 方塊），MVP 輪廓清晰。兩個測試場景覆蓋了主要系統，可以快速驗證。

---

## 綜合結論

### 整體架構評估

「九重命運」採用 **Godot 4 + GDScript** 開發，整體架構設計相當成熟，清楚展現以下幾個優點：

**架構亮點：**
- **EventBus 解耦**：40+ 個訊號覆蓋所有系統間通訊，幾乎所有模組均可獨立替換。
- **狀態機驅動**：BaseStateMachine + BattleStateMachine + GameSceneStateMachine 形成完整的雙層狀態機（場景切換 + 戰鬥流程），架構清晰。
- **拖放系統**：DraggableTile / DropZone / DragDropManager 三層分工明確，支援觸控和滑鼠雙輸入。
- **JSON 資料驅動**：所有遊戲內容（方塊、英雄、敵人、關卡、技能）均以 JSON 管理，修改數值不需動程式碼。
- **Factory Method 模式**：BattleTile、LevelTile、NavigationTile 均有靜態工廠方法，物件創建統一且方便。

---

### 已實作 vs 尚未實作的功能

**✅ 已實作（基本可運行）：**
- 主選單 UI（九宮格 + NavigationTile 橫列）
- 關卡選擇場景（含 LevelTile 顯示解鎖狀態）
- 戰鬥場景 UI 框架（BattleBoard 3×3 + 手牌區）
- 拖放方塊到棋盤（單格 + 多格形狀）
- 連擊傷害計算（BattleBoard.calculate_total_damage）
- 敵人倒數攻擊邏輯（Enemy.tick_countdown）
- 屬性克制系統（Enemy._calculate_damage）
- 場景狀態機切換（GameSceneStateMachine）
- 戰鬥狀態機流程（preparing → player_turn → calculating → enemy_turn → victory/defeat）
- Singleton 調試工具（DebugManager / debug_state.gd）
- 完整測試場景（SimpleTest / DragDropTest）

**❌ 尚未實作或半成品：**
- **技能系統執行時崩潰**：FireballSkill/HealSkill 在 RefCounted 中呼叫 `get_tree()`
- **魔力（Mana）系統**：資料有設計，Hero 類完全未實作
- **技能升等生效**：`level_up()` 不重新套用縮放
- **波次系統**：`load_next_enemy_wave()` 清理舊敵人但不創建新一波敵人
- **關卡解鎖邏輯**：`unlock_conditions` 有設計但無程式讀取
- **獎勵系統**：`VictoryState._calculate_rewards()` 為 TODO
- **美術資源**：所有 sprite/icon 均為 ColorRect 佔位符
- **deck/shop/settings/result 場景**：尚未建立，切換到這些場景會崩潰
- **方塊旋轉/翻轉 UI**：資料有 `rotation_allowed`，但棋盤沒有觸發旋轉的 UI
- **棋盤障礙格子**：`board.blocked` 有設計，BattleBoard 未實作
- **多英雄選擇**：目前固定使用 H001
- **多層關卡導航**：chapter_tree 框架有，但多層瀏覽邏輯為 pass

---

### 潛在問題與技術債

**嚴重（執行時崩潰）：**
1. `FireballSkill.execute()` 呼叫 `get_tree().create_timer()` — RefCounted 無此方法
2. `BattleTile.create_from_block_data()` 使用 `new()` 繞過 `_ready()`，初始化不完整
3. `GameSceneStateMachine.BattleState.enter()` 呼叫 `scene.initialize_battle()` — battle.gd 無此方法

**中等（功能異常）：**
4. `StateManager` 多處使用 `emit_signal("name", ...)` GDScript 3 字串寫法
5. `DropZone` 動畫 Tween 無引用，呼叫 `stop_all_animations()` 無法真正停止
6. `DragDropManager.play_drop_fail_animation()` 與 `end_drag()` 雙重呼叫 `cleanup_drag()`
7. `BattleStateMachine.PreparingState._setup_ui()` 波次數設定已知錯誤（有注釋說明）
8. `Enemy._on_turn_started()` 方法存在但未在 `_ready()` 中連接信號

**輕微（設計債）：**
9. `Hero.take_damage()` 複製父類邏輯而非呼叫 `super.take_damage()`
10. `DebugManager.hide_debug_info()` 為空函式
11. `balance.json` 的連擊倍率表與 `ResourceManager` 硬編碼版本可能不一致
12. 縮排風格不一致（部分檔案用 Tab，部分用空格）
13. 大量調試用 `print` 語句未移除，正式版本需要清理

---

### 建議的下一步開發方向

**優先修復（阻礙 MVP 的崩潰問題）：**
1. 修復 FireballSkill/HealSkill 的 `get_tree()` 呼叫問題（改為透過 owner 或 Engine.get_main_loop()）
2. 修復 BattleTile 工廠方法，確保 `_ready()` 正常執行
3. 建立 result.tscn / settings.tscn 空場景，避免場景切換崩潰
4. 修復 Enemy 的 `turn_started` 信號連接

**核心遊戲循環完善：**
5. 完成波次系統（`load_next_enemy_wave()` 實際創建新敵人）
6. 串通回合結束流程（消除 PlayerTurnState 與 battle.gd 的重複路徑）
7. 實作關卡完成後自動解鎖下一關的邏輯

**功能擴展：**
8. 新增方塊旋轉 UI（長按或雙指旋轉手勢）
9. 實作英雄魔力系統
10. 新增更多英雄（至少 3 個不同屬性）和敵人（目標 10 個以上）
11. 接入真實美術資源（Sprite2D/TextureRect）

**程式碼品質：**
12. 全面將 `emit_signal("name")` 替換為 `.emit()` 格式
13. 統一縮排風格（建議全部改用 Tab）
14. 移除或隔離調試用 print 語句
