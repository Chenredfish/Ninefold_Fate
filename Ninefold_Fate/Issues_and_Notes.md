# 九重命運 (Ninefold Fate) — 注意事項總覽

> 最後更新：2026-06-23
>
> **已完成摘要**：✅ CRASH 5/5、BUG 22/22、建議 11/40（S01~S09、S11~S15、S17~S19、S21~S24、S26、S30、S33、S40）
>
> **未實裝功能進度**：U05、U07、U10、U13 已完成（4/20），其餘 16 項待處理
>
> **戰鬥系統重構**：傷害計算 #1~#6 全部完成（2026-06-23）——逐 tile 計算、target_type 分流、combo_multiplier 跨回合追蹤、await 等待結算完畢

---

## 分類說明

| 標籤 | 意義 |
|------|------|
| `[🚧 未實作]` | 框架已建立但功能尚未填入 |
| `[⚠️ 建議]` | 程式碼品質、可維護性或設計改善 |
| `[📝 備注]` | 中性觀察、設計合理的說明、預留空間描述 |
| `[📝 暫緩]` | 評估後決定暫不處理，原因已記錄 |
| `[📝 不處理]` | 評估後決定不處理 |

---

## 🚧 未實作 — 框架已建立但功能尚未填入

**U01** `[🚧 未實作]` **ResourceManager.return_to_pool() 是假物件池**
`return_to_pool()` 的實際實作只是 `queue_free()`，物件池功能完全未實作，每次「回收」都是直接銷毀物件。
*影響：singletons/ResourceManager.gd*

**U02** `[🚧 未實作]` **DebugManager.hide_debug_info() 為空**
函式體僅為 `pass`，debug UI 無法被隱藏。
*影響：singletons/DebugManager.gd*

**U03** `[🚧 未實作]` **DebugManager.show_debug_info() 只有 print**
方法只輸出到 `print`，沒有實際的 UI 面板（FPS、記憶體、物件檢查器均無顯示）。
*影響：singletons/DebugManager.gd*

**U04** `[🚧 未實作]` **Hero 動畫全部為 pass**
`_play_damage_animation()`、`_play_heal_animation()`、`_play_death_animation()` 三個方法全部是 pass，英雄無任何戰鬥動畫反饋。
*影響：scripts/components/Hero.gd*

**U06** `[🚧 未實作]` **level_selection.gd 返回導航為 pass**
`_on_back_tile_dropped()` 和 `_on_main_menu_tile_dropped()` 皆為 `pass`，多層關卡導航尚未實作。
*影響：scripts/scenes/level_selection.gd*

**U08** `[🚧 未實作]` **battle.gd 暫停按鈕無連接**
「暫停」按鈕已放入場景但無任何連接處理，點擊無效果。
*影響：scripts/scenes/battle.gd*

**U09** `[🚧 未實作]` **VictoryState._calculate_rewards() 為 TODO**
`VictoryState._calculate_rewards()` 有注釋 `# TODO: 根據表現計算獎勵`，目前只有固定金幣/經驗值，無任何基於表現的動態計算。
*影響：scripts/state_machine/BattleStateMachine.gd (VictoryState)*

**U11** `[🚧 未實作]` **FireMasterySkill 傷害加成無 UI 反饋**
被動技能觸發後只 `print`，沒有任何 UI 顯示（如傷害數字變色、特效提示等）。
*影響：scripts/skills/FireMasterySkill.gd*

**U12** `[🚧 未實作]` **技能升等無實際效果**
`BaseSkill.level_up()` 中有注釋「暫時跳過動態重載」，升等後 `_apply_level_scaling()` 不會被重新呼叫，`parameters` 中的數值不更新，升等完全無效。
*影響：scripts/skills/BaseSkill.gd*

**U14** `[🚧 未實作]` **DragDropTest 棋盤完成訊號未接通**
`DragDropTest.gd` 中連接 `secondary_drop_zone.board_completed` 的程式碼被注釋掉，棋盤滿格訊號尚未接通。
*影響：test_scenes/DragDropTest.gd*

**U15** `[🚧 未實作]` **方塊旋轉/翻轉功能無 UI 觸發**
`blocks.json` 中有 `rotation_allowed`/`flip_allowed` 欄位，`ResourceManager.get_rotated_pattern()` 和 `get_flipped_pattern()` 方法存在，但在 `BattleTile` 或 `BattleBoard` 中找不到任何觸發旋轉/翻轉的 UI 操作，資料和邏輯已備但流程未串通。
*影響：scripts/ui/tiles/BattleTile.gd、scripts/ui/BattleBoard.gd*

**U16** `[🚧 未實作]` **棋盤障礙格子（board.blocked）未實作**
`levels.json` 中 `board.blocked` 欄位可設定障礙格子，但 `BattleBoard` 中完全沒有實作此功能，障礙格子設定目前無效。
*影響：scripts/ui/BattleBoard.gd*

**U17** `[🚧 未實作]` **關卡解鎖條件（unlock_conditions）未讀取**
`levels.json` 的 `unlock_conditions` 欄位已設計（如 level_002 需完成 level_001），但程式碼中沒有讀取此欄位並自動解鎖下一關的邏輯，關卡解鎖狀態完全靠 JSON 中的初始值。
*影響：scripts/state_machine/BattleStateMachine.gd、singletons/ResourceManager.gd*

**U18** `[🚧 未實作]` **敵人進階欄位尚未設計**
`enemies.json` 目前每個敵人缺少特殊技能（`skills`/`abilities`）、掉落物（`drops`）、對話（`dialogue`）等進階設計欄位，敵人多樣性極度不足（只有 2 個）。
*影響：data/enemies.json*

**U19** `[🚧 未實作]` **所有視覺元素均為 ColorRect 佔位符**
所有 sprite/icon 均為 `ColorRect + Label` 佔位符，尚未整合真實美術資源。Hero 的 `_create_default_appearance()` 直接 `pass`，英雄若無 sprite 資源將顯示空白。
*影響：scripts/components/BaseCharacter.gd、scripts/components/Hero.gd*

**U20** `[🚧 未實作]` **棋盤滿格自動送出（選項設定）**
計畫新增設定選項：開啟後棋盤放滿時自動觸發結束回合，省去老手重複點按的步驟。
技術上需要：① EventBus 定義 `board_completed` 訊號；② BattleBoard.on_board_completed() 發送訊號（已有注釋掉的預留代碼）；③ 設定系統讀取開關值決定是否自動送出。
*影響：scripts/ui/BattleBoard.gd、singletons/EventBus.gd、設定系統（未建立）*

---

## ⚠️ 建議 — 設計改善與技術債

**S10** `[📝 不處理]` **main.gd StateManager 初始化失敗時靜默 Fallback**
若 `StateManager` 初始化失敗，備用方案直接呼叫 `change_scene_to_file()` 而不印出任何警告，使問題難以排查。
*影響：main.gd*
> **決定：** Autoload 載入失敗時 Godot 引擎本身已會在 Debugger 拋出大量錯誤，額外加 `push_error()` 實際上淹沒在其中毫無幫助。現有的 `print()` 已足夠，不值得改動。

**S16** `[📝 暫緩]` **GameSceneStateMachine LevelSelectionState 白名單過於嚴格**
`LevelSelectionState.can_transition_to()` 限制只能轉換到 `["main_menu", "battle"]`，若未來需要從關卡選擇直接進入設定或其他頁面，需修改白名單，設計不夠彈性。
*影響：scripts/state_machine/GameSceneStateMachine.gd (LevelSelectionState)*
> **決定：** 整個 GameSceneStateMachine 均採用白名單模式控制場景流程，屬於刻意設計。待設定頁、構築頁等場景完善後，再依實際遊戲流程決定是否擴充白名單。

**S20** `[📝 暫緩]` **BattleBoard 缺少棋盤狀態訊號**
`check_board_completion()` 達到滿格或連擊條件時未發送任何訊號，上層 `battle.gd` 無法感知棋盤狀態變化，UI 與邏輯分離做得不夠徹底。
*影響：scripts/ui/BattleBoard.gd*
> **決定：** 此訊號與「棋盤滿格自動送出」功能綁定，待 U20 實作時一併處理。

**S25** `[⚠️ 建議]` **BattleTile 多格縮放基準值硬編碼**
多格方塊的視覺縮放基於 `standard_cell_size = 66.67`（棋盤 200÷3），但實際棋盤格子可能因螢幕 resize 而改變，此數值應參數化，由棋盤動態傳入。
*影響：scripts/ui/tiles/BattleTile.gd*

**S27** `[⚠️ 建議]` **LevelTile.can_start_drag() 定義但從未呼叫**
`can_start_drag()` 方法定義了「locked 狀態不可拖拽」邏輯，但 `_on_gui_input()` 中並未呼叫此方法，拖拽檢查實際由 `DragDropManager.can_accept_tile()` 負責，`can_start_drag()` 形同虛設（dead code）。
*影響：scripts/ui/tiles/LevelTile.gd*

**S28** `[⚠️ 建議]` **NavigationTile._get_scene_type_from_function() 回傳值未使用**
`_get_scene_type_from_function(func_name)` 回傳 `SceneType` 列舉值，但呼叫者 `perform_scene_transition()` 未使用此回傳值，整個方法實際上是多餘的，建議移除或整合。
*影響：scripts/ui/tiles/NavigationTile.gd*

**S29** `[⚠️ 建議]` **NavigationTile.set_navigation_data() 每次呼叫都重建所有內容**
呼叫後觸發 `setup_navigation_style()` 並重新創建所有子節點，若頻繁呼叫（如動態更新導航資料）會造成效能浪費，建議只更新差異部分。
*影響：scripts/ui/tiles/NavigationTile.gd*

**S31** `[⚠️ 建議]` **balance.json tile_bonus 所有屬性相同**
`tile_bonus` 中 fire/water/grass/light/dark 均為 2，目前完全無差異化，若未來要做屬性加成差異需要同步更新讀取此 JSON 的邏輯。
*影響：data/balance.json*

**S32** `[⚠️ 建議]` **balance.json 缺少進階平衡數值**
缺少敵人防禦（defense）、迴避率（evasion）、爆擊率（critical）等進階數值定義，平衡系統仍屬初階，未來擴展需補充。
*影響：data/balance.json*

**S34** `[⚠️ 建議]` **enemies.json tags 欄位定義但未使用**
`tags` 欄位（如 `["basic", "slime"]`）在所有敵人資料中均有定義，但程式碼中找不到任何使用此欄位的邏輯，屬於預留但未接通的設計。
*影響：data/enemies.json*

**S35** `[⚠️ 建議]` **heroes.json passives 欄位冗餘**
`passives` 欄位為空陣列，但技能已統一在 `skills` 欄位中以 `type` 區分主動/被動，`passives` 欄位設計冗餘，建議移除或明確定義其用途。
*影響：data/heroes.json*

**S36** `[⚠️ 建議]` **heroes.json growth_curve 邏輯未實作**
`growth_curve: "linear"` 存在，但 `ResourceManager` 中沒有根據此值計算成長的邏輯，英雄屬性隨等級提升完全未實作。
*影響：data/heroes.json、singletons/ResourceManager.gd*

**S37** `[⚠️ 建議]` **skills.json script_class 欄位未被使用**
`script_class` 欄位（如 `"FireMasterySkill"`）設計用於動態實例化，但 `SkillManager` 回傳的是 Dictionary 而非 Node 實例，此欄位實際未被使用，動態技能載入功能尚未接通。
*影響：data/skills.json、singletons/SkillManager.gd*

**S38** `[⚠️ 建議]` **SimpleTest 使用 get_meta() 取值設計不一致**
`SimpleTest.gd` 以 `get_meta("element")` 取得角色屬性，表示 `ResourceManager` 創建的物件透過 meta 傳遞資料，而非直接設定 `@export` 屬性，與 `BaseCharacter` 的 `@export` 設計略有落差，建議統一初始化方式。
*影響：test_scenes/SimpleTest.gd、singletons/ResourceManager.gd*

**S39** `[⚠️ 建議]` **battle_old.gd 應在確認新版穩定後移除**
`battle_old.gd` 保留著重構前的戰鬥場景，已與新版邏輯（UI 與遊戲狀態分離）不一致，應在確認新版穩定後刪除，避免混淆。
*影響：scripts/scenes/battle_old.gd*

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
`_exit_tree()` 中呼叫 `DragDropManager.unregister_drop_zone(self)`，確保節點移除時投放區域正確從管理器中反註冊，生命週期管理正確。
*影響：scripts/ui/DropZone.gd*

**N08** `[📝 備注]` **main_menu.gd F9 熱鍵實作正確**
F9 熱鍵使用 `event is InputEventKey and event.pressed and event.keycode == KEY_F9` 偵測，寫法符合 Godot 4 最佳實踐。
*影響：scripts/scenes/main_menu.gd*

**N09** `[📝 備注]` **level_selection.gd _on_confirm_level_tile_dropped() 為 pass 屬正確設計**
此方法為 `pass` 是因為確認邏輯由 `NavigationTile` 內部的 `on_drag_ended()` 自行處理（透過 EventBus 驅動場景切換），`level_selection.gd` 不需要額外處理，此設計合理。
*影響：scripts/scenes/level_selection.gd*

**N10** `[📝 備注]` **DraggableTile 同時支援觸控與滑鼠輸入**
`_on_gui_input()` 統一處理 `InputEventScreenTouch`、`InputEventMouseButton`、`InputEventScreenDrag`、`InputEventMouseMotion`，兼顧手機觸控與桌面滑鼠，對多平台支援設計合理。
*影響：scripts/ui/DraggableTile.gd*

**N11** `[📝 備注]` **blocks.json 無 epic/legendary 稀有度，擴展空間預留**
目前只有 common/uncommon/rare 三個稀有度等級，顯示有意預留了稀有度擴展空間，未來增加高稀有度方塊不需改動資料格式。
*影響：data/blocks.json*

**N12** `[📝 備注]` **enemies.json 缺少 earth/wind 屬性敵人，但程式碼已預留**
`LevelTile.get_element_display_name()` 中已有「地(earth)」和「風(wind)」屬性的顯示名稱，但 `enemies.json` 中目前沒有任何這兩種屬性的敵人，屬於程式碼超前設計，待未來補充敵人資料時即可生效。
*影響：data/enemies.json、scripts/ui/tiles/LevelTile.gd*

**N13** `[📝 備注]` **levels.json 欄位設計完整，大量預留欄位**
關卡資料結構已預留 `bgm`、`background`、`rewards`、`objectives`、`turn_limit`、`special_rules`、`events`、`tutorial_steps` 等進階功能欄位，MVP 階段全部為空值，但格式已鎖定，未來填入不需更動資料結構。
*影響：data/levels.json*

**N14** `[📝 備注]` **DragDropTest._on_navigation_requested() 只 print 是正確的測試設計**
`_on_navigation_requested` 只 `print`，不執行實際場景切換，是正確的測試設計（避免測試場景中意外跳轉至其他場景）。
*影響：test_scenes/DragDropTest.gd*

**N15** `[📝 備注]` **BattleBoard stop_all_animations() 位置重置邏輯正確**
`stop_all_animations()` 雖無法完全停止 Tween，但位置重置（`position = Vector2.ZERO`）的設計意圖正確，架構上有考慮到動畫恢復問題。
*影響：scripts/ui/BattleBoard.gd*

**N16** `[📝 備注]` **GameSceneStateMachine 場景數量少，遍歷查找效能可接受**
`_on_scene_transition_requested()` 用 for 迴圈遍歷 `SceneType.values()` 查找場景，場景數量少（6個）時效能不是問題，若未來場景大量增加可改用反向 Dictionary 優化。
*影響：scripts/state_machine/GameSceneStateMachine.gd*

**N17** `[📝 備注]` **BattleBoard 多格方塊基礎系統扎實**
`create_grid_layout()` 建立 3×3 每格 200×200px 的棋盤，多格方塊支援（`can_place_multi_tile_at`、`place_multi_tile_at_position`）和撤銷機制（`undo_last_tile_drop`）均已實作，是多格拼圖戰鬥系統的扎實基礎。
*影響：scripts/ui/BattleBoard.gd*

---

## 綜合開發建議

### 近期可評估（有現有框架，接通即用）

| 優先 | ID | 說明 |
|------|----|----|
| 🟡 中 | U06 | level_selection 返回/主選單導航（`pass` 改接通） |
| 🟡 中 | U17 | unlock_conditions 自動解鎖（讀 JSON 欄位即可） |
| 🟡 中 | U15 | 方塊旋轉/翻轉 UI 觸發（邏輯已備，補 UI 操作） |
| 🟡 中 | U20 | 棋盤滿格自動送出（設定開關 + BattleBoard 訊號） |
| 🟢 低 | S39 | 刪除 battle_old.gd（確認新版穩定後） |
| 🟢 低 | S27 | 移除 LevelTile.can_start_drag() dead code |
| 🟢 低 | S28 | 整合或移除 NavigationTile._get_scene_type_from_function() |

### 中長期功能

| 優先 | ID | 說明 |
|------|----|----|
| 🟡 中 | U04 | Hero 戰鬥動畫（目前全為 pass） |
| 🟡 中 | U09 | VictoryState 基於表現的動態獎勵計算 |
| 🟡 中 | U11 | 被動技能觸發 UI 反饋 |
| 🟡 中 | U12 | 技能升等實際效果（`_apply_level_scaling()` 重新呼叫） |
| 🟡 中 | U18 | 敵人多樣性：增加敵人數量與進階欄位設計 |
| 🟢 低 | S36 | 英雄成長曲線實作（heroes.json growth_curve 接通） |
| 🟢 低 | S37 | skills.json script_class 動態載入技能 |

### 暫緩（待相依功能完成再評估）

- **S16** — GameSceneStateMachine 白名單彈性：待設定頁、構築頁完善後擴充
- **S20** — BattleBoard 棋盤狀態訊號：與 U20 棋盤滿格自動送出一起處理
- **U16** — 棋盤障礙格子：待關卡設計需要時再實作
- **U01~U03** — 物件池、DebugManager UI：工具類，優先度最低
