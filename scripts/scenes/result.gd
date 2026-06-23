extends Control

var main_info_area: Control
var result_detail_panel: Panel
var unified_confirm_grid: Control
var result_tile_container: ScrollContainer
var result_control_tile_container: ScrollContainer

var result_data: Dictionary = {}

const VALID_RESOURCES: Array = ["gold", "gems", "shards"]

func set_result_data(data: Dictionary) -> void:
	print("[ResultScene] 收到結算資料：", data)
	result_data = data
	_apply_rewards()
	_setup_ui()

func _apply_rewards() -> void:
	if result_data.get("battle_result") != "victory":
		return
	var level_id: String = result_data.get("level_id", "")
	var level_data: Dictionary = ResourceManager.level_database.get(level_id, {})
	var rewards: Array = level_data.get("rewards", [])
	for reward in rewards:
		var type: String = reward.get("type", "")
		if type not in VALID_RESOURCES:
			print("[ResultScene] 警告：不認識的獎勵類型 '%s'，略過" % type)
			continue
		var key: String = "resources." + type
		var current: int = SaveManager.get_value(key, 0)
		SaveManager.set_value(key, current + reward.get("amount", 0))
	SaveManager.save()

func _setup_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	main_info_area = Control.new()
	main_info_area.size = Vector2(1080, 1000)
	main_info_area.position = Vector2(0, 0)
	add_child(main_info_area)

	_create_background_area()
	_create_main_info_area()
	_create_confirm_grid()
	_create_tile_area()

func _create_background_area() -> void:
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0.1, 0.1, 0.2, 1.0)
	main_info_area.add_child(bg)

func _create_main_info_area() -> void:
	var is_victory: bool = result_data.get("battle_result", "") == "victory"

	var title = Label.new()
	title.text = "勝利！" if is_victory else "失敗..."
	title.position = Vector2(40, 60)
	title.size = Vector2(1000, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color",
		Color(1.0, 0.9, 0.2) if is_victory else Color(0.9, 0.3, 0.3))
	main_info_area.add_child(title)

	result_detail_panel = Panel.new()
	result_detail_panel.position = Vector2(90, 250)
	result_detail_panel.size = Vector2(900, 500)
	main_info_area.add_child(result_detail_panel)

	_create_panel_content(is_victory)

func _create_panel_content(is_victory: bool) -> void:
	_create_stars(is_victory)
	_create_rewards_section()
	_create_stats_section(is_victory)

func _create_stars(is_victory: bool) -> void:
	var level_id: String = result_data.get("level_id", "")
	var stars: int = SaveManager.get_value("progress.levels." + level_id + ".stars", 0) if is_victory and not level_id.is_empty() else 0
	var star_text: String = ""
	for i in range(3):
		star_text += "★" if i < stars else "☆"

	var label = Label.new()
	label.text = star_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 20)
	label.size = Vector2(900, 80)
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	result_detail_panel.add_child(label)

func _create_rewards_section() -> void:
	var section_title = Label.new()
	section_title.text = "獲得獎勵"
	section_title.position = Vector2(20, 115)
	section_title.size = Vector2(420, 40)
	section_title.add_theme_font_size_override("font_size", 24)
	section_title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	result_detail_panel.add_child(section_title)

	var div = ColorRect.new()
	div.position = Vector2(20, 155)
	div.size = Vector2(400, 2)
	div.color = Color(0.5, 0.5, 0.7, 0.5)
	result_detail_panel.add_child(div)

	var level_id: String = result_data.get("level_id", "")
	var level_data: Dictionary = ResourceManager.level_database.get(level_id, {})
	var rewards: Array = level_data.get("rewards", []) if result_data.get("battle_result") == "victory" else []
	var y: int = 168
	for reward in rewards:
		var label = Label.new()
		label.text = "・" + _reward_name(reward.get("type", "")) + "  +" + str(reward.get("amount", 0))
		label.position = Vector2(30, y)
		label.size = Vector2(400, 40)
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color.WHITE)
		result_detail_panel.add_child(label)
		y += 45

func _create_stats_section(is_victory: bool) -> void:
	var section_title = Label.new()
	section_title.text = "戰鬥數據"
	section_title.position = Vector2(470, 115)
	section_title.size = Vector2(420, 40)
	section_title.add_theme_font_size_override("font_size", 24)
	section_title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	result_detail_panel.add_child(section_title)

	var div = ColorRect.new()
	div.position = Vector2(460, 155)
	div.size = Vector2(420, 2)
	div.color = Color(0.5, 0.5, 0.7, 0.5)
	result_detail_panel.add_child(div)

	var stats: Array = [
		["結果", "勝利" if is_victory else "失敗"],
		["星級", "★★★" if is_victory else "—"],
	]
	var y: int = 168
	for stat in stats:
		var label = Label.new()
		label.text = "・" + stat[0] + "：" + stat[1]
		label.position = Vector2(480, y)
		label.size = Vector2(400, 40)
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color.WHITE)
		result_detail_panel.add_child(label)
		y += 45

func _create_confirm_grid() -> void:
	unified_confirm_grid = Control.new()
	unified_confirm_grid.position = Vector2(240, 800)
	unified_confirm_grid.size = Vector2(600, 600)
	add_child(unified_confirm_grid)

	var grid_bg = ColorRect.new()
	grid_bg.size = Vector2(600, 600)
	grid_bg.color = Color(0.2, 0.2, 0.3, 1.0)
	unified_confirm_grid.add_child(grid_bg)

	for i in range(3):
		for j in range(3):
			var drop_zone = DropZone.new()
			drop_zone.position = Vector2(j * 200, i * 200)
			drop_zone.size = Vector2(200, 200)
			drop_zone.set_accepted_types(["back_level", "main_menu", "confirm_level", "level_select"])
			unified_confirm_grid.add_child(drop_zone)
			drop_zone.modulate = Color(1.2, 1.2, 1.0, 1.0)
			drop_zone.tile_dropped.connect(_on_tile_dropped)

func _create_tile_area() -> void:
	result_tile_container = ScrollContainer.new()
	result_tile_container.position = Vector2(40, 1420)
	result_tile_container.size = Vector2(1000, 240)
	result_tile_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	result_tile_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(result_tile_container)
	result_tile_container.add_child(HBoxContainer.new())

	result_control_tile_container = ScrollContainer.new()
	result_control_tile_container.position = Vector2(40, 1660)
	result_control_tile_container.size = Vector2(1000, 240)
	result_control_tile_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	result_control_tile_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(result_control_tile_container)

	var control_container = HBoxContainer.new()
	control_container.add_theme_constant_override("separation", 20)
	result_control_tile_container.add_child(control_container)

	var main_menu_tile = NavigationTile.create_main_menu_tile("res://scripts/scenes/main_menu.tscn")
	main_menu_tile.size = Vector2(200, 200)
	control_container.add_child(main_menu_tile)

	var level_select_tile = NavigationTile.create_level_select_tile("res://scripts/scenes/level_selection.tscn")
	level_select_tile.size = Vector2(200, 200)
	control_container.add_child(level_select_tile)

func _on_tile_dropped(tile_data: Dictionary) -> void:
	print("[ResultScene] tile 投放：", tile_data)

func _reward_name(type: String) -> String:
	match type:
		"gold": return "金幣"
		"gems": return "寶石"
		_: return type
