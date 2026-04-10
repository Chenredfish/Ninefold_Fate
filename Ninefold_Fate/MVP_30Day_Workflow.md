

# 九重命運 MVP 30 天開發工作日誌（可勾選表單版）

本計畫依據 MVP 問卷內容，將 Godot 專案開發流程細分為 30 天，每日明確列出目標、重點任務、需設計/新增的物件、函式、場景、節點與驗收標準。每一小步驟皆可單獨勾選。

---

## Day 1
- [ ] Godot 4.5 專案初始化
- [ ] 設定專案解析度
- [ ] 設定直向模式
- [ ] 設定 FPS
- [ ] 建立資料夾：
	- [ ] scenes/
	- [ ] scripts/
	- [ ] data/
	- [ ] ui/
	- [ ] audio/
- [ ] 初始化 Git
- [ ] 設置 .gitignore

## Day 2
- [ ] 設計統一拖放系統基礎
	- [ ] 撰寫 DragDropManager.gd（Autoload）
	- [ ] 撰寫 DraggableTile.gd（基類）
	- [ ] 撰寫 DropZone.gd（基類）
	- [ ] 基礎拖放邏輯與訊號設計
- [ ] 設計主選單場景 MainMenu.tscn
	- [ ] 新增多層 CanvasLayer（背景、互動、效果）
	- [ ] 新增 NavigationGrid（3×3導航網格）
	- [ ] 新增 FunctionTileContainer（功能圖塊區）
	- [ ] 新增腳本 MainMenu.gd
- [ ] 建立 LevelSelection.tscn 空場景

## Day 3
- [ ] 設計結算場景 Result.tscn（拖放版本）
	- [ ] 新增多層 CanvasLayer（背景、互動、效果）
	- [ ] 新增 ActionGrid（3×3行動確認網格）
	- [ ] 新增 ActionTileContainer（行動圖塊區）
	- [ ] 新增腳本 Result.gd
- [ ] 設計功能圖塊
	- [ ] NavigationTile（戰鬥、構築、商店、設定）
	- [ ] ActionTile（重試、繼續、返回、分享）
- [ ] 串接主選單→戰鬥→結算→主選單拖放流程

## Day 4
- [ ] 設計戰鬥場景骨架 Battle.tscn
	- [ ] 新增 CanvasLayer
	- [ ] 新增 EnemyPanel
	- [ ] 新增 BoardRoot
	- [ ] 新增 TileBagPanel
	- [ ] 新增 ActionPanel
	- [ ] 新增 DamageBreakdownPopup
	- [ ] 新增 MessagePopup
	- [ ] 新增腳本 Battle.gd

## Day 5
- [ ] 設計棋盤 BoardRoot
	- [ ] 新增 GridContainer（9x9）
	- [ ] 新增 Tile（自訂控件）
	- [ ] 新增腳本 Board.gd
	- [ ] 支援 blocked 格顯示
	- [ ] 支援格子點擊/高亮

## Day 6
- [ ] 設計候選圖塊區 TileBagPanel
	- [ ] 新增 HBoxContainer
	- [ ] 新增 TileBagSlot（自訂控件）
	- [ ] 新增腳本 TileBag.gd
	- [ ] 設計圖塊資料結構（TileData）
	- [ ] 支援圖塊拖曳
	- [ ] 支援吸附網格

## Day 7
- [ ] 設計敵人面板 EnemyPanel
	- [ ] 新增 TextureRect（頭像）
	- [ ] 新增 ProgressBar（HP）
	- [ ] 新增 Label（CD）
	- [ ] 新增 Label（屬性）
	- [ ] 新增腳本 Enemy.gd
	- [ ] 設計敵人資料結構（EnemyData）
	- [ ] 完成敵人倒數顯示

## Day 8
- [ ] 設計操作面板 ActionPanel
	- [ ] 新增 Button（送出）
	- [ ] 新增 Label（combo）
	- [ ] 新增 Label（回合提示）
	- [ ] 新增 Button（設定）
	- [ ] 新增腳本 ActionPanel.gd
	- [ ] 完成送出按鈕互動
	- [ ] 設計回合提示訊息顯示

## Day 9
- [ ] 設計傷害分解與訊息彈窗
	- [ ] 新增 PopupPanel（DamageBreakdownPopup）
	- [ ] 新增 PopupPanel（MessagePopup）
	- [ ] 新增腳本 DamageBreakdownPopup.gd
	- [ ] 新增腳本 MessagePopup.gd
	- [ ] 完成彈窗顯示/隱藏流程

## Day 10
- [ ] 撰寫 DataLoader.gd（Autoload）
	- [ ] load_json(path)
	- [ ] get_data(key)
- [ ] 撰寫 GameState.gd（Autoload）
	- [ ] current_level 屬性
	- [ ] rng_seed 屬性
	- [ ] set_level(id)
	- [ ] reset_state()

## Day 11
- [ ] 設計 balance.json
- [ ] 設計 hero_001.json
- [ ] 設計 level_001.json
- [ ] 設計 level_002.json
- [ ] 撰寫資料註解
- [ ] 測試 DataLoader 載入
- [ ] 資料驗證

## Day 12
- [ ] 撰寫 Board.gd 主要函式
	- [ ] place_tile(tile, pos)
	- [ ] is_valid_placement(tile, pos)
	- [ ] scan_3x3()
- [ ] 單元測試格子放置
- [ ] 單元測試 blocked 驗證

## Day 13
- [ ] 撰寫 TileBag.gd 主要函式
	- [ ] generate_tiles()
	- [ ] refill_tile()
	- [ ] can_place_more()
- [ ] 支援送出後自動補新圖塊

## Day 14
- [ ] 撰寫 DamageResolver.gd 主要函式
	- [ ] calc_damage(hero, tiles, combo)
	- [ ] get_main_color(tiles)
	- [ ] get_combo_multiplier(combo)
- [ ] 套用 balance.json 公式

## Day 15
- [ ] 撰寫 Enemy.gd 主要函式
	- [ ] tick_cd()
	- [ ] attack_player()
	- [ ] reset_cd()
- [ ] 支援多敵人資料結構（先只顯示一隻）

## Day 16
- [ ] 撰寫 BattleUI.gd
	- [ ] 設計訊號 tile_placed
	- [ ] 設計訊號 turn_resolved
	- [ ] 設計訊號 enemy_attacked
	- [ ] 設計訊號 level_completed
	- [ ] 串接各 Panel 與邏輯腳本

## Day 17
- [ ] 串接主選單、關卡選單、戰鬥、結算完整流程
	- [ ] 新增函式 change_scene(target)
	- [ ] 支援關卡切換
	- [ ] 支援重來

## Day 18
- [ ] 實作 debug overlay
	- [ ] 新增 Panel
	- [ ] 新增 Label（回合）
	- [ ] 新增 Label（傷害分解）
	- [ ] 新增 Label（敵人倒數）
- [ ] BattleUI 實作 reload_balance() 按鈕

## Day 19
- [ ] 設計 LevelSelection UI（拖放選關）
	- [ ] 新增 ChapterInfo（章節資訊、進度條）
	- [ ] 新增 ConfirmationGrid（3×3確認網格）
	- [ ] 新增 LevelTileContainer（關卡圖塊滾動）
	- [ ] 新增腳本 LevelSelection.gd
	- [ ] 設計 LevelTile（關卡圖塊）
	- [ ] 關卡解鎖條件與星級顯示

## Day 20
- [ ] 完善拖放導航系統
	- [ ] 實作 NavigationTile 拖放邏輯
	- [ ] 實作場景切換動畫
	- [ ] 測試主選單四個功能圖塊
	- [ ] 優化拖放視覺反饋
- [ ] 構築系統預留
	- [ ] 建立 DeckBuild.tscn 空場景（暫不實作）
	- [ ] 構築圖塊顯示但點擊提示「敬請期待」

## Day 21
- [ ] 設計設定視窗
	- [ ] 新增 PopupPanel
	- [ ] 新增 Slider（音量）
	- [ ] 新增 Button（重設）
	- [ ] 新增 Button（關於）
	- [ ] 新增腳本 SettingsPopup.gd

## Day 22
- [ ] 結算畫面統計顯示
	- [ ] 新增 Label（回合數）
	- [ ] 新增 Label（最大連擊）
	- [ ] 新增 Label（總傷害）
	- [ ] 串接 Result.gd 顯示統計資料

## Day 23
- [ ] 無可放置時提示與強制結束回合
	- [ ] Board.gd 新增函式 has_valid_move()
	- [ ] BattleUI.gd 新增流程控制

## Day 24
- [ ] 預留動畫層、特效層節點
	- [ ] 新增 AnimationPlayer
	- [ ] 新增 Particles2D
	- [ ] 製作簡單 UI 彈跳動畫
	- [ ] 製作棋盤高亮動畫

## Day 25
- [ ] 多語系資料結構設計
	- [ ] 新增 data/locale.json
	- [ ] UI 節點支援文字切換

## Day 26
- [ ] 彈窗模組化設計
	- [ ] 將設定彈窗獨立 scene
	- [ ] 將說明彈窗獨立 scene
	- [ ] 將獎勵彈窗獨立 scene
	- [ ] 新增函式 show_popup(type)

## Day 27
- [ ] 撰寫自動化測試腳本（如有）
	- [ ] 測試 Board.gd
	- [ ] 測試 TileBag.gd
	- [ ] 測試 DamageResolver.gd
	- [ ] 測試 Enemy.gd

## Day 28
- [ ] 全流程手動測試，依驗收清單逐項檢查
	- [ ] 修正流程問題
	- [ ] 修正 UI 問題
	- [ ] 修正數值問題

## Day 29
- [ ] 補齊缺漏美術資源（如有）
- [ ] 替換佔位圖
- [ ] 優化 UI/UX 細節

## Day 30
- [ ] 最終整合
- [ ] 重構
- [ ] 清理專案
- [ ] 撰寫 README
- [ ] 撰寫開發紀錄
- [ ] 交付驗收

---

> 本日誌可依實際進度彈性調整，建議每日完成後記錄遇到的問題與解決方式，利於後續維護與擴充。