# 九重命運 (Ninefold Fate) — 注意事項總覽

> 來源：專案自動分析筆記（Batch 1–6，全部完成）
> 最後更新：2026-04-09

---

## 分類說明

| 標籤 | 意義 |
|------|------|
| `[💥 CRASH]` | 執行時必定崩潰的問題 |
| `[🐛 BUG]` | 邏輯錯誤或功能異常（不一定崩潰） |
| `[🚧 未實作]` | 框架已建立但功能尚未填入 |
| `[⚠️ 建議]` | 程式碼品質、可維護性或設計改善 |
| `[📝 備注]` | 中性觀察、設計合理的說明、預留空間描述 |

---

## 💥 CRASH — 執行時必定崩潰

**C01** `[💥 CRASH]` **FireballSkill / HealSkill 在 RefCounted 中呼叫 get_tree()**
`BaseSkill.gd` 繼承 `RefCounted`（非 Node），`FireballSkill.execute()` 中有 `await get_tree().create_timer(0.5).timeout`，`_create_fireball_effect()` 中的 Tween 也依賴 SceneTree。RefCounted 沒有 `get_tree()` 方法，**任何技能使用都必定崩潰**。修復方式：改為 `Engine.get_main_loop() as SceneTree`，或讓技能透過 `owner` 存取場景樹。
*影響：scripts/skills/FireballSkill.gd、scripts/skills/HealSkill.gd*

**C02** `[💥 CRASH]` **BattleTile.create_from_block_data() 使用 new() 繞過 _ready()**
靜態工廠方法 `BattleTile.create_from_block_data()` 使用 `BattleTile.new()` 建立實例，但 `Control` 節點必須透過 `.instantiate()` 或加入場景樹後才會執行 `_ready()`，`@onready` 變數均為 null，視覺節點不存在。**產生初始化不完整的物件，觸摸相關操作必定崩潰**。
*影響：scripts/ui/tiles/BattleTile.gd*

**C03** `[💥 CRASH]` **GameSceneStateMachine.BattleState.enter() 呼叫不存在的方法**
`BattleState.enter()` 載入場景後呼叫 `scene.initialize_battle(data.level_id)`，但 `battle.gd` 中**沒有此方法**（戰鬥初始化透過 EventBus 的 `battle_started` 驅動）。此呼叫靜默失敗但可能在某些設定下導致崩潰。
*影響：scripts/state_machine/GameSceneStateMachine.gd*

**C04** `[💥 CRASH]` **deck / settings / result 場景檔尚不存在**
`GameSceneStateMachine` 的 `DeckBuildState`、`SettingsState`、`ResultState` 在 `enter()` 中呼叫 `load_scene()`，但 `deck_build.tscn`、`settings.tscn`、`result.tscn` 很可能尚未建立，`load_scene()` 會回傳 null，切換至這些場景**必定崩潰**。
*影響：scripts/state_machine/GameSceneStateMachine.gd*

**C05** `[💥 CRASH]` **FireballSkill.take_damage() 型別不匹配**
`FireballSkill.execute()` 呼叫 `target.take_damage(damage_info)`，傳入的是 Dictionary，但 `BaseCharacter.take_damage()` 的簽名為 `take_damage(damage: int, damage_type: String, source, emit_event: bool)`，**型別不匹配，執行時錯誤**。
*影響：scripts/skills/FireballSkill.gd*

---

## 🐛 BUG — 功能異常或邏輯錯誤

**B01** `[🐛 BUG]` **GDScript 3 遺留寫法：emit_signal() 字串形式**
`StateManager.gd` 多處使用 `EventBus.emit_signal("event_name", ...)` 字串形式，`BattleStateMachine.gd` 也有類似情況（`end_battle()`、`PlayerTurnState.end_player_turn()`、`refill_hand()` 等）。Godot 4 正確寫法應為 `EventBus.event_name.emit(...)`，字串形式在 GDScript 4 中有相容性風險。
*影響：singletons/StateManager.gd、scripts/state_machine/BattleStateMachine.gd*

**B02** `[🐛 BUG]` **StateManager.pause_all_state_machines() 使用錯誤的 Godot 4 API**
呼叫 `set_auto_process()` 和 `set_auto_physics_process()`，Godot 4 的正確 API 應為 `set_process(false)` 和 `set_physics_process(false)`。此方法可能完全無效。
*影響：singletons/StateManager.gd*

**B03** `[🐛 BUG]` **DebugManager F1 熱鍵偵測邏輯有誤**
偵測條件為 `event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_F1)`，`ui_accept` 通常對應 Enter/Space 而非 F1，邏輯上需要同時按 Enter 才能切換 debug。應直接偵測 `event is InputEventKey and event.keycode == KEY_F1 and event.pressed`。
*影響：singletons/DebugManager.gd*

**B04** `[🐛 BUG]` **DragDropManager 雙重清理風險**
`play_drop_fail_animation()` 的 tween 回調呼叫 `cleanup_drag()`，但 `end_drag()` 本身也呼叫 `cleanup_drag()`，存在**雙重清理**風險，可能造成 null 存取或重複釋放節點。
*影響：singletons/DragDropManager.gd*

**B05** `[🐛 BUG]` **DragDropManager.create_drag_preview() 場景切換後殘留**
`create_drag_preview()` 直接加到 `get_tree().current_scene`，若場景在拖拽過程中切換，預覽節點將**殘留在已切換的場景中**，造成視覺污染或記憶體洩漏。
*影響：singletons/DragDropManager.gd*

**B06** `[🐛 BUG]` **Enemy._on_turn_started() 未連接訊號**
`_on_turn_started(turn_type)` 方法存在，但 `_ready()` 中並未看到明確連接 `EventBus.turn_started` 訊號的程式碼，**敵人可能永遠不會自動觸發倒數攻擊**（turn_started 發射時沒有接收方）。
*影響：scripts/components/Enemy.gd*

**B07** `[🐛 BUG]` **DropZone 多 Tween 動畫疊加**
`set_highlight_valid()` / `set_highlight_invalid()` 各自呼叫 `start_pulse_animation()` / `start_shake_animation()` 但未保存 Tween 引用，若動畫進行中再次呼叫，會**建立多個 Tween 造成動畫疊加混亂**。
*影響：scripts/ui/DropZone.gd*

**B08** `[🐛 BUG]` **DropZone.stop_all_animations() 無法真正停止動畫**
因 Tween 無引用，`stop_all_animations()` 只能恢復 `highlight_overlay.modulate.a = 1.0`，但 Tween 繼續在背景運行，**動畫實際上無法被停止**。
*影響：scripts/ui/DropZone.gd*

**B09** `[🐛 BUG]` **DropZone.create_hint_label() 在 highlight_overlay 建立前呼叫**
`setup_base_style()` 中呼叫 `create_hint_label()`，但 `highlight_overlay` 在稍後的 `setup_highlight_overlay()` 才建立，可能造成**提示標籤疊加順序錯誤或 null 存取**。
*影響：scripts/ui/DropZone.gd*

**B10** `[🐛 BUG]` **BattleStateMachine.PreparingState 波次數設定已知錯誤**
`_setup_ui()` 中 `enemies_remaining` 被設為**全部敵人數量**而非第一波數量，程式碼中有注釋「`# 這個是錯誤的，因為敵人不會一次全部出現`」，波次系統存在已知 Bug。
*影響：scripts/state_machine/BattleStateMachine.gd (PreparingState)*

**B11** `[🐛 BUG]` **PlayerTurnState.end_player_turn() 與 battle.gd 回合結束路徑衝突**
`PlayerTurnState.end_player_turn()` 呼叫 `EventBus.emit_signal("turn_ended")` 且**無任何參數**，但 `_on_turn_ended(total_damage: int, cards_in_ui: Array)` 期待兩個參數；另一條路徑由 `battle.gd._on_end_turn_pressed()` 發送含參數的 `turn_ended`。**兩路徑邏輯重複且參數不一致**。
*影響：scripts/state_machine/BattleStateMachine.gd、scripts/scenes/battle.gd*

**B12** `[🐛 BUG]` **GameSceneStateMachine.BattleState.exit() 發送不存在的訊號**
`BattleState.exit()` 發送 `battle_cleanup_requested` 訊號，但 `EventBus.gd` 中**沒有定義此訊號**，訊號名稱不一致，發送無效。
*影響：scripts/state_machine/GameSceneStateMachine.gd*

**B13** `[🐛 BUG]` **DraggableTile MouseMotion 事件可能遺漏**
`_on_gui_input()` 中 `InputEventMouseMotion` 判斷依賴 `Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)`，在某些邊界情況下（如快速移動或 GUI 焦點切換）可能**漏掉移動事件**。應改為直接檢查 `InputEventMouseMotion.button_mask`。
*影響：scripts/ui/DraggableTile.gd*

**B14** `[🐛 BUG]` **BattleBoard.drop_history 深拷貝可能不完整**
`drop_history` 中的 `tile_data` 使用 `duplicate()` 備份，若 `tile_data` 包含複雜型別（如內嵌物件或節點引用），`duplicate()` 的**淺拷貝可能造成撤銷時資料不一致**。
*影響：scripts/ui/BattleBoard.gd*

**B15** `[🐛 BUG]` **LevelTile.get_element_text() 防禦性不足**
假設 `enemies[0]` 為首敵且資料格式統一（純字串 vs 字典），但若關卡資料格式不統一或敵人陣列為空，會造成**執行時錯誤**。
*影響：scripts/ui/tiles/LevelTile.gd*

**B16** `[🐛 BUG]` **FireMasterySkill 存取 EventBus 靜默失敗**
透過 `scene_tree.get_first_node_in_group("autoload_eventbus")` 取得 EventBus，若 EventBus 未加入此 group，`eb` 為 null，事件發送**靜默失敗，無任何錯誤訊息**。
*影響：scripts/skills/FireMasterySkill.gd*

**B17** `[🐛 BUG]` **level_selection.gd DropZone 座標 x/y 相反**
`create_confirm_grid()` 中迴圈以 `(i, j)` 設位置，但 `x = i*200, y = j*200`（行→x、列→y），與 `main_menu.gd` 的 `(j*200, i*200)` 方向**不一致**，可能導致九宮格確認區佈局異常。
*影響：scripts/scenes/level_selection.gd*

**B18** `[🐛 BUG]` **battle.gd setup_battle_ui 訊號參數不匹配**
`EventBus.setup_battle_ui` 訊號定義只有 `level_data: Dictionary` 一個參數，但 `battle.gd` 的連接函式簽名為 `(level_data, enemies_scenes, hero_scene)`，**額外的 enemies_scenes 和 hero_scene 始終為預設值**，無法由訊號傳入。
*影響：scripts/scenes/battle.gd、singletons/EventBus.gd*

**B19** `[🐛 BUG]` **Hero.take_damage() 複製父類邏輯不呼叫 super**
`Hero.take_damage()` 完全重寫父類流程（先呼叫 `skill_component.modify_incoming_damage()`，再手動執行傷害邏輯），**未呼叫 `super.take_damage()`**，若父類傷害邏輯更新，Hero 不會自動同步，造成維護困難。
*影響：scripts/components/Hero.gd*

**B20** `[🐛 BUG]` **NavigationTile.on_drag_ended() await 懸掛風險**
使用 `await get_tree().create_timer(0.5).timeout` 延遲場景切換，但若拖拽過程中節點被移除，**await 將永久懸掛**。應在 await 後加入 `if not is_instance_valid(self): return`。
*影響：scripts/ui/tiles/NavigationTile.gd*

**B21** `[🐛 BUG]` **BaseStateMachine.go_back() 歷史紀錄可能不一致**
`go_back()` 手動修改 `state_history` 切片後再呼叫 `transition_to()`，而 `transition_to()` 又呼叫 `_update_history()` 添加新記錄，**歷史管理邏輯存在潛在不一致**，連續 go_back() 可能產生預期外的狀態序列。
*影響：scripts/state_machine/BaseStateMachine.gd*

**B22** `[🐛 BUG]` **SkillComponent 與 Enemy 的 turn_started 回調簽名不一致**
`SkillComponent._on_turn_started()` 簽名為 `(turn_number: int)`，但 `Enemy._on_turn_started()` 簽名為 `(turn_type: String)`，需確認 `EventBus.turn_started` 實際發射的參數型別，其中一個連接**可能因參數型別不匹配而無法正常呼叫**。
*影響：scripts/components/SkillComponent.gd、scripts/components/Enemy.gd*

---

## 🚧 未實作 — 框架已建立但功能尚未填入

**U01** `[🚧 未實作]` **ResourceManager.return_to_pool() 是假物件池**
`return_to_pool()` 的實際實作只是 `queue_free()`，**物件池功能完全未實作**，每次「回收」都是直接銷毀物件。
*影響：singletons/ResourceManager.gd*

**U02** `[🚧 未實作]` **DebugManager.hide_debug_info() 為空**
函式體僅為 `pass`，debug UI 無法被隱藏。
*影響：singletons/DebugManager.gd*

**U03** `[🚧 未實作]` **DebugManager.show_debug_info() 只有 print**
方法只輸出到 `print`，**沒有實際的 UI 面板**（FPS、記憶體、物件檢查器均無顯示）。
*影響：singletons/DebugManager.gd*

**U04** `[🚧 未實作]` **Hero 動畫全部為 pass**
`_play_damage_animation()`、`_play_heal_animation()`、`_play_death_animation()` 三個方法**全部是 pass**，英雄無任何戰鬥動畫反饋。
*影響：scripts/components/Hero.gd*

**U05** `[🚧 未實作]` **main_menu.gd 開始遊戲拖放未實作**
`_on_start_tile_dropped(dropped_tile)` 只有 `print`，**未執行任何場景切換邏輯**。
*影響：scripts/scenes/main_menu.gd*

**U06** `[🚧 未實作]` **level_selection.gd 返回導航為 pass**
`_on_back_tile_dropped()` 和 `_on_main_menu_tile_dropped()` 皆為 `pass`，**多層關卡導航尚未實作**。
*影響：scripts/scenes/level_selection.gd*

**U07** `[🚧 未實作]` **battle.gd 技能按鈕為 pass**
`_on_skill_pressed()` 為 `pass`，**技能按鈕功能尚未實作**。
*影響：scripts/scenes/battle.gd*

**U08** `[🚧 未實作]` **battle.gd 暫停按鈕無連接**
「暫停」按鈕已放入場景但**無任何連接處理**，點擊無效果。
*影響：scripts/scenes/battle.gd*

**U09** `[🚧 未實作]` **VictoryState._calculate_rewards() 為 TODO**
`VictoryState._calculate_rewards()` 有注釋 `# TODO: 根據表現計算獎勵`，**目前只有固定金幣/經驗值**，無任何基於表現的動態計算。
*影響：scripts/state_machine/BattleStateMachine.gd (VictoryState)*

**U10** `[🚧 未實作]` **load_next_enemy_wave() 不創建新敵人**
`BattleStateMachine.load_next_enemy_wave()` 等待 1 秒後清除死亡敵人並發送 UI 清理訊號，但**完全沒有實際建立新波次敵人的程式碼**，波次系統是半成品。
*影響：scripts/state_machine/BattleStateMachine.gd*

**U11** `[🚧 未實作]` **FireMasterySkill 傷害加成無 UI 反饋**
被動技能觸發後只 `print`，**沒有任何 UI 顯示**（如傷害數字變色、特效提示等）。
*影響：scripts/skills/FireMasterySkill.gd*

**U12** `[🚧 未實作]` **技能升等無實際效果**
`BaseSkill.level_up()` 中有注釋「暫時跳過動態重載」，升等後 `_apply_level_scaling()` **不會被重新呼叫**，`parameters` 中的數值不更新，升等完全無效。
*影響：scripts/skills/BaseSkill.gd*

**U13** `[🚧 未實作]` **Hero 魔力（Mana）系統未實作**
`FireballSkill.can_activate()` 檢查 `owner.get_current_mana()`，但 `Hero` 類**完全沒有 `current_mana`、`get_current_mana()`、`consume_mana()` 等方法**，魔力機制完全無效（始終視為魔力足夠）。
*影響：scripts/components/Hero.gd、scripts/skills/FireballSkill.gd*

**U14** `[🚧 未實作]` **DragDropTest 棋盤完成訊號未接通**
`DragDropTest.gd` 中連接 `secondary_drop_zone.board_completed` 的程式碼被**注釋掉**，棋盤滿格訊號尚未接通，與 Batch 5 分析中指出 BattleBoard 無訊號反饋的問題相呼應。
*影響：test_scenes/DragDropTest.gd*

**U15** `[🚧 未實作]` **方塊旋轉/翻轉功能無 UI 觸發**
`blocks.json` 中有 `rotation_allowed`/`flip_allowed` 欄位，`ResourceManager.get_rotated_pattern()` 和 `get_flipped_pattern()` 方法存在，但在 `BattleTile` 或 `BattleBoard` 中**找不到任何觸發旋轉/翻轉的 UI 操作**，資料和邏輯已備但流程未串通。
*影響：scripts/ui/tiles/BattleTile.gd、scripts/ui/BattleBoard.gd*

**U16** `[🚧 未實作]` **棋盤障礙格子（board.blocked）未實作**
`levels.json` 中 `board.blocked` 欄位可設定障礙格子，但 `BattleBoard` 中**完全沒有實作此功能**，障礙格子設定目前無效。
*影響：scripts/ui/BattleBoard.gd*

**U17** `[🚧 未實作]` **關卡解鎖條件（unlock_conditions）未讀取**
`levels.json` 的 `unlock_conditions` 欄位已設計（如 level_002 需完成 level_001），但**程式碼中沒有讀取此欄位並自動解鎖下一關**的邏輯，關卡解鎖狀態完全靠 JSON 中的初始值。
*影響：scripts/state_machine/BattleStateMachine.gd、singletons/ResourceManager.gd*

**U18** `[🚧 未實作]` **敵人進階欄位尚未設計**
`enemies.json` 目前每個敵人缺少特殊技能（`skills`/`abilities`）、掉落物（`drops`）、對話（`dialogue`）等進階設計欄位，敵人多樣性極度不足（只有 2 個）。
*影響：data/enemies.json*

**U19** `[🚧 未實作]` **所有視覺元素均為 ColorRect 佔位符**
所有 sprite/icon 均為 `ColorRect + Label` 佔位符，**尚未整合真實美術資源**。Hero 的 `_create_default_appearance()` 直接 `pass`，英雄若無 sprite 資源將顯示空白。
*影響：scripts/components/BaseCharacter.gd、scripts/components/Hero.gd*

---

## ⚠️ 建議 — 設計改善與技術債

**S01** `[⚠️ 建議]` **EventBus: setup_deck_ui 參數命名易混淆**
訊號 `setup_deck_ui(deck_id: Dictionary)` 參數名為 `deck_id` 但型別是 `Dictionary`，`id` 一般暗示是字串識別碼，應改名為 `deck_data: Dictionary` 以符合型別語意。
*影響：singletons/EventBus.gd*

**S02** `[⚠️ 建議]` **SkillManager.create_skill() 回傳 Dictionary 而非物件**
`create_skill()` 回傳 Dictionary 副本，與 `BaseSkill.gd` 的物件導向設計不一致；若外部呼叫者期待 Node 或 RefCounted 實例，可能造成混淆。應考慮統一介面。
*影響：singletons/SkillManager.gd*

**S03** `[⚠️ 建議]` **SkillManager 注釋混用繁/簡體中文**
程式碼注釋存在繁體和簡體中文混用的情況，顯示有不同時期的修改，建議統一。
*影響：singletons/SkillManager.gd*

**S04** `[⚠️ 建議]` **BaseCharacter 全域 damage_dealt 訂閱效能風險**
`_connect_events()` 中每個角色都訂閱了全域 `EventBus.damage_dealt` 訊號，在 `_on_damage_received` 中以 `if target == self` 過濾。**若場面上有大量角色，此模式將造成 O(n) 的廣播效能問題**。可改為由 BattleStateMachine 統一分派，或直接對目標角色呼叫 `take_damage()`。
*影響：scripts/components/BaseCharacter.gd*

**S05** `[⚠️ 建議]` **BaseCharacter health_bar 初始化方式混用**
`@onready var health_bar: ColorRect = null` 與 `_create_health_bar()` 動態建立**同時存在**，兩種方式混用易混淆，應擇一：保留 `@onready`（從場景樹取得）或保留動態建立，去掉另一個。
*影響：scripts/components/BaseCharacter.gd*

**S06** `[⚠️ 建議]` **Enemy 屬性克制表應從 balance.json 讀取**
`_calculate_damage()` 中的屬性剋制倍率（如水系對火系 ×1.5、同系 ×0.5）**寫死在程式碼中**，若未來要調整平衡需直接改程式碼。建議改從 `data/balance.json` 讀取，統一由資料層管理。
*影響：scripts/components/Enemy.gd*

**S07** `[⚠️ 建議]` **Enemy.attack_aim 為死碼**
`attack_aim: Node` 屬性已定義且說明為攻擊目標，但 `attack()` 方法改用 `EventBus.damage_dealt_to_hero` 廣播，`attack_aim` **從未被使用**，屬於死碼（dead code），應移除或補上使用邏輯。
*影響：scripts/components/Enemy.gd*

**S08** `[⚠️ 建議]` **SkillComponent 未設定 class_name**
`SkillComponent.gd` 沒有設定 `class_name`，相較於其他有命名的類別，命名一致性較差，建議加上。
*影響：scripts/components/SkillComponent.gd*

**S09** `[⚠️ 建議]` **main.gd 遺留大量注釋測試代碼**
有一大段被 `#` 注釋掉的 F1~F4 測試場景切換說明，顯示開發過程中有大量手動測試流程，建議清理或移至 DebugManager。
*影響：main.gd*

**S10** `[⚠️ 建議]` **main.gd StateManager 初始化失敗時靜默 Fallback**
若 `StateManager` 初始化失敗，備用方案直接呼叫 `change_scene_to_file()` 而不印出任何警告，**使問題難以排查**。建議至少 `push_error()` 說明 StateManager 未找到。
*影響：main.gd*

**S11** `[⚠️ 建議]` **debug_state.gd 縮排風格不一致**
`debug_state.gd` 使用空格縮排，而 `BaseCharacter.gd` 等主要檔案使用 Tab，**專案縮排風格不一致**（建議統一使用 Tab，符合 GDScript 官方風格）。
*影響：debug_state.gd*

**S12** `[⚠️ 建議]` **BaseStateMachine 基類硬編碼測試場景快捷鍵**
`_input()` 中硬編碼了 F1~F4 快捷鍵切換測試場景，此邏輯存在**基類**中，意味著每個繼承的狀態機實例都會搶攔這四個按鍵，應移至 DebugManager 或只在開發版本啟用。
*影響：scripts/state_machine/BaseStateMachine.gd*

**S13** `[⚠️ 建議]` **BaseStateMachine 啟動訊息標籤錯誤**
`_ready()` 印出 `[Global Shortcuts] F1:SimpleTest F2:StateMachine F3:DragDrop F4:Enemy`，但正確應為 F2:DragDrop / F3:LevelTile，**標籤已過時，顯示代碼未同步更新**。
*影響：scripts/state_machine/BaseStateMachine.gd*

**S14** `[⚠️ 建議]` **BattleStateMachine 等待訊號的錯誤寫法**
`PreparingState._setup_ui()` 中等待方式為 `await EventBus.battle_ui_update_complete.connect(func(): pass, CONNECT_ONE_SHOT)`，語義錯誤（`connect` 回傳 Error，await 一個 Error 無意義）。正確寫法應為 `await EventBus.battle_ui_update_complete`。
*影響：scripts/state_machine/BattleStateMachine.gd (PreparingState)*

**S15** `[⚠️ 建議]` **BattleStateMachine 三引號字串誤用為注釋**
`EnemyTurnState._on_damage_dealt_to_hero()` 後面有三引號包裹的說明文字，GDScript 中三引號字串只是運算式而非文件注釋，位置也在程式碼之後，**應改為 `##` 文件注釋或普通 `#` 注釋**。
*影響：scripts/state_machine/BattleStateMachine.gd (EnemyTurnState)*

**S16** `[⚠️ 建議]` **GameSceneStateMachine LevelSelectionState 白名單過於嚴格**
`LevelSelectionState.can_transition_to()` 限制只能轉換到 `["main_menu", "battle"]`，若未來需要從關卡選擇直接進入設定或其他頁面，需修改白名單，**設計不夠彈性**。
*影響：scripts/state_machine/GameSceneStateMachine.gd (LevelSelectionState)*

**S17** `[⚠️ 建議]` **BaseSkill._get_localized_name() 應直接存取 autoload**
使用 `Engine.get_main_loop().get_nodes_in_group("autoload_resource_manager")` 存取 ResourceManager，但 ResourceManager 可能並未加入此 group，應直接以全域名稱 `ResourceManager` 存取 autoload。
*影響：scripts/skills/BaseSkill.gd*

**S18** `[⚠️ 建議]` **FireMasterySkill 存取 EventBus 方式不一致**
透過 `scene_tree.get_first_node_in_group("autoload_eventbus")` 取得 EventBus，與其他地方直接使用 `EventBus.xxx.emit()` 的方式**不一致**，建議統一使用 autoload 直接存取。
*影響：scripts/skills/FireMasterySkill.gd*

**S19** `[⚠️ 建議]` **HealSkill 假設 heal() 的回傳值格式**
`target.heal(heal_amount)` 假設回傳 `actual_healed`（實際治療量），但 `BaseCharacter.heal()` 的回傳值需確認是否與此一致，存在潛在的型別假設。
*影響：scripts/skills/HealSkill.gd*

**S20** `[⚠️ 建議]` **BattleBoard 缺少棋盤狀態訊號**
`check_board_completion()` 達到滿格或連擊條件時**未發送任何訊號**，上層 `battle.gd` 無法感知棋盤狀態變化，UI 與邏輯分離做得不夠徹底，建議補充 `board_state_changed` 等訊號。
*影響：scripts/ui/BattleBoard.gd*

**S21** `[⚠️ 建議]` **BattleBoard 格子編號標籤（0~8）為調試殘留**
`create_grid_layout()` 在每格加入 0~8 的數字標籤，此為調試用途，**應在正式版本中隱藏或移除**。
*影響：scripts/ui/BattleBoard.gd*

**S22** `[⚠️ 建議]` **DraggableTile.setup_base_style() 只呼叫一次**
`setup_base_style()` 只在 `_ready()` 時呼叫一次，若子類修改了樣式後（如高亮選中），**無法自動還原**基本樣式，建議提供重置方法。
*影響：scripts/ui/DraggableTile.gd*

**S23** `[⚠️ 建議]` **DraggableTile 缺少 _exit_tree() 清理**
沒有 `_exit_tree()` 覆寫，**拖拽進行中若節點被移除**，可能在場景中留下懸浮的拖拽預覽節點。建議在 `_exit_tree()` 中通知 DragDropManager 取消拖拽。
*影響：scripts/ui/DraggableTile.gd*

**S24** `[⚠️ 建議]` **BattleTile.setup_from_resource_manager() 可能重複初始化**
工廠方法創建後會設定資料，`_ready()` 中已呼叫一次初始化，`setup_from_resource_manager()` 再次呼叫時雖有 `if is_inside_tree()` 檢查，**仍可能造成重複初始化**，建議加入初始化狀態標記。
*影響：scripts/ui/tiles/BattleTile.gd*

**S25** `[⚠️ 建議]` **BattleTile 多格縮放基準值硬編碼**
多格方塊的視覺縮放基於 `standard_cell_size = 66.67`（棋盤 200÷3），但實際棋盤格子可能因螢幕 resize 而改變，**此數值應參數化**，由棋盤動態傳入。
*影響：scripts/ui/tiles/BattleTile.gd*

**S26** `[⚠️ 建議]` **LevelTile 每次查詢敵人資料效能問題**
`create_level_content()` 中的敵人屬性查詢 `ResourceManager.get_enemy_data(enemy_id)` **每次都重複呼叫**，若關卡敵人眾多且此方法頻繁觸發，會有效能問題，建議快取查詢結果。
*影響：scripts/ui/tiles/LevelTile.gd*

**S27** `[⚠️ 建議]` **LevelTile.can_start_drag() 定義但從未呼叫**
`can_start_drag()` 方法定義了「locked 狀態不可拖拽」邏輯，但 `_on_gui_input()` 中並未呼叫此方法，拖拽檢查實際由 `DragDropManager.can_accept_tile()` 負責，`can_start_drag()` **形同虛設**（dead code）。
*影響：scripts/ui/tiles/LevelTile.gd*

**S28** `[⚠️ 建議]` **NavigationTile._get_scene_type_from_function() 回傳值未使用**
`_get_scene_type_from_function(func_name)` 回傳 `SceneType` 列舉值，但呼叫者 `perform_scene_transition()` **未使用此回傳值**，整個方法實際上是多餘的，建議移除或整合。
*影響：scripts/ui/tiles/NavigationTile.gd*

**S29** `[⚠️ 建議]` **NavigationTile.set_navigation_data() 每次呼叫都重建所有內容**
呼叫後觸發 `setup_navigation_style()` 並重新創建所有子節點，若**頻繁呼叫**（如動態更新導航資料）會造成效能浪費，建議只更新差異部分。
*影響：scripts/ui/tiles/NavigationTile.gd*

**S30** `[⚠️ 建議]` **NavigationTile.perform_scene_transition() 仍用舊式字串 emit**
硬編碼呼叫 `EventBus.emit_signal("scene_transition_requested", ...)` 字串形式，應改為 `EventBus.scene_transition_requested.emit(state_name, navigation_data)`。
*影響：scripts/ui/tiles/NavigationTile.gd*

**S31** `[⚠️ 建議]` **balance.json tile_bonus 所有屬性相同**
`tile_bonus` 中 fire/water/grass/light/dark 均為 2，**目前完全無差異化**，若未來要做屬性加成差異需要同步更新讀取此 JSON 的邏輯。
*影響：data/balance.json*

**S32** `[⚠️ 建議]` **balance.json 缺少進階平衡數值**
缺少敵人防禦（defense）、迴避率（evasion）、爆擊率（critical）等進階數值定義，**平衡系統仍屬初階**，未來擴展需補充。
*影響：data/balance.json*

**S33** `[⚠️ 建議]` **balance.json 連擊倍率與 ResourceManager 硬編碼版本可能不一致**
`ResourceManager.get_combo_multiplier()` 中硬編碼了連擊倍率計算邏輯，但沒有從 `balance.json` 讀取，**JSON 記錄的是設計意圖，程式碼是實際生效的**，兩者若分歧難以察覺。建議程式碼改從 JSON 讀取。
*影響：singletons/ResourceManager.gd、data/balance.json*

**S34** `[⚠️ 建議]` **enemies.json tags 欄位定義但未使用**
`tags` 欄位（如 `["basic", "slime"]`）在所有敵人資料中均有定義，但**程式碼中找不到任何使用此欄位的邏輯**，屬於預留但未接通的設計。
*影響：data/enemies.json*

**S35** `[⚠️ 建議]` **heroes.json passives 欄位冗餘**
`passives` 欄位為空陣列，但技能已統一在 `skills` 欄位中以 `type` 區分主動/被動，**`passives` 欄位設計冗餘**，建議移除或明確定義其用途。
*影響：data/heroes.json*

**S36** `[⚠️ 建議]` **heroes.json growth_curve 邏輯未實作**
`growth_curve: "linear"` 存在，但 `ResourceManager` 中**沒有根據此值計算成長的邏輯**，英雄屬性隨等級提升完全未實作。
*影響：data/heroes.json、singletons/ResourceManager.gd*

**S37** `[⚠️ 建議]` **skills.json script_class 欄位未被使用**
`script_class` 欄位（如 `"FireMasterySkill"`）設計用於動態實例化，但 `SkillManager.create_skill()` 回傳的是 Dictionary 而非 Node 實例，**此欄位實際未被使用**，動態技能載入功能尚未接通。
*影響：data/skills.json、singletons/SkillManager.gd*

**S38** `[⚠️ 建議]` **SimpleTest 使用 get_meta() 取值設計不一致**
`SimpleTest.gd` 以 `get_meta("element")` 取得角色屬性，表示 `ResourceManager` 創建的物件透過 meta 傳遞資料，而非直接設定 `@export` 屬性，**與 `BaseCharacter` 的 `@export` 設計略有落差**，建議統一初始化方式。
*影響：test_scenes/SimpleTest.gd、singletons/ResourceManager.gd*

**S39** `[⚠️ 建議]` **battle_old.gd 應在確認新版穩定後移除**
`battle_old.gd` 保留著重構前的戰鬥場景，已與新版邏輯（UI 與遊戲狀態分離）不一致，**應在確認新版穩定後刪除**，避免混淆。
*影響：scripts/scenes/battle_old.gd*

**S40** `[⚠️ 建議]` **DragDropTest 導航場景路徑不存在**
`DragDropTest.gd` 中 NavigationTile 使用 `res://scenes/BattleScene.tscn` 等**不存在的路徑**（正確應為 `res://scripts/scenes/battle.tscn`），拖入後切換場景會失敗，應同步修正。
*影響：test_scenes/DragDropTest.gd*

---

## 📝 備注 — 中性觀察與設計說明

**N01** `[📝 備注]` **EventBus used_cards_response 請求-回應設計**
`used_cards_response` 訊號暗示手牌有請求-回應（request-response）機制，是非對稱事件設計，比一般廣播訊號更特殊，在實作手牌系統時需特別注意此模式。
*影響：singletons/EventBus.gd*

**N02** `[📝 備注]` **ResourceManager.create_block() 主要供測試使用**
方法有注釋說明「實際遊戲建議使用 `BattleTile.create_from_block_data()`」，此方法定位為測試輔助工具，非正式遊戲使用路徑。
*影響：singletons/ResourceManager.gd*

**N03** `[📝 備注]` **SkillManager 不含技能執行邏輯**
`SkillManager` 只負責資料查詢介面（從 JSON 載入、提供查詢），實際技能效果在 `scripts/skills/` 各類別中，職責分離清晰。
*影響：singletons/SkillManager.gd*

**N04** `[📝 備注]` **StateManager 初始化使用 await process_frame 確保 autoload 就緒**
`_ready()` 中 `await get_tree().process_frame` 確保所有 autoload singleton 初始化完成後才創建狀態機，這是 Godot 中處理 autoload 依賴順序的正確做法。
*影響：singletons/StateManager.gd*

**N05** `[📝 備注]` **BaseCharacter._create_default_appearance() 只用於 Enemy**
此方法在 `Hero` 中被空實作覆寫（`pass`），意味著父類預設的 ColorRect 外觀只用於 Enemy，Hero 有自己的外觀設定邏輯，兩者差異屬於有意設計。
*影響：scripts/components/BaseCharacter.gd、scripts/components/Hero.gd*

**N06** `[📝 備注]` **BaseState.get_state_info() 調試方法設計合理**
使用 `get_script().get_global_name()` 取得類別名稱，搭配狀態 ID 和附帶資料，提供足夠的調試資訊，是實用的狀態機調試工具設計。
*影響：scripts/state_machine/BaseState.gd*

**N07** `[📝 備注]` **DropZone._exit_tree() 正確清理 DragDropManager 訂閱**
`_exit_tree()` 中呼叫 `DragDropManager.unregister_drop_zone(self)`，確保節點移除時投放區域正確從管理器中反註冊，**生命週期管理正確**。
*影響：scripts/ui/DropZone.gd*

**N08** `[📝 備注]` **main_menu.gd F9 熱鍵實作正確**
F9 熱鍵使用 `event is InputEventKey and event.pressed and event.keycode == KEY_F9` 偵測，寫法符合 Godot 4 最佳實踐，與 DebugManager 的 F1 錯誤寫法形成對比（參見 B03）。
*影響：scripts/scenes/main_menu.gd*

**N09** `[📝 備注]` **level_selection.gd _on_confirm_level_tile_dropped() 為 pass 屬正確設計**
此方法為 `pass` 是因為確認邏輯由 `NavigationTile` 內部的 `on_drag_ended()` 自行處理（透過 EventBus 驅動場景切換），`level_selection.gd` 不需要額外處理，此設計合理。
*影響：scripts/scenes/level_selection.gd*

**N10** `[📝 備注]` **DraggableTile 同時支援觸控與滑鼠輸入**
`_on_gui_input()` 統一處理 `InputEventScreenTouch`、`InputEventMouseButton`、`InputEventScreenDrag`、`InputEventMouseMotion`，兼顧手機觸控與桌面滑鼠，對多平台支援設計合理。
*影響：scripts/ui/DraggableTile.gd*

**N11** `[📝 備注]` **blocks.json 無 epic/legendary 稀有度，擴展空間預留**
目前只有 common/uncommon/rare 三個稀有度等級，沒有 epic 或 legendary，顯示有意預留了稀有度擴展空間，未來增加高稀有度方塊不需改動資料格式。
*影響：data/blocks.json*

**N12** `[📝 備注]` **enemies.json 缺少 earth/wind 屬性敵人，但程式碼已預留**
`LevelTile.get_element_display_name()` 中已有「地(earth)」和「風(wind)」屬性的顯示名稱，但 `enemies.json` 中目前沒有任何這兩種屬性的敵人，屬於程式碼超前設計，待未來補充敵人資料時即可生效。
*影響：data/enemies.json、scripts/ui/tiles/LevelTile.gd*

**N13** `[📝 備注]` **levels.json 欄位設計完整，大量預留欄位**
關卡資料結構非常完整，已預留 `bgm`、`background`、`rewards`、`objectives`、`turn_limit`、`special_rules`、`events`、`tutorial_steps` 等進階功能欄位，MVP 階段全部為空值，但格式已鎖定，未來填入不需更動資料結構。
*影響：data/levels.json*

**N14** `[📝 備注]` **DragDropTest._on_navigation_requested() 只 print 是正確的測試設計**
`_on_navigation_requested` 只 `print`，不執行實際場景切換，是正確的測試設計（避免測試場景中意外跳轉至其他場景），與正式場景中 NavigationTile 驅動切換的邏輯刻意隔離。
*影響：test_scenes/DragDropTest.gd*

**N15** `[📝 備注]` **BattleBoard stop_all_animations() 位置重置邏輯正確**
`stop_all_animations()` 雖因無 Tween 引用而無法完全停止動畫（見 B08），但位置重置（`position = Vector2.ZERO`）的設計意圖正確，說明架構上有考慮到動畫恢復問題。
*影響：scripts/ui/BattleBoard.gd*

**N16** `[📝 備注]` **GameSceneStateMachine 場景數量少，遍歷查找效能可接受**
`_on_scene_transition_requested()` 用 for 迴圈遍歷 `SceneType.values()` 查找場景，場景數量少（6個）時效能不是問題，若未來場景大量增加可改用反向 Dictionary 優化。
*影響：scripts/state_machine/GameSceneStateMachine.gd*

**N17** `[📝 備注]` **BattleBoard 多格方塊基礎系統扎實**
`create_grid_layout()` 建立 3×3 每格 200×200px 的棋盤，多格方塊支援（`can_place_multi_tile_at`、`place_multi_tile_at_position`）和撤銷機制（`undo_last_tile_drop`）均已實作，是多格拼圖戰鬥系統的扎實基礎。
*影響：scripts/ui/BattleBoard.gd*

---

## 綜合開發建議

### 優先修復（MVP 阻礙）
1. **C01** — 修復技能 get_tree() 問題，使技能系統可用
2. **C02** — 修復 BattleTile 工廠方法，確保 _ready() 正常執行
3. **C04** — 建立 result.tscn / settings.tscn / deck_build.tscn 空場景，避免切換崩潰
4. **B06** — 補上 Enemy turn_started 訊號連接，使敵人倒數正常運作
5. **C03** — 移除或修正 BattleState.enter() 中不存在的方法呼叫

### 核心循環完善
6. **U10** — 完成波次系統（load_next_enemy_wave 實際建立新敵人）
7. **B11** — 消除 PlayerTurnState 與 battle.gd 的回合結束重複路徑
8. **U17** — 實作 unlock_conditions 自動解鎖邏輯
9. **U15** — 串通方塊旋轉/翻轉的 UI 觸發流程

### 程式碼品質
10. **B01** — 全面將 `emit_signal("name")` 替換為 `.emit()` 格式
11. **S11** — 統一縮排風格（建議全部使用 Tab）
12. **S39** — 確認新版穩定後刪除 battle_old.gd
