extends Node

const SAVE_PATH = "user://save_data.json"

var data: Dictionary = {}
var _is_loaded: bool = false

func _ready():
	print("[SaveManager] 初始化存檔系統...")
	load_save()
	print("[SaveManager] 存檔系統就緒，存檔路徑：", ProjectSettings.globalize_path(SAVE_PATH))

# ── 讀檔 ──────────────────────────────────────────────────────────────────────

func load_save():
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] 找不到存檔，建立預設存檔（首次啟動）")
		data = _default_save()
		save()
		_is_loaded = true
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("[SaveManager] 無法開啟存檔：" + SAVE_PATH)
		data = _default_save()
		_is_loaded = true
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("[SaveManager] 存檔 JSON 格式損毀，使用預設值（行 " + str(json.get_error_line()) + "）")
		data = _default_save()
		_is_loaded = true
		return

	data = json.get_data()
	_migrate()
	_is_loaded = true
	print("[SaveManager] 存檔載入成功")
	print("  - 英雄等級：", get_value("hero.level", 1))
	print("  - 已解鎖關卡：", get_value("progress.levels_unlocked", []))
	print("  - 金幣：", get_value("resources.gold", 0))

# ── 寫檔 ──────────────────────────────────────────────────────────────────────

func save():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] 無法寫入存檔：" + SAVE_PATH)
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[SaveManager] 存檔已儲存")

# ── 讀取 helper（支援 "." 路徑，例如 "hero.level"）────────────────────────────

func get_value(path: String, default = null):
	var keys = path.split(".")
	var current = data
	for key in keys:
		if not current is Dictionary or not current.has(key):
			return default
		current = current[key]
	return current

# ── 寫入 helper（只改記憶體，需手動呼叫 save() 才寫入硬碟）──────────────────

func set_value(path: String, value):
	var keys = path.split(".")
	var current = data
	for i in range(keys.size() - 1):
		if not current.has(keys[i]) or not current[keys[i]] is Dictionary:
			current[keys[i]] = {}
		current = current[keys[i]]
	current[keys[-1]] = value

# ── 版本升遷（每個 if v < N 區塊負責從上一版升到 N）──────────────────────────

func _migrate():
	var v: int = data.get("version", 1)
	var original_v: int = v
	# v1 是基準版本，未來在這裡依序加：
	# if v < 2:
	#     data["version"] = 2; v = 2
	if v != original_v:
		save()
		print("[SaveManager] 存檔已從 v", original_v, " 升遷至 v", v)

# ── 預設存檔（新遊戲初始狀態）────────────────────────────────────────────────

func _default_save() -> Dictionary:
	var today: String = Time.get_date_string_from_system()
	return {
		"version": 1,
		"player": {
			"name": "玩家",
			"id": "P%08x" % (randi() ^ Time.get_ticks_msec()),
			"created_at": today
		},
		"resources": {
			"gold": 0,
			"gems": 0,
			"shards": 0
		},
		"collection": {
			"heroes": [
				{ "id": "H001", "level": 1, "obtained_at": today }
			],
			"blocks": [
				{ "id": "B001", "obtained_at": today },
				{ "id": "B002", "obtained_at": today },
				{ "id": "B003", "obtained_at": today },
				{ "id": "B004", "obtained_at": today },
				{ "id": "B005", "obtained_at": today },
				{ "id": "B101", "obtained_at": today },
				{ "id": "B102", "obtained_at": today },
				{ "id": "B201", "obtained_at": today }
			]
		},
		"decks": [
			{
				"name": "預設卡組",
				"hero_id": "H001",
				"block_ids": ["B001", "B002", "B003", "B004", "B005", "B101", "B102", "B201"]
			}
		],
		"active_deck_index": 0,
		"progress": {
			"levels": {
				"level_000": { "status": "completed", "stars": 3, "clear_count": 1, "cleared_at": today },
				"level_001": { "status": "unlocked" },
				"level_002": { "status": "locked" }
			}
		},
		"settings": {
			"bgm_volume": 1.0,
			"sfx_volume": 1.0,
			"language": "zh"
		}
	}

# ── 除錯用：F8 重置存檔（僅 debug build）────────────────────────────────────

func _input(event):
	if OS.is_debug_build() and event is InputEventKey:
		if event.pressed and event.keycode == KEY_F8:
			data = _default_save()
			save()
			print("[SaveManager] [DEBUG] 存檔已重置為預設值")

# ── 除錯用：印出完整存檔內容 ──────────────────────────────────────────────────

func debug_print():
	print("[SaveManager] ===== 當前存檔內容 =====")
	print(JSON.stringify(data, "\t"))
	print("[SaveManager] =============================")
