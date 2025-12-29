extends Node2D

func _ready():
    print("[BattleScene] 載入戰鬥場景，主節點：", self, " parent：", get_parent())
    setup_ui()

func setup_ui():
    pass