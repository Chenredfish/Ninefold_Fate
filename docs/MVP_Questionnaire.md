# Ninefold Fate — 原型 MVP 問答清單（填寫範本）

用途：請直接在此檔勾選 [x]、填空或修改預設值。完成後我會依你的答案產出可執行的原型工作排程與檔案樣板。

---

## 1) 目標平台與效能
- 作業系統：
  - [ ] iOS
  - [ ] Android
  - [x] 兩者皆要（MVP 僅針對其中一種實測：Android）
- 螢幕方向：
  - [x] 直向
  - [ ] 橫向
- 解析度目標（畫面基準尺寸）：`1080x1920`
- 目標 FPS：`60`
- 畫面比例處理：
  - [x] 以 1080x1920 為基準，其他比例上下留黑/裁切
  - [ ] 自適應 UI

## 2) 輸入模型與操作
- 拖放放置：
  - [x] 單指拖放到格子，吸附網格
  - [ ] 放置前可旋轉
  - [ ] 可翻面
- 撤銷：
  - [ ] 不支援
  - [ ] 支援（限制：棋盤送出後無法撤銷）
- 無效放置：
  - [x] 回彈 + 無提示
  - [ ] 直接禁止拖入
- 其他：
  - 觸覺/音效回饋（MVP）：[ ] 有  [x] 無

## 3) MVP 範圍與排除
- 此版本需要：
  - [x] 戰鬥核心（棋盤放置 + 傷害結算 + 敵人倒數）
  - [x] 基礎戰鬥 UI（回合提示、結算面板、設定）
  - [x] 關卡讀取（至少 2 關）
- 此版本先不做：
  - [x] 抽卡
  - [x] 存檔
  - 主動技能：
    - [x] 暫不做(只被動技能)
    - [ ] 簡化 1 個英雄技能（說明：_____）
- Definition of Done（可調整）：
  - [x] 可完整打一關並顯示勝/敗
  - [x] 顯示傷害分解（基礎、屬性、連擊）
  - [x] 敵人倒數與攻擊正確
  - [x] 兩個關卡可切換與重來

## 4) 核心規則細節
- 棋盤尺寸：
  - [x] 9×9
  - [ ] 其他：____
- 圖塊形態：
  - [ ] 單格
  - [X] 多格（形狀清單：之後新增；皆不可旋轉）
- 放置條件：
  - [x] 只能放在空格
  - [x] 不能放在 blocked 牆
- 候選圖塊區：
  - 同時可選數量：`4`
  - 送出棋盤後立即補一個新圖塊：[x] 是 [ ] 否
- 回合內可放置次數上限：`8`
- 3×3 方陣的形成與結算：
  - [x] 按下送出按鈕(不需要 3×3 區域填滿)
  - 主色定義：區域內最多的屬性為主色；若平手→
    - [x] 使用英雄屬性
    - [ ] 固定優先序
- Combo 定義：
  - [x] 同一回合內每完成一次 3×3 +1 連擊
  - [x] 連擊跨回合累積（重置條件：一回合沒有完成3*3）
- 回合順序：
  - [x] 玩家放置 → 結算 → 敵人倒數/攻擊 → 下一回合
  - 倒數加速條件（若有）：無（預設無）

## 5) 數值基線（可直接填數）
- 英雄基礎攻擊：`100`
- 單格圖塊加成：各屬性 `+2`（可改：_____）
- 屬性相剋矩陣：
  - 同屬：`1.0`
  - 剋屬：`1.1`
  - 被剋：`0.9`
  - 其他：`1.0`
- 連擊倍率：
  - 1 連：`1.0`；2 連：`1.1`；3 連：`1.2`；（公式或表格：1~11連每個增加0.1，11連之後每個增加0.5）
- 傷害公式（確認/修改）：
  - `damage = floor((hero_base + 3×tile_bonus_main) × element_multiplier × combo_multiplier)`

## 6) 敵人與倒數
- 同場敵人數量：
  - [x] 1
  - [ ] 1～3（站位與順序：_____）
- 倒數：
  - 初始 CD：`3`（可改：_____）
  - 每回合 -1；到 0 後攻擊並重置為：`3`（可改：_____）
- 攻擊型態：
  - [x] 固定傷害 `80`
  - [ ] 係數（請寫公式：_____）
  - 目標：
    - [x] 玩家（單體）
    - [ ] 範圍/全體（若未來有多單位）

## 7) 技能（若 MVP 要做）
- 本版是否包含技能：
  - [x] 否
  - [ ] 是（請填）
    - 名稱：_____
    - 觸發： [ ] 冷卻 `__` 回合 / [ ] 能量 `__` / [ ] 一次性
    - 效果：_____
    - UI 觸發方式： [ ] 按鈕 / [ ] 自動

## 8) UI/UX 流程
- 主要畫面：
  - [x] 主選單 → 戰鬥 → 結算 → 重來/返回主選單
- 戰鬥畫面元素：
  - [x] 敵人展示 + 倒數
  - [x] 棋盤（9×9）
  - [x] 候選 4 個圖塊區
  - [x] 回合與提示訊息（debug overlay 可切換）
- 例外情境處理：
  - 無可放置時： [x] 提示 + 強制結束回合 / [ ] 其他：_____


### 8.1 主要場景與流程

- MainMenu（主選單）
  - LOGO/標題
  - 拖放導航區域（3×3網格）
  - 功能圖塊：戰鬥、構築、商店、設定
  - 版權/版本資訊

- LevelSelection（關卡選擇）
  - 章節資訊區（章節標題、進度條）
  - 關卡確認區域（3×3網格）
  - 關卡圖塊區（水平滾動）
  - [返回主選單] 圖塊

- Battle（戰鬥場景）
  - ...（同前述）

- Result（結算畫面）
  - ...（同前述）

- Battle（戰鬥場景）
  - 上層：
    - 敵人區（敵人立繪/頭像、屬性icon、HP條、倒數CD、攻擊動畫/提示）
    - 關卡名稱/回合數顯示
  - 中層：
    - 棋盤區（9×9格，blocked格有特殊底色/遮罩）
    - 放置高亮（可放區域高亮、拖曳時吸附）
    - 已放置圖塊顯示（多格圖塊以不同顏色/邊框區分）
  - 下層：
    - 候選圖塊區（4個，顯示形狀/屬性，支援拖曳）
    - [送出] 按鈕（本回合結算）
    - Combo/連擊顯示（本回合已完成次數）
    - 傷害分解面板（彈出/浮動，顯示基礎、屬性、連擊倍率）
    - 回合提示/訊息（如「無可放置」「敵人攻擊」）
    - [設定] 按鈕（暫停、音量、重來、返回主選單）

- Result（結算畫面）
  - 勝利/失敗大字
  - 關卡通過/失敗說明
  - [重來]、[返回主選單] 按鈕
  - 本局統計（回合數、最大連擊、總傷害等）

### 8.2 Godot 場景分層與節點建議


- MainMenu.tscn
  - CanvasLayer（背景層）
    - TitlePanel（LOGO/標題）
    - NavigationGrid（3×3導航網格）
  - CanvasLayer（互動層）
    - FunctionTileContainer（戰鬥、構築、商店、設定圖塊）
  - CanvasLayer（效果層）
    - DragPreview、TransitionEffect

- LevelSelection.tscn
  - CanvasLayer（背景層）
    - ChapterInfo（章節資訊、進度條）
    - ConfirmationGrid（3×3確認網格）
  - CanvasLayer（互動層）
    - LevelTileContainer（關卡圖塊滾動區）
    - BackTile（返回圖塊）
  - CanvasLayer（資訊層）
    - LevelDetailPopup、DragPreview

- Battle.tscn
  - CanvasLayer
    - EnemyPanel（敵人頭像、HP條、CD、屬性icon）
    - BoardRoot（棋盤格子、blocked遮罩、已放置圖塊）
    - TileBagPanel（候選圖塊區，支援拖曳）
    - ActionPanel（送出按鈕、combo顯示、回合提示、設定）
    - DamageBreakdownPopup（傷害分解浮窗）
    - MessagePopup（提示訊息）

- Result.tscn
  - CanvasLayer
    - VBoxContainer（勝敗大字、統計、按鈕群）

### 8.3 UI 分層與訊號流向

- UI 分層：
  - 背景層（棋盤、敵人、圖塊）
  - 互動層（拖曳、放置高亮、送出按鈕）
  - 資訊層（HP、CD、combo、傷害分解、訊息）
  - 彈出層（結算、設定、提示）

- 訊號流向建議：
  - TileBagPanel → BoardRoot：tile_dragged, tile_placed
  - BoardRoot → DamageResolver：request_damage_calc
  - DamageResolver → ActionPanel/DamageBreakdownPopup：damage_result
  - EnemyPanel → ActionPanel/MessagePopup：enemy_attack, enemy_cd_update
  - ActionPanel → BattleUI：turn_end, request_result
  - BattleUI → Result.tscn：show_result


#### 8.4 UI 分層可擴充建議
- 動畫層（Animation Layer）：角色/敵人攻擊、受擊、技能、UI 彈跳等動畫，與互動層分離。
- 特效層（Effect Layer）：粒子、閃光、爆擊等特效，獨立於主互動與資訊層。
- 多語系/國際化：UI 文字集中管理（如本地化字典），方便日後多語系擴充。
- 彈窗/模組化：所有彈窗（設定、說明、獎勵等）獨立 scene，便於複用與動態生成。

---

## 9) Godot 結構確認

- 版本：`Godot 4.x`（確切版本：4.5）
- Autoload：
  - [x] GameState.gd（關卡、RNG seed）
  - [x] DataLoader.gd（讀取 JSON）
  - [x] DragDropManager.gd（統一拖放系統）
- Scenes：
  - [x] MainMenu.tscn（拖放導航）
  - [x] LevelSelection.tscn（拖放選關）
  - [x] Battle.tscn（含 Board / TileBag / Enemy / Hero / BattleUI）
  - [x] Result.tscn（拖放選擇後續行動）
- Scripts（邏輯分工）：
  - [x] DraggableTile.gd（可拖拽圖塊基類）
  - [x] DropZone.gd（投放區域基類）
  - [x] Board.gd（格子、放置驗證、3×3 掃描）
  - [x] TileBag.gd（候選生成與補充）
  - [x] DamageResolver.gd（傷害分解、combo）
  - [x] Enemy.gd（倒數/攻擊）
  - [x] BattleUI.gd（提示、結算、熱重載）
- 訊號約定：
  - [x] tile_placed, turn_resolved, enemy_attacked, level_completed
  - [x] drag_started, drag_ended, navigation_requested（拖放系統）

## 10) 資料格式樣例（直接在此區塊內填）


- balance.json（統一高數值與倍率規則）
```jsonc
{
  // 英雄基礎攻擊力
  "hero_base_attack": 100,
  // 各屬性單格圖塊加成
  "tile_bonus": {"fire": 2, "water": 2, "grass": 2, "light": 2, "dark": 2},
  // 屬性相剋倍率
  "element_multiplier": {
    "same": 1.0,         // 同屬性
    "advantage": 1.1,    // 剋屬
    "disadvantage": 0.9, // 被剋
    "neutral": 1.0       // 其他
  },
  // 連擊倍率表
  "combo_multiplier_table": {
    "1": 1.0,  // 1 連擊
    "2": 1.1,  // 2 連擊
    "3": 1.2,
    "4": 1.3,
    "5": 1.4,
    "6": 1.5,
    "7": 1.6,
    "8": 1.7,
    "9": 1.8,
    "10": 1.9,
    "11": 2.0
  },
  // 11連以上倍率增幅規則
  "combo_multiplier_formula": "11連之後每+1連擊，倍率+0.5"
}
```

- hero_001.json（可擴充角色資料範例）
```jsonc
{
  "id": "H001", // 角色唯一ID
  "name": {"zh": "火之勇者", "en": "Flame Hero"}, // 名稱（多語系）
  "element": "fire", // 屬性
  "base_attack": 100, // 基礎攻擊力
  "hp": 1000, // 生命值
  "level": 1, // 等級
  "exp": 0, // 經驗值
  "growth_curve": "linear", // 成長曲線
  "skills": [
    {"id": "S001", "type": "passive", "desc": {"zh": "火屬性傷害+10%", "en": "+10% fire damage"}} // 技能（被動/主動）
  ],
  "passives": [], // 被動技能（可擴充）
  "icon_path": "res://art/hero/H001_icon.png", // 頭像路徑
  "sprite_path": "res://art/hero/H001_sprite.png", // 角色圖路徑
  "animation_set": "res://art/hero/H001_anim.tres", // 動畫資源
  "tags": ["starter", "warrior"], // 標籤
  "unlock_level": 1 // 解鎖等級
}
```

- level_001.json（統一高數值設定）

```jsonc
{
  "id": "level_001", // 關卡ID
  "name": "", // 關卡名稱
  "description": "", // 關卡描述
  "bgm": "", // 背景音樂
  "background": "", // 背景圖/場景
  "rewards": [], // 通關獎勵
  "objectives": [], // 額外目標
  "turn_limit": null, // 回合限制
  "special_rules": "", // 特殊規則
  "enemy_spawn_pattern": "", // 敵人出現模式
  "events": [], // 劇情/事件
  "tutorial_steps": [], // 教學步驟
  "unlock_conditions": [], // 解鎖條件
  "recommended_power": null, // 建議戰力
  "tags": [], // 標籤
  "board": {"width": 9, "height": 9, "blocked": []}, // 棋盤設定（blocked: 障礙格）
  "hero_id": "H001", // 使用英雄ID
  "enemies": [
    {"id": "E001", "hp": 800, "element": "water", "atk": 80, "cd": 3} // 敵人資料（id, hp, 屬性, 攻擊, 倒數）
  ],
  "win_condition": "all_enemies_defeated" // 勝利條件
}
```

- level_002.json（範例，火屬敵人，HP更高）

```jsonc
{
  "id": "level_002", // 關卡ID
  "name": "", // 關卡名稱
  "description": "", // 關卡描述
  "bgm": "", // 背景音樂
  "background": "", // 背景圖/場景
  "rewards": [], // 通關獎勵
  "objectives": [], // 額外目標
  "turn_limit": null, // 回合限制
  "special_rules": "", // 特殊規則
  "enemy_spawn_pattern": "", // 敵人出現模式
  "events": [], // 劇情/事件
  "tutorial_steps": [], // 教學步驟
  "unlock_conditions": [], // 解鎖條件
  "recommended_power": null, // 建議戰力
  "tags": [], // 標籤
  "board": {"width": 9, "height": 9, "blocked": [{"x":4,"y":4}]}, // 棋盤設定（blocked: 障礙格）
  "hero_id": "H001", // 使用英雄ID
  "enemies": [
    {"id": "E002", "hp": 1200, "element": "fire", "atk": 100, "cd": 3} // 敵人資料
  ],
  "win_condition": "all_enemies_defeated" // 勝利條件
}
```

- 元素相剋說明（若有特殊規則，請文字描述）：
```
火→草、草→水、水→火；光↔暗；同屬加成；其餘中性。（可修改）
```

## 11) 工具鏈與流程
- 版本控制：
  - [x] 使用 Git；忽略 .import、.godot
- 資料夾結構：
  - [x] res://scenes, res://scripts, res://data, res://ui, res://audio
- 數值熱重載：
  - [x] BattleUI 上提供「重新讀取 balance.json」按鈕
- 除錯：
  - [x] 顯示當前回合、傷害分解、敵人倒數

## 12) 驗收與測試
- 關卡：
  - [x] 兩個可選關卡（001/002），可重來
- 手動測試清單：
  - [x] 有效/無效放置行為
  - [x] 成功結算 3×3，顯示分解
  - [x] 敵人倒數→攻擊→重置流程
  - [x] 勝利/失敗視窗
  - [x] 無可放置時的提示/處理

## 13) 開發時程（兩週樣板）
- 我是否採用建議 30 天工期切分：
  - [x] 是
  - [ ] 否（請提供你的日期規劃：_____）
- 預計開始日期：_____；預計完成日期：_____

## 14) 風險與備註
- 你目前最擔心的風險（任填 1～3 項）：
  - 1) 無美術資源
  - 2) UI狀態管理
  - 3) _____
- 額外需求或想先嘗試的變體：故事模式(有文本)

---
填好後回傳此檔或直接告訴我關鍵差異，我會：
1) 生成 data/balance.json、data/level_001.json/002.json 的最小可用版本；
2) 產出 Godot 專案節點/腳本清單與訊號約定；
3) 給出具體的 Day 1~Day 10 工作單與驗收點。