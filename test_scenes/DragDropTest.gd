# DragDropTest.gd - 拖放系統測試場景
extends Node2D

# 測試圖塊和投放區域
var battle_tile: NavigationTile
var shop_tile: NavigationTile
var deck_tile: NavigationTile
var settings_tile: NavigationTile

var main_drop_zone: DropZone
var secondary_drop_zone: DropZone

func _ready():
	print("===========================================")
	print("=== 九重運命 - 拖放系統測試 ===")
	print("===========================================")
	
	# 等待一幀確保所有系統載入完成
	await get_tree().process_frame
	
	# 檢查依賴系統
	check_dependencies()
	
	# 創建測試UI
	create_test_ui()
	
	# 連接訊號
	connect_signals()
	
	print("\n=== 測試說明 ===")
	print("1. 拖拽下方的功能圖塊到上方的投放區域")
	print("2. 綠色高亮表示可以投放，紅色表示不可以")
	print("3. 成功投放會有動畫效果和粒子")
	print("4. 按 R 重置測試，ESC 退出")
	print("===========================================")

# 檢查系統依賴
func check_dependencies():
	print("\n--- 檢查系統依賴 ---")
	
	# 檢查 DragDropManager
	var ddm = get_node_or_null("/root/DragDropManager")
	if ddm:
		print("✅ DragDropManager 已載入")
	else:
		print("❌ DragDropManager 未載入")
	
	# 檢查其他系統
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		print("✅ EventBus 已載入")
	else:
		print("❌ EventBus 未載入")

# 創建測試UI
func create_test_ui():
	print("\n--- 創建測試UI ---")
	
	# 創建背景
	create_background()
	
	# 創建投放區域
	create_drop_zones()
	
	# 創建功能圖塊
	create_navigation_tiles()
	
	# 創建說明文字
	create_instructions()

# 創建背景
func create_background():
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0.1, 0.1, 0.15, 1.0)  # 深藍色背景
	add_child(bg)

# 創建投放區域
func create_drop_zones():
	# 主要投放區域（接受導航圖塊）
	main_drop_zone = DropZone.new()
	main_drop_zone.size = Vector2(400, 300)
	main_drop_zone.position = Vector2(340, 200)
	main_drop_zone.zone_type = "main_navigation"
	main_drop_zone.set_accepted_types(["navigation"])
	add_child(main_drop_zone)
	
	# 次要投放區域（只接受特定類型）
	secondary_drop_zone = DropZone.new()
	secondary_drop_zone.size = Vector2(300, 200)
	secondary_drop_zone.position = Vector2(390, 550)
	secondary_drop_zone.zone_type = "secondary"
	secondary_drop_zone.set_accepted_types(["battle", "shop"])  # 只接受戰鬥和商店
	add_child(secondary_drop_zone)
	
	print("✅ 投放區域已創建")

# 創建導航圖塊
func create_navigation_tiles():
	# 戰鬥圖塊
	battle_tile = NavigationTile.create_battle_tile("res://scenes/BattleScene.tscn")
	battle_tile.size = Vector2(200, 200)
	battle_tile.position = Vector2(100, 1400)
	add_child(battle_tile)
	
	# 商店圖塊
	shop_tile = NavigationTile.create_shop_tile("res://scenes/ShopScene.tscn")
	shop_tile.size = Vector2(200, 200)
	shop_tile.position = Vector2(320, 1400)
	add_child(shop_tile)
	
	# 構築圖塊
	deck_tile = NavigationTile.create_deck_tile("res://scenes/DeckScene.tscn")
	deck_tile.size = Vector2(200, 200)
	deck_tile.position = Vector2(540, 1400)
	add_child(deck_tile)
	
	# 設定圖塊
	settings_tile = NavigationTile.create_settings_tile("res://scenes/SettingsScene.tscn")
	settings_tile.size = Vector2(200, 200)
	settings_tile.position = Vector2(760, 1400)
	add_child(settings_tile)
	
	print("✅ 導航圖塊已創建")

# 創建說明文字
func create_instructions():
	# 標題
	var title = Label.new()
	title.text = "九重運命 - 拖放系統測試"
	title.position = Vector2(540, 50)
	title.size = Vector2(400, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)
	
	# 主投放區標籤
	var main_label = Label.new()
	main_label.text = "主投放區域\n(接受所有導航圖塊)"
	main_label.position = Vector2(340, 150)
	main_label.size = Vector2(400, 50)
	main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_label.add_theme_font_size_override("font_size", 16)
	main_label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(main_label)
	
	# 次投放區標籤
	var secondary_label = Label.new()
	secondary_label.text = "次投放區域\n(只接受戰鬥和商店)"
	secondary_label.position = Vector2(390, 520)
	secondary_label.size = Vector2(300, 40)
	secondary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	secondary_label.add_theme_font_size_override("font_size", 14)
	secondary_label.add_theme_color_override("font_color", Color.CYAN)
	add_child(secondary_label)
	
	# 操作說明
	var instructions = Label.new()
	instructions.text = "操作說明：拖拽下方圖塊到上方投放區域\nR 鍵重置 | ESC 鍵退出"
	instructions.position = Vector2(340, 900)
	instructions.size = Vector2(400, 100)
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	add_child(instructions)

# 連接訊號
func connect_signals():
	# 連接 DragDropManager 的訊號
	if DragDropManager:
		DragDropManager.tile_drag_started.connect(_on_tile_drag_started)
		DragDropManager.tile_drag_ended.connect(_on_tile_drag_ended)
		DragDropManager.navigation_requested.connect(_on_navigation_requested)
	
	# 連接投放區域的訊號
	main_drop_zone.tile_dropped.connect(_on_main_zone_dropped)
	secondary_drop_zone.tile_dropped.connect(_on_secondary_zone_dropped)
	
	print("✅ 訊號已連接")

# === 訊號處理方法 ===

func _on_tile_drag_started(tile_data: Dictionary, source_scene: String):
	print("[測試] 開始拖拽：", tile_data.get("type", "unknown"), " | 完整資料：", tile_data)

func _on_tile_drag_ended(tile_data: Dictionary, drop_zone, success: bool):
	var zone_name = drop_zone.zone_type if drop_zone else "無"
	var accepted_types = drop_zone.accepted_tile_types if drop_zone else []
	print("[測試] 拖拽結束：", tile_data.get("type", "unknown"), " -> ", zone_name, " (成功:", success, ")")
	print("    投放區域接受類型：", accepted_types, " | 圖塊完整資料：", tile_data)

func _on_navigation_requested(target_scene: String, tile_type: String):
	print("[測試] 請求導航：", tile_type, " -> ", target_scene)
	
	# 在測試中，我們不實際切換場景，而是顯示消息
	show_navigation_message(target_scene, tile_type)

func _on_main_zone_dropped(tile_data: Dictionary):
	print("[測試] 主區域接收投放：", tile_data)
	create_success_message("成功投放到主區域！", main_drop_zone.position)

func _on_secondary_zone_dropped(tile_data: Dictionary):
	print("[測試] 次區域接收投放：", tile_data)
	create_success_message("成功投放到次區域！", secondary_drop_zone.position)

# === 輔助方法 ===

# 顯示導航消息
func show_navigation_message(scene_path: String, tile_type: String):
	var message = Label.new()
	message.text = "導航請求：" + tile_type + "\n目標：" + scene_path
	message.position = Vector2(400, 800)
	message.size = Vector2(280, 80)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 14)
	message.add_theme_color_override("font_color", Color.GREEN)
	add_child(message)
	
	# 3秒後消失
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(message.queue_free)

# 創建成功消息
func create_success_message(text: String, pos: Vector2):
	var message = Label.new()
	message.text = text
	message.position = pos + Vector2(50, -30)
	message.size = Vector2(200, 30)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 16)
	message.add_theme_color_override("font_color", Color.YELLOW)
	add_child(message)
	
	# 動畫效果
	var tween = create_tween()
	tween.tween_property(message, "position:y", message.position.y - 50, 1.0)
	tween.parallel().tween_property(message, "modulate:a", 0.0, 1.0)
	tween.tween_callback(message.queue_free)

# === 輸入處理 ===

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC
		print("\n[測試] 退出測試")
		get_tree().quit()
	
	elif event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_R):  # R
		print("\n[測試] 重置測試場景")
		get_tree().reload_current_scene()

# === 除錯資訊 ===

func _process(_delta):
	# 每秒顯示一次除錯資訊
	if (Time.get_ticks_msec() % 2000) < 16:  # 大約每2秒
		show_debug_info()

func show_debug_info():
	if DragDropManager:
		var debug_info = DragDropManager.get_debug_info()
		if debug_info.is_dragging:
			print("[除錯] 拖拽中：", debug_info.dragging_tile_type, " | 投放區域數量：", debug_info.drop_zones_count)