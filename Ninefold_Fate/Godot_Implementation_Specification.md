# Ninefold Fate - Godot 實作規格書

## 1. 概述與技術要求
- 引擎版本：Godot 4.5
- 腳本語言：GDScript
- 基準解析度：1080×1920
- 輸入系統：觸控拖放

## 2. 資料夾結構與資源管理
- 建議的 res:// 資料夾結構
- 檔案命名規範
- 主題資源配置（UITheme.tres）

## 3. AutoLoad 與主題資源
- project.godot AutoLoad 設定
- UITheme.tres 配置

## 4. 場景樹結構與節點屬性
### 4.1 主選單 (MainMenu.tscn)
```
MainMenu (Control)
├── BackgroundLayer (CanvasLayer)
│   ├── TitlePanel (Control)
│   │   ├── GameLogo (Label)
│   │   └── SubtitleLabel (Label)
│   └── NavigationGrid (Control)
│       ├── GridContainer (GridContainer)
│       │   ├── GridSlot1 (Control) 
│       │   ├── GridSlot2 (Control)
│       │   ├── ...
│       │   └── CenterSlot (Control + DropZone)
│       └── GridHighlight (NinePatchRect)
├── InteractionLayer (CanvasLayer)
│   └── FunctionTileContainer (Control)
│       ├── BattleTile (Control + DraggableTile + NavigationTile)
│       ├── DeckBuildTile (Control + DraggableTile + NavigationTile)
│       ├── ShopTile (Control + DraggableTile + NavigationTile)
│       └── SettingsTile (Control + DraggableTile + NavigationTile)
└── EffectLayer (CanvasLayer)
    ├── DragPreview (Control)
    └── TransitionEffect (ColorRect + AnimationPlayer)
```

#### 4.1.1 具體節點屬性設定

##### MainMenu (Control)
```gdscript
# 節點屬性
anchor_left = 0.0
anchor_top = 0.0  
anchor_right = 1.0
anchor_bottom = 1.0
size = Vector2(1080, 1920)
```

##### BackgroundLayer (CanvasLayer)
```gdscript
layer = 0
```

##### TitlePanel (Control)
```gdscript
anchor_left = 0.0
anchor_top = 0.0
anchor_right = 1.0
anchor_bottom = 0.0
offset_bottom = 400.0
size = Vector2(1080, 400)
```

##### GameLogo (Label)
```gdscript
text = "Ninefold Fate"
anchor_left = 0.5
anchor_top = 0.0
anchor_right = 0.5
anchor_bottom = 0.0
offset_left = -300.0  # 600px 寬度的一半
offset_top = 90.0     # 150 - 60 (字體高度一半)
offset_right = 300.0
offset_bottom = 210.0
horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
vertical_alignment = VERTICAL_ALIGNMENT_CENTER

# 字體設定
add_theme_font_size_override("font_size", 48)
add_theme_color_override("font_color", Color(1.0, 0.843, 0.0)) # #FFD700
add_theme_font_override("font", bold_font_resource)
```

##### SubtitleLabel (Label)
```gdscript
text = "選擇你的命運方塊"
anchor_left = 0.5
anchor_top = 0.0
anchor_right = 0.5
anchor_bottom = 0.0
offset_left = -200.0
offset_top = 270.0
offset_right = 200.0
offset_bottom = 290.0
horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
vertical_alignment = VERTICAL_ALIGNMENT_CENTER

# 字體設定
add_theme_font_size_override("font_size", 20)
add_theme_color_override("font_color", Color(0.8, 0.8, 0.8)) # #CCCCCC
```

##### NavigationGrid (Control)
```gdscript
anchor_left = 0.5
anchor_top = 0.0
anchor_right = 0.5
anchor_bottom = 0.0
offset_left = -300.0  # 600px 寬度的一半
offset_top = 500.0
offset_right = 300.0
offset_bottom = 1100.0
size = Vector2(600, 600)
```

##### GridContainer (GridContainer)
```gdscript
columns = 3
add_theme_constant_override("h_separation", 20)
add_theme_constant_override("v_separation", 20)
anchor_left = 0.0
anchor_top = 0.0
anchor_right = 1.0
anchor_bottom = 1.0
```

##### CenterSlot (Control + DropZone 腳本)
```gdscript
# Control 屬性
custom_minimum_size = Vector2(200, 200)

# DropZone 腳本屬性
@export var accepted_tile_types: Array[String] = ["navigation"]
@export var zone_type: String = "main_navigation"

# 視覺樣式
var style_box = StyleBoxFlat.new()
style_box.bg_color = Color(0.0, 0.0, 0.0, 0.67) # #000000AA
style_box.corner_radius_top_left = 20
style_box.corner_radius_top_right = 20
style_box.corner_radius_bottom_left = 20
style_box.corner_radius_bottom_right = 20
style_box.border_width_left = 2
style_box.border_width_right = 2
style_box.border_width_top = 2
style_box.border_width_bottom = 2
style_box.border_color = Color(1.0, 0.843, 0.0) # #FFD700 發光邊框
add_theme_stylebox_override("panel", style_box)
```

##### BattleTile (Control + DraggableTile + NavigationTile 腳本)
```gdscript
# Control 屬性
size = Vector2(200, 200)
position = Vector2(140, 1620)

# DraggableTile 腳本屬性
@export var tile_type: String = "navigation"
@export var tile_data: Dictionary = {"function": "battle"}
@export var return_on_invalid_drop: bool = true

# NavigationTile 腳本屬性
@export var target_scene_path: String = "res://scenes/LevelSelection.tscn"
@export var navigation_data: Dictionary = {"scene_name": "level_selection"}

# 視覺設定
func _ready():
    setup_battle_tile_style()

func setup_battle_tile_style():
    var style_box = StyleBoxFlat.new()
    
    # 線性漸層背景 #FF4444 → #CC2222
    style_box.bg_color = Color(1.0, 0.267, 0.267) # #FF4444
    # Godot 4.x 漸層設定
    var gradient = Gradient.new()
    gradient.add_point(0.0, Color(1.0, 0.267, 0.267))  # #FF4444
    gradient.add_point(1.0, Color(0.8, 0.133, 0.133))   # #CC2222
    
    # 圓角設定
    style_box.corner_radius_top_left = 16
    style_box.corner_radius_top_right = 16
    style_box.corner_radius_bottom_left = 16
    style_box.corner_radius_bottom_right = 16
    
    # 邊框設定
    style_box.border_width_left = 4
    style_box.border_width_right = 4
    style_box.border_width_top = 4
    style_box.border_width_bottom = 4
    style_box.border_color = Color(0.667, 0.0, 0.0) # #AA0000
    
    # 陰影效果
    style_box.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
    style_box.shadow_size = 8
    
    add_theme_stylebox_override("panel", style_box)
    
    # 添加圖標和文字
    setup_battle_icon_and_text()

func setup_battle_icon_and_text():
    # 圖標 (TextureRect 或自定義繪製)
    var icon = TextureRect.new()
    icon.texture = preload("res://art/icons/sword_shield.png")
    icon.size = Vector2(60, 60)
    icon.position = Vector2(50, 30)  # 中央偏上 20px
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    add_child(icon)
    
    # 文字標籤
    var label = Label.new()
    label.text = "戰鬥"
    label.size = Vector2(160, 30)
    label.position = Vector2(0, 120)  # 底部中央偏上 20px
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color.WHITE)
    add_child(label)
```

### 4.2 關卡選擇 (LevelSelection.tscn)
```
LevelSelection (Control)
├── BackgroundLayer (CanvasLayer)
│   ├── ChapterInfo (Control)
│   │   ├── ChapterTitle (Label)
│   │   ├── ProgressBar (ProgressBar)
│   │   ├── LeftButton (Button)
│   │   └── RightButton (Button)
│   └── ConfirmationGrid (Control)
│       ├── GridContainer (GridContainer)
│       │   └── CenterConfirmSlot (Control + DropZone)
│       └── GridHighlight (NinePatchRect)
├── InteractionLayer (CanvasLayer)
│   ├── LevelTileContainer (ScrollContainer)
│   │   └── HBoxContainer (HBoxContainer)
│   │       ├── Level1Tile (Control + LevelTile)
│   │       ├── Level2Tile (Control + LevelTile)
│   │       └── ...
│   └── BackTile (Control + ActionTile)
└── InfoLayer (CanvasLayer)
    ├── LevelDetailPopup (PopupPanel)
    └── DragPreview (Control)
```

#### 4.2.1 具體節點屬性設定

##### ChapterTitle (Label)
```gdscript
text = "第一章：初始試煉"
position = Vector2(80, 60)
size = Vector2(800, 40)
add_theme_font_size_override("font_size", 28)
add_theme_color_override("font_color", Color.WHITE)
add_theme_font_override("font", bold_font_resource)
```

##### ProgressBar (ProgressBar)
```gdscript
position = Vector2(80, 110)
size = Vector2(920, 20)
min_value = 0.0
max_value = 5.0
value = 3.0  # 3/5 完成

# 自定義樣式
var bg_style = StyleBoxFlat.new()
bg_style.bg_color = Color(0.2, 0.2, 0.2)  # #333333
bg_style.corner_radius_top_left = 10
bg_style.corner_radius_top_right = 10
bg_style.corner_radius_bottom_left = 10
bg_style.corner_radius_bottom_right = 10
add_theme_stylebox_override("background", bg_style)

var fill_style = StyleBoxFlat.new()
fill_style.bg_color = Color(0.267, 0.667, 0.267)  # #44AA44
fill_style.corner_radius_top_left = 10
fill_style.corner_radius_top_right = 10
fill_style.corner_radius_bottom_left = 10
fill_style.corner_radius_bottom_right = 10
add_theme_stylebox_override("fill", fill_style)
```

##### ConfirmationGrid (Control)
```gdscript
position = Vector2(290, 250)
size = Vector2(500, 400)

# 背景樣式
var style_box = StyleBoxFlat.new()
# 漸層藍色背景 #1a237e → #283593
style_box.bg_color = Color(0.102, 0.137, 0.494)  # #1a237e
var gradient = Gradient.new()
gradient.add_point(0.0, Color(0.102, 0.137, 0.494))  # #1a237e
gradient.add_point(1.0, Color(0.157, 0.208, 0.576))  # #283593

style_box.corner_radius_top_left = 25
style_box.corner_radius_top_right = 25
style_box.corner_radius_bottom_left = 25
style_box.corner_radius_bottom_right = 25
add_theme_stylebox_override("panel", style_box)
```

##### LevelTileContainer (ScrollContainer)
```gdscript
position = Vector2(40, 750)
size = Vector2(1000, 200)  # 可視區域高度 200px
scroll_horizontal_enabled = true
scroll_vertical_enabled = false

# 滾動條樣式
var scrollbar_style = StyleBoxFlat.new()
scrollbar_style.bg_color = Color(0.3, 0.3, 0.3, 0.8)
add_theme_stylebox_override("scroll", scrollbar_style)
```

##### Level1Tile (Control + LevelTile 腳本)
```gdscript
# Control 屬性
size = Vector2(200, 200)
custom_minimum_size = Vector2(200, 200)

# LevelTile 腳本屬性
@export var level_id: String = "level_001"
@export var is_unlocked: bool = true
@export var completion_stars: int = 2

# 可挑戰狀態樣式
func setup_available_style():
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color.WHITE
    style_box.border_width_left = 2
    style_box.border_width_right = 2
    style_box.border_width_top = 2
    style_box.border_width_bottom = 2
    style_box.border_color = Color(0.8, 0.8, 0.8)  # #CCCCCC
    style_box.corner_radius_top_left = 12
    style_box.corner_radius_top_right = 12
    style_box.corner_radius_bottom_left = 12
    style_box.corner_radius_bottom_right = 12
    add_theme_stylebox_override("panel", style_box)
    
    # 關卡編號
    var number_label = Label.new()
    number_label.text = "1"
    number_label.size = Vector2(200, 200)
    number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    number_label.add_theme_font_size_override("font_size", 32)
    number_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
    number_label.add_theme_font_override("font", bold_font_resource)
    add_child(number_label)
    
    # 敵人預覽 (右上角)
    var enemy_preview = TextureRect.new()
    enemy_preview.texture = preload("res://art/enemies/slime_preview.png")
    enemy_preview.size = Vector2(30, 30)
    enemy_preview.position = Vector2(140, 40)
    add_child(enemy_preview)
```

### 4.3 戰鬥場景 (Battle.tscn)
```
Battle (Control)
├── BackgroundLayer (CanvasLayer)
│   ├── EnemyPanel (Control)
│   │   ├── EnemySprite (TextureRect)
│   │   ├── ElementIcon (TextureRect) 
│   │   ├── HPBar (ProgressBar)
│   │   └── CountdownLabel (Label)
│   ├── BoardRoot (Control)
│   │   ├── GridContainer (GridContainer)
│   │   │   ├── GridSlot_0_0 (Control + BoardTile)
│   │   │   ├── GridSlot_0_1 (Control + BoardTile)
│   │   │   └── ... (81個格子)
│   │   ├── PlacedTiles (Control)
│   │   └── HighlightOverlay (Control)
│   └── TileBagPanel (Control)
│       ├── TileSlot1 (Control + DraggableTile)
│       ├── TileSlot2 (Control + DraggableTile)
│       ├── TileSlot3 (Control + DraggableTile)
│       └── TileSlot4 (Control + DraggableTile)
├── InteractionLayer (CanvasLayer)
│   ├── ActionPanel (Control)
│   │   ├── SubmitButton (Button)
│   │   ├── ComboDisplay (Label)
│   │   ├── TurnMessage (Label)
│   │   └── SettingsButton (Button)
│   └── DragPreview (Control)
└── FloatingLayer (CanvasLayer)
    ├── DamageBreakdownPopup (PopupPanel)
    └── MessagePopup (AcceptDialog)
```

#### 4.3.1 具體節點屬性設定

##### EnemySprite (TextureRect)
```gdscript
texture = preload("res://art/enemies/slime_001.png")
size = Vector2(200, 200)
position = Vector2(50, 50)  # 在 150,150 中心對齊
stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

# 圓形遮罩效果
material = preload("res://materials/CircleMask.tres")

# 邊框效果 (使用 NinePatchRect 覆蓋)
var border_frame = NinePatchRect.new()
border_frame.size = Vector2(208, 208)  # 200 + 4px 邊框 * 2
border_frame.position = Vector2(-4, -4)
var border_style = StyleBoxFlat.new()
border_style.border_width_left = 4
border_style.border_width_right = 4
border_style.border_width_top = 4
border_style.border_width_bottom = 4
border_style.border_color = Color(1.0, 0.843, 0.0)  # #FFD700
add_child(border_frame)
```

##### HPBar (ProgressBar)
```gdscript
position = Vector2(400, 100)
size = Vector2(600, 40)
min_value = 0.0
max_value = 1200.0  # 最大 HP
value = 800.0       # 當前 HP

# 背景樣式
var bg_style = StyleBoxFlat.new()
bg_style.bg_color = Color(0.2, 0.2, 0.2)  # #333333
bg_style.corner_radius_top_left = 20
bg_style.corner_radius_top_right = 20
bg_style.corner_radius_bottom_left = 20
bg_style.corner_radius_bottom_right = 20
add_theme_stylebox_override("background", bg_style)

# 血條樣式
var fill_style = StyleBoxFlat.new()
fill_style.bg_color = Color(1.0, 0.267, 0.267)  # #FF4444
fill_style.corner_radius_top_left = 20
fill_style.corner_radius_top_right = 20
fill_style.corner_radius_bottom_left = 20
fill_style.corner_radius_bottom_right = 20
add_theme_stylebox_override("fill", fill_style)

# HP 數值文字覆蓋
var hp_label = Label.new()
hp_label.text = "800 / 1200"
hp_label.size = Vector2(600, 40)
hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
hp_label.add_theme_font_size_override("font_size", 18)
hp_label.add_theme_color_override("font_color", Color.WHITE)
add_child(hp_label)
```

##### CountdownLabel (Label)
```gdscript
text = "3"
position = Vector2(840, 120)  # 900,180 中心對齊，尺寸 120x120
size = Vector2(120, 120)
horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
vertical_alignment = VERTICAL_ALIGNMENT_CENTER

# 字體設定
add_theme_font_size_override("font_size", 48)
add_theme_color_override("font_color", Color.WHITE)
add_theme_font_override("font", bold_font_resource)

# 圓形背景
var style_box = StyleBoxFlat.new()
style_box.bg_color = Color(1.0, 0.533, 0.0)  # #FF8800
style_box.corner_radius_top_left = 60  # 半圓
style_box.corner_radius_top_right = 60
style_box.corner_radius_bottom_left = 60
style_box.corner_radius_bottom_right = 60
add_theme_stylebox_override("normal", style_box)
```

##### BoardRoot GridContainer (GridContainer)
```gdscript
position = Vector2(240, 1000)
size = Vector2(600, 600)
columns = 3
add_theme_constant_override("h_separation", 0)
add_theme_constant_override("v_separation", 0)

# 背景
var bg_style = StyleBoxFlat.new()
bg_style.bg_color = Color(0.18, 0.18, 0.18)  # #2E2E2E
bg_style.border_width_left = 4
bg_style.border_width_right = 4
bg_style.border_width_top = 4
bg_style.border_width_bottom = 4
bg_style.border_color = Color(0.33, 0.33, 0.33)  # #555555
add_theme_stylebox_override("panel", bg_style)
```

##### GridSlot (Control + BoardTile 腳本)
```gdscript
# Control 屬性
custom_minimum_size = Vector2(94, 94)
size = Vector2(94, 94)

# BoardTile 腳本屬性
@export var grid_x: int = 0
@export var grid_y: int = 0  
@export var is_blocked: bool = false
@export var is_occupied: bool = false

# 空格狀態樣式
func setup_empty_style():
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color(0.96, 0.96, 0.96)  # #F5F5F5
    style_box.border_width_left = 1
    style_box.border_width_right = 1
    style_box.border_width_top = 1
    style_box.border_width_bottom = 1
    style_box.border_color = Color(0.87, 0.87, 0.87)  # #DDDDDD
    style_box.corner_radius_top_left = 6
    style_box.corner_radius_top_right = 6
    style_box.corner_radius_bottom_left = 6
    style_box.corner_radius_bottom_right = 6
    add_theme_stylebox_override("panel", style_box)

# 障礙格狀態樣式  
func setup_blocked_style():
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color(0.2, 0.2, 0.2)  # #333333
    # 斜線紋理需要自定義繪製或使用 TextureRect
    add_theme_stylebox_override("panel", style_box)
    
    # 斜線紋理 (使用自定義繪製)
    queue_redraw()

func _draw():
    if is_blocked:
        # 繪製 45度斜線紋理
        var line_color = Color(0.4, 0.4, 0.4)  # #666666
        for i in range(0, int(size.x + size.y), 8):
            var start = Vector2(i, 0)
            var end = Vector2(i - size.y, size.y)
            if start.x > size.x:
                start = Vector2(size.x, i - size.x)
            if end.x < 0:
                end = Vector2(0, i)
            draw_line(start, end, line_color, 1.0)

# 高亮狀態
func set_highlight(valid: bool):
    if valid:
        # 可放置高亮
        var highlight_style = StyleBoxFlat.new()
        highlight_style.bg_color = Color(0.267, 1.0, 0.267, 0.25)  # #44FF4440
        highlight_style.border_width = 2
        highlight_style.border_color = Color(0.267, 1.0, 0.267)  # #44FF44
        add_theme_stylebox_override("panel", highlight_style)
    else:
        # 無效區域高亮
        var invalid_style = StyleBoxFlat.new()
        invalid_style.bg_color = Color(1.0, 0.267, 0.267, 0.25)  # #FF444440
        invalid_style.border_width = 2
        invalid_style.border_color = Color(1.0, 0.267, 0.267)  # #FF4444
        add_theme_stylebox_override("panel", invalid_style)
```

##### SubmitButton (Button)
```gdscript
text = "送出"
position = Vector2(400, 1450)
size = Vector2(280, 80)

# 按鈕樣式
var normal_style = StyleBoxFlat.new()
normal_style.bg_color = Color(1.0, 0.4, 0.0)  # #FF6600
normal_style.corner_radius_top_left = 40
normal_style.corner_radius_top_right = 40
normal_style.corner_radius_bottom_left = 40
normal_style.corner_radius_bottom_right = 40
add_theme_stylebox_override("normal", normal_style)

# 按下樣式
var pressed_style = StyleBoxFlat.new()
pressed_style.bg_color = Color(0.8, 0.32, 0.0)  # 暗一點的橙色
pressed_style.corner_radius_top_left = 40
pressed_style.corner_radius_top_right = 40
pressed_style.corner_radius_bottom_left = 40
pressed_style.corner_radius_bottom_right = 40
add_theme_stylebox_override("pressed", pressed_style)

# 字體設定
add_theme_font_size_override("font_size", 28)
add_theme_color_override("font_color", Color.WHITE)
add_theme_font_override("font", bold_font_resource)
```

### 4.4 結算畫面 (Result.tscn)
```
Result (Control)
├── BackgroundLayer (CanvasLayer)
│   ├── TitleLabel (Label)
│   ├── StarsContainer (Control)
│   │   ├── Star1 (TextureRect)
│   │   ├── Star2 (TextureRect)
│   │   └── Star3 (TextureRect)
│   ├── ScoreLabel (Label)
│   └── BestScoreLabel (Label)
├── InteractionLayer (CanvasLayer)
│   ├── RetryButton (Button)
│   ├── NextLevelButton (Button)
│   └── MainMenuButton (Button)
└── EffectLayer (CanvasLayer)
    ├── ParticleEffect (CPUParticles2D)
    └── TransitionEffect (ColorRect + AnimationPlayer)
```

#### 4.4.1 具體節點屬性設定

##### TitleLabel (Label)
```gdscript
text = "關卡結束"
position = Vector2(100, 50)
size = Vector2(800, 40)
horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
vertical_alignment = VERTICAL_ALIGNMENT_CENTER

# 字體設定
add_theme_font_size_override("font_size", 36)
add_theme_color_override("font_color", Color(1.0, 0.843, 0.0)) # #FFD700
add_theme_font_override("font", bold_font_resource)
```

##### StarsContainer (Control)
```gdscript
position = Vector2(400, 150)
size = Vector2(600, 100)
anchor_left = 0.5
anchor_top = 0.0
anchor_right = 0.5
anchor_bottom = 0.0
```

##### Star1 (TextureRect)
```gdscript
texture = preload("res://art/ui/star.png")
size = Vector2(64, 64)
position = Vector2(0, 0)
stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
```

##### ScoreLabel (Label)
```gdscript
text = "分數: 100"
position = Vector2(100, 300)
size = Vector2(800, 40)
horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
vertical_alignment = VERTICAL_ALIGNMENT_CENTER

# 字體設定
add_theme_font_size_override("font_size", 28)
add_theme_color_override("font_color", Color.WHITE)
```

##### RetryButton (Button)
```gdscript
text = "重試"
position = Vector2(250, 800)
size = Vector2(200, 60)

# 按鈕樣式
var normal_style = StyleBoxFlat.new()
normal_style.bg_color = Color(0.267, 0.533, 1.0)  # #4488FF
normal_style.corner_radius_top_left = 30
normal_style.corner_radius_top_right = 30
normal_style.corner_radius_bottom_left = 30
normal_style.corner_radius_bottom_right = 30
add_theme_stylebox_override("normal", normal_style)

# 字體設定
add_theme_font_size_override("font_size", 24)
add_theme_color_override("font_color", Color.WHITE)
add_theme_font_override("font", bold_font_resource)
```

## 5. 拖放系統核心組件
### 5.1 DragDropManager.gd (AutoLoad)
```gdscript
extends Node

signal tile_drag_started(tile_data: Dictionary, source_scene: String)
signal tile_drag_ended(tile_data: Dictionary, drop_zone: DropZone, success: bool)
signal navigation_requested(target_scene: String, tile_type: String)

var current_dragging_tile: DraggableTile = null
var valid_drop_zones: Array[DropZone] = []
var drag_preview: Control = null
var drag_offset: Vector2 = Vector2.ZERO

func start_drag(tile: DraggableTile, global_pos: Vector2):
    if current_dragging_tile != null:
        return false
        
    current_dragging_tile = tile
    drag_offset = tile.global_position - global_pos
    
    # 創建拖拽預覽
    create_drag_preview(tile)
    
    # 設置原圖塊為半透明
    tile.modulate.a = 0.5
    
    # 發送開始拖拽訊號
    tile_drag_started.emit(tile.tile_data, get_tree().current_scene.scene_file_path)
    
    return true

func create_drag_preview(original_tile: DraggableTile):
    drag_preview = Control.new()
    drag_preview.size = original_tile.size
    drag_preview.modulate.a = 0.9
    
    # 複製原圖塊的外觀
    var preview_bg = NinePatchRect.new()
    preview_bg.size = original_tile.size
    
    # 複製樣式 (簡化版)
    var style = original_tile.get_theme_stylebox("panel").duplicate()
    preview_bg.add_theme_stylebox_override("panel", style)
    
    # 添加陰影效果
    var shadow = ColorRect.new()
    shadow.color = Color(0, 0, 0, 0.3)
    shadow.size = original_tile.size + Vector2(24, 24)  # 12px blur * 2
    shadow.position = Vector2(-12, -12)
    shadow.z_index = -1
    
    drag_preview.add_child(shadow)
    drag_preview.add_child(preview_bg)
    
    # 縮放效果
    drag_preview.scale = Vector2(1.1, 1.1)
    
    # 添加到場景樹
    get_tree().current_scene.add_child(drag_preview)

func update_drag(global_pos: Vector2):
    if drag_preview == null:
        return
        
    drag_preview.global_position = global_pos + drag_offset
    
    # 檢測碰撞的投放區域
    var drop_zone = find_drop_zone_at_position(global_pos)
    update_drop_zone_highlights(drop_zone)

func find_drop_zone_at_position(global_pos: Vector2) -> DropZone:
    for zone in valid_drop_zones:
        if zone.global_rect.has_point(global_pos):
            return zone
    return null

func update_drop_zone_highlights(hovered_zone: DropZone):
    for zone in valid_drop_zones:
        if zone == hovered_zone:
            if can_drop_on_zone(current_dragging_tile, zone):
                zone.set_highlight_valid(true)
            else:
                zone.set_highlight_invalid(true) 
        else:
            zone.clear_highlight()

func end_drag(global_pos: Vector2) -> bool:
    if current_dragging_tile == null:
        return false
        
    var drop_zone = find_drop_zone_at_position(global_pos)
    var success = false
    
    if drop_zone != null and can_drop_on_zone(current_dragging_tile, drop_zone):
        # 成功投放
        success = true
        perform_drop_action(current_dragging_tile, drop_zone)
        play_drop_success_animation()
    else:
        # 失敗，回彈動畫
        play_drop_fail_animation()
    
    # 清理
    cleanup_drag()
    
    tile_drag_ended.emit(current_dragging_tile.tile_data, drop_zone, success)
    current_dragging_tile = null
    
    return success

func cleanup_drag():
    if current_dragging_tile:
        current_dragging_tile.modulate.a = 1.0
        
    if drag_preview:
        drag_preview.queue_free()
        drag_preview = null
        
    # 清除所有高亮
    for zone in valid_drop_zones:
        zone.clear_highlight()

func play_drop_success_animation():
    if drag_preview == null:
        return
        
    # 縮放動畫：1.2 → 1.0，持續 0.3秒
    var tween = create_tween()
    tween.tween_property(drag_preview, "scale", Vector2(1.2, 1.2), 0.1)
    tween.tween_property(drag_preview, "scale", Vector2(1.0, 1.0), 0.2)
    
    # 粒子效果 (簡化版)
    create_success_particles(drag_preview.global_position)

func play_drop_fail_animation():
    if current_dragging_tile == null:
        return
        
    # 回彈動畫
    var tween = create_tween()
    var original_pos = current_dragging_tile.global_position
    var current_pos = drag_preview.global_position if drag_preview else original_pos
    
    # 彈性回到原位置
    tween.tween_method(
        func(pos): if drag_preview: drag_preview.global_position = pos,
        current_pos,
        original_pos,
        0.5
    )
    tween.tween_callback(cleanup_drag)

func can_drop_on_zone(tile: DraggableTile, zone: DropZone) -> bool:
    return zone.can_accept_tile(tile)

func perform_drop_action(tile: DraggableTile, zone: DropZone):
    zone.on_tile_dropped(tile.tile_data)
    
    # 處理導航圖塊
    if tile is NavigationTile:
        var nav_tile = tile as NavigationTile
        if nav_tile.target_scene_path != "":
            navigation_requested.emit(nav_tile.target_scene_path, tile.tile_type)

func create_success_particles(position: Vector2):
    # 創建簡單的粒子效果
    for i in range(20):
        var particle = ColorRect.new()
        particle.size = Vector2(4, 4)
        particle.color = Color(1, 1, 0, 0.8)  # 黃色
        particle.position = position
        get_tree().current_scene.add_child(particle)
        
        # 隨機方向擴散
        var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
        var distance = randf_range(50, 100)
        
        var tween = create_tween()
        tween.tween_property(particle, "position", position + direction * distance, 0.5)
        tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
        tween.tween_callback(particle.queue_free)
```

### 5.2 DraggableTile.gd (基類)
```gdscript
class_name DraggableTile
extends Control

signal drag_started()
signal drag_ended(success: bool)

@export var tile_type: String = ""
@export var tile_data: Dictionary = {}
@export var return_on_invalid_drop: bool = true

var is_dragging: bool = false

func _ready():
    gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent):
    if event is InputEventScreenTouch:
        var touch_event = event as InputEventScreenTouch
        
        if touch_event.pressed and not is_dragging:
            # 開始拖拽
            start_dragging(touch_event.position)
        elif not touch_event.pressed and is_dragging:
            # 結束拖拽
            end_dragging(touch_event.position)
            
    elif event is InputEventScreenDrag and is_dragging:
        # 拖拽過程
        update_dragging(event.position)

func start_dragging(local_pos: Vector2):
    var global_pos = global_position + local_pos
    
    if DragDropManager.start_drag(self, global_pos):
        is_dragging = true
        drag_started.emit()

func update_dragging(local_pos: Vector2):
    var global_pos = global_position + local_pos
    DragDropManager.update_drag(global_pos)

func end_dragging(local_pos: Vector2):
    var global_pos = global_position + local_pos
    var success = DragDropManager.end_drag(global_pos)
    
    is_dragging = false
    drag_ended.emit(success)

# 可被子類重寫的方法
func on_drag_started():
    pass

func on_drag_ended(success: bool):
    pass
```

### 5.3 DropZone.gd (基類)
```gdscript
class_name DropZone
extends Control

signal tile_dropped(tile_data: Dictionary)
signal tile_hover_enter(tile_data: Dictionary)
signal tile_hover_exit()

@export var accepted_tile_types: Array[String] = []
@export var zone_type: String = ""

var highlight_overlay: ColorRect

func _ready():
    # 創建高亮覆蓋層
    highlight_overlay = ColorRect.new()
    highlight_overlay.size = size
    highlight_overlay.color = Color.TRANSPARENT
    highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(highlight_overlay)
    
    # 註冊到拖放管理器
    DragDropManager.valid_drop_zones.append(self)

func _exit_tree():
    # 從管理器中移除
    if self in DragDropManager.valid_drop_zones:
        DragDropManager.valid_drop_zones.erase(self)

func can_accept_tile(tile: DraggableTile) -> bool:
    if accepted_tile_types.is_empty():
        return true
    return tile.tile_type in accepted_tile_types

func set_highlight_valid(enabled: bool):
    if enabled:
        highlight_overlay.color = Color(0.267, 1.0, 0.267, 0.25)  # #44FF4440
        # 邊框效果
        var style = StyleBoxFlat.new()
        style.border_width = 4
        style.border_color = Color(0.267, 1.0, 0.267)  # #44FF44
        add_theme_stylebox_override("panel", style)
        
        # 脈動動畫
        start_pulse_animation()

func set_highlight_invalid(enabled: bool):
    if enabled:
        highlight_overlay.color = Color(1.0, 0.267, 0.267, 0.25)  # #FF444440
        var style = StyleBoxFlat.new()
        style.border_width = 4
        style.border_color = Color(1.0, 0.267, 0.267)  # #FF4444
        add_theme_stylebox_override("panel", style)

func clear_highlight():
    highlight_overlay.color = Color.TRANSPARENT
    remove_theme_stylebox_override("panel")

func start_pulse_animation():
    var tween = create_tween()
    tween.set_loops()
    tween.tween_property(highlight_overlay, "modulate:a", 0.5, 0.5)
    tween.tween_property(highlight_overlay, "modulate:a", 1.0, 0.5)

func on_tile_dropped(tile_data: Dictionary):
    tile_dropped.emit(tile_data)
    # 可被子類重寫以執行特定邏輯
```

## 6. 特化組件
### 6.1 NavigationTile.gd (導航圖塊)
```gdscript
class_name NavigationTile
extends DraggableTile

@export var target_scene_path: String = ""
@export var navigation_data: Dictionary = {}

func _ready():
    super._ready()
    tile_type = "navigation"

func on_drag_ended(success: bool):
    super.on_drag_ended(success)
    
    if success and target_scene_path != "":
        # 延遲切換場景，讓動畫完成
        await get_tree().create_timer(0.5).timeout
        get_tree().change_scene_to_file(target_scene_path)
```

### 6.2 LevelTile.gd (關卡圖塊)
```gdscript
class_name LevelTile
extends DraggableTile

@export var level_id: String = ""
@export var is_unlocked: bool = false
@export var completion_stars: int = 0

func _ready():
    super._ready()
    tile_type = "level"
    tile_data = {
        "level_id": level_id,
        "is_unlocked": is_unlocked,
        "completion_stars": completion_stars
    }
    
    setup_visual_state()

func setup_visual_state():
    if is_unlocked:
        if completion_stars > 0:
            setup_completed_style()
        else:
            setup_available_style()
    else:
        setup_locked_style()

func setup_completed_style():
    # 已完成樣式（如前面所示）
    pass

func setup_available_style():
    # 可挑戰樣式（如前面所示）
    pass

func setup_locked_style():
    # 未解鎖樣式
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color(0.96, 0.96, 0.96)  # #F5F5F5
    style_box.border_width = 2
    style_box.border_color = Color(0.6, 0.6, 0.6)  # #999999
    add_theme_stylebox_override("panel", style_box)
    
    modulate.a = 0.6
    
    # 鎖定圖標
    var lock_icon = TextureRect.new()
    lock_icon.texture = preload("res://art/icons/lock.png")
    lock_icon.size = Vector2(40, 40)
    lock_icon.position = Vector2(70, 70)  # 中央
    add_child(lock_icon)
```

### 6.3 ActionTile.gd (行動圖塊)
```gdscript
class_name ActionTile
extends DraggableTile

@export var action_type: String = "" # "retry", "continue", "back", "share"
@export var action_data: Dictionary = {}

func _ready():
    super._ready()
    tile_type = "action"
    tile_data = {
        "action_type": action_type,
        "action_data": action_data
    }
    
    setup_action_style()

func setup_action_style():
    match action_type:
        "retry":
            setup_retry_style()
        "continue":
            setup_continue_style()
        "back":
            setup_back_style()
        "share":
            setup_share_style()

func setup_retry_style():
    # 重試圖塊樣式（橙色）
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color(1.0, 0.533, 0.0)  # #FF8800
    style_box.corner_radius_top_left = 20
    style_box.corner_radius_top_right = 20
    style_box.corner_radius_bottom_left = 20
    style_box.corner_radius_bottom_right = 20
    add_theme_stylebox_override("panel", style_box)

func setup_continue_style():
    # 繼續圖塊樣式（綠色）
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color(0.267, 0.667, 0.267)  # #44AA44
    style_box.corner_radius_top_left = 20
    style_box.corner_radius_top_right = 20
    style_box.corner_radius_bottom_left = 20
    style_box.corner_radius_bottom_right = 20
    add_theme_stylebox_override("panel", style_box)

func setup_back_style():
    # 返回圖塊樣式（藍色）
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color(0.267, 0.533, 1.0)  # #4488FF
    style_box.corner_radius_top_left = 20
    style_box.corner_radius_top_right = 20
    style_box.corner_radius_bottom_left = 20
    style_box.corner_radius_bottom_right = 20
    add_theme_stylebox_override("panel", style_box)

func setup_share_style():
    # 分享圖塊樣式（紫色）
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color(0.667, 0.267, 1.0)  # #AA44FF
    style_box.corner_radius_top_left = 20
    style_box.corner_radius_top_right = 20
    style_box.corner_radius_bottom_left = 20
    style_box.corner_radius_bottom_right = 20
    add_theme_stylebox_override("panel", style_box)
```

### 6.4 BoardTile.gd (棋盤格)
```gdscript
class_name BoardTile
extends Control

@export var grid_x: int = 0
@export var grid_y: int = 0  
@export var is_blocked: bool = false
@export var is_occupied: bool = false

func _ready():
    setup_empty_style()

# 空格狀態樣式
func setup_empty_style():
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color(0.96, 0.96, 0.96)  # #F5F5F5
    style_box.border_width_left = 1
    style_box.border_width_right = 1
    style_box.border_width_top = 1
    style_box.border_width_bottom = 1
    style_box.border_color = Color(0.87, 0.87, 0.87)  # #DDDDDD
    style_box.corner_radius_top_left = 6
    style_box.corner_radius_top_right = 6
    style_box.corner_radius_bottom_left = 6
    style_box.corner_radius_bottom_right = 6
    add_theme_stylebox_override("panel", style_box)

# 障礙格狀態樣式  
func setup_blocked_style():
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color(0.2, 0.2, 0.2)  # #333333
    # 斜線紋理需要自定義繪製或使用 TextureRect
    add_theme_stylebox_override("panel", style_box)
    
    # 斜線紋理 (使用自定義繪製)
    queue_redraw()

func _draw():
    if is_blocked:
        # 繪製 45度斜線紋理
        var line_color = Color(0.4, 0.4, 0.4)  # #666666
        for i in range(0, int(size.x + size.y), 8):
            var start = Vector2(i, 0)
            var end = Vector2(i - size.y, size.y)
            if start.x > size.x:
                start = Vector2(size.x, i - size.x)
            if end.x < 0:
                end = Vector2(0, i)
            draw_line(start, end, line_color, 1.0)

# 高亮狀態
func set_highlight(valid: bool):
    if valid:
        # 可放置高亮
        var highlight_style = StyleBoxFlat.new()
        highlight_style.bg_color = Color(0.267, 1.0, 0.267, 0.25)  # #44FF4440
        highlight_style.border_width = 2
        highlight_style.border_color = Color(0.267, 1.0, 0.267)  # #44FF44
        add_theme_stylebox_override("panel", highlight_style)
    else:
        # 無效區域高亮
        var invalid_style = StyleBoxFlat.new()
        invalid_style.bg_color = Color(1.0, 0.267, 0.267, 0.25)  # #FF444440
        invalid_style.border_width = 2
        invalid_style.border_color = Color(1.0, 0.267, 0.267)  # #FF4444
        add_theme_stylebox_override("panel", invalid_style)
```

### 6.5 HeroTile/BlockTile（八個凸塊+一英雄）
```gdscript
# HeroTile.gd
class_name HeroTile
extends Control

@export var hero_id: String = "hero_01"
@export var position_index: int = 0  # 0-8 對應 3x3 網格

func _ready():
    setup_hero_style()

func setup_hero_style():
    # 英雄圖示
    var icon = TextureRect.new()
    icon.texture = preload("res://art/heroes/" + hero_id + ".png")
    icon.size = Vector2(64, 64)
    icon.position = Vector2(15, 15)
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    add_child(icon)
    
    # 英雄編號
    var number_label = Label.new()
    number_label.text = str(position_index + 1)
    number_label.size = Vector2(64, 64)
    number_label.position = Vector2(0, 0)
    number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    number_label.add_theme_font_size_override("font_size", 24)
    number_label.add_theme_color_override("font_color", Color.WHITE)
    add_child(number_label)
```

## 7. 純代碼實現建議
### 7.1 英雄與凸塊圖塊（純代碼）
- 用不同顏色的 ColorRect/StyleBoxFlat 代表八種凸塊
- 用 Label 顯示凸塊編號或屬性文字
- 主英雄用較大尺寸、特殊顏色或加粗邊框區分
- 範例 GDScript 實現
```gdscript
# MainScene.gd
extends Node2D

func _ready():
    # 創建棋盤格
    for x in range(3):
        for y in range(3):
            var tile = BoardTile.new()
            tile.position = Vector2(x, y) * 100
            add_child(tile)
            
            # 設定凸塊顏色
            if x == 1 and y == 1:
                # 中央為主英雄
                tile.modulate = Color(1, 0.8, 0.8)
                tile.add_child(HeroTile.new())
            else:
                # 其他為普通凸塊
                tile.modulate = Color(0.8, 0.8, 1)
            
            tile.set_process(true)
```

## 8. 開發檢查清單
- 場景創建檢查
- 拖放系統檢查
- 視覺效果檢查
- 場景切換檢查

---