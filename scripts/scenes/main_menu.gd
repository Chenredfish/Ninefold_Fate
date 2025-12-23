extends Control

var logo: Label
var subtitle: Label
var intro_label: Label
var version_label: Label

var unified_confirm_grid: Control
var confirm_label: Label

var scroll_tile_container: ScrollContainer
var tile_container: HBoxContainer
var battle_tile: NavigationTile
var shop_tile: NavigationTile
var deck_tile: NavigationTile
var settings_tile: NavigationTile

func _ready():
	print("[MainMenu] Main menu scene loaded")
	
	create_background()
	
	create_upper_UI() #在(0,0)~(1080, 1000)
	create_middle_UI() #在(240,1000)~(840, 1600)
	create_lower_UI() #在(0,1600)~(1080, 1920)
	
	print("[MainMenu] Main menu setup complete")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F9:
			print_debug_info()

func print_debug_info():
	print("\n=== MAIN MENU DEBUG INFO ===")
	print("Current Scene: ", get_tree().current_scene.name if get_tree().current_scene else "None")
	print("Parent: ", get_parent().name if get_parent() else "None")
	
	if StateManager:
		print("StateManager: Available")
		if StateManager.game_scene_state_machine:
			var gsm = StateManager.game_scene_state_machine
			print("- Current State: ", gsm.get_current_state_id() if gsm.has_method("get_current_state_id") else "Unknown")
			print("- Current Scene: ", gsm.current_scene.name if gsm.current_scene else "None")
	print("=== END DEBUG INFO ===\n")

func create_background():
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0.1, 0.1, 0.2, 1.0)
	add_child(bg)

func create_upper_UI():
	#製作logo
	logo = Label.new()
	logo.text = "Nine Folds Fate"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	logo.size_flags_vertical = Control.SIZE_FILL
	logo.custom_minimum_size = Vector2(1080, 200) # 寬度與畫面一致
	logo.position = Vector2(0, 200) # Y軸位置
	add_child(logo)
	logo.add_theme_font_size_override("font_size", 96)

	#新增副標題
	subtitle = Label.new()
	subtitle.text = "An Epic Adventure Awaits"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.size_flags_vertical = Control.SIZE_FILL
	subtitle.custom_minimum_size = Vector2(1080, 100) # 寬度與畫面一致
	subtitle.position = Vector2(0, 350) # 原本設定是300
	subtitle.add_theme_font_size_override("font_size", 48)
	add_child(subtitle)

	#新增遊戲介紹區塊
	intro_label = Label.new()
	intro_label.text = "Welcome to Nine Folds Fate! Embark on a thrilling journey through mystical lands, challenging battles, and strategic deck-building. Prepare yourself for an unforgettable adventure!"
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro_label.size_flags_vertical = Control.SIZE_FILL
	intro_label.custom_minimum_size = Vector2(1080, 200) # 寬度與畫面一致
	intro_label.position = Vector2(0, 500)
	intro_label.add_theme_font_size_override("font_size", 24)
	#文字過多要換行
	intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(intro_label)

	#新增版本資訊
	version_label = Label.new()
	version_label.text = "Version 0.1 Alpha"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	version_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	version_label.size_flags_vertical = Control.SIZE_FILL
	version_label.custom_minimum_size = Vector2(1080, 50) # 寬度與畫面一致
	version_label.position = Vector2(0, 1870) # 原本是 (1000, 950)，但前面已經設定對齊在右下角
	version_label.add_theme_font_size_override("font_size", 16)
	add_child(version_label)

func create_middle_UI():
	#創造棋盤的背景
	var grid_bg = ColorRect.new()
	grid_bg.position = Vector2(240, 800)
	grid_bg.size = Vector2(600, 600)
	grid_bg.color = Color(0.2, 0.2, 0.3, 1.0)
	add_child(grid_bg) 

	#參考create_confirm_grid
	unified_confirm_grid = Control.new()
	unified_confirm_grid.position = Vector2(240, 800)
	unified_confirm_grid.size = Vector2(600, 600)
	add_child(unified_confirm_grid)

	for i in range(3):
		for j in range(3):
			var drop_zone = DropZone.new()
			drop_zone.position = Vector2(j * 200, i * 200)
			drop_zone.size = Vector2(200, 200)
			drop_zone.zone_type = ""
			drop_zone.set_accepted_types(["level_select", "shop", "deck", "settings"])
			unified_confirm_grid.add_child(drop_zone)

			if i == 1 and j == 1:
				drop_zone.modulate = Color(1.2, 1.2, 1.0, 1.0)
				drop_zone.tile_dropped.connect(_on_start_tile_dropped)

	confirm_label = Label.new()
	confirm_label.text = "Drag start tile here to begin"
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.custom_minimum_size = Vector2(600, 40)
	confirm_label.position = Vector2(0, 600) # 在中央格子下方
	confirm_label.add_theme_font_size_override("font_size", 20)
	confirm_label.add_theme_color_override("font_color", Color.WHITE)
	unified_confirm_grid.add_child(confirm_label)

func create_lower_UI():
	#新增容器去裝tile，總共四個tile，每一個tile200x200
	scroll_tile_container = ScrollContainer.new()
	scroll_tile_container.position = Vector2(100, 1600)
	scroll_tile_container.size = Vector2(1080, 320)
	scroll_tile_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_tile_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll_tile_container)

	tile_container = HBoxContainer.new()
	tile_container.add_theme_constant_override("separation", 20)
	scroll_tile_container.add_child(tile_container)

	# 關卡選擇圖塊
	battle_tile = NavigationTile.create_level_select_tile("res://scripts/scenes/level_selection.tscn")
	battle_tile.size = Vector2(200, 200)
	battle_tile.position = Vector2(0, 0)
	tile_container.add_child(battle_tile)
	
	# 商店圖塊
	shop_tile = NavigationTile.create_shop_tile("res://scripts/scenes/shop_scene.tscn")
	shop_tile.size = Vector2(200, 200)
	shop_tile.position = Vector2(500, 0)
	tile_container.add_child(shop_tile)
	
	# 構築圖塊
	deck_tile = NavigationTile.create_deck_tile("res://scripts/scenes/deck_scene.tscn")
	deck_tile.size = Vector2(200, 200)
	deck_tile.position = Vector2(700, 0)
	tile_container.add_child(deck_tile)
	
	# 設定圖塊
	settings_tile = NavigationTile.create_settings_tile("res://scripts/scenes/settings_scene.tscn")
	settings_tile.size = Vector2(200, 200)
	settings_tile.position = Vector2(900, 0)
	tile_container.add_child(settings_tile)

func _on_start_tile_dropped(dropped_tile):
	print("Start tile dropped: ", dropped_tile)
