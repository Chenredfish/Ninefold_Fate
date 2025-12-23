# debug_state.gd - 調試腳本
# 在主菜單中按 F9 鍵可以查看當前狀態機的狀態

extends Control

func _ready():
    print("[Debug] Debug state monitor ready. Press F9 to see state info.")

func _input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F9:
            print_state_debug_info()

func print_state_debug_info():
    print("\n=== STATE MACHINE DEBUG INFO ===")
    
    # StateManager 信息
    if StateManager:
        print("StateManager: Available")
        print("- Game Scene State Machine: ", StateManager.game_scene_state_machine != null)
        
        if StateManager.game_scene_state_machine:
            var gsm = StateManager.game_scene_state_machine
            print("- Current State: ", gsm.get_current_state_id() if gsm.has_method("get_current_state_id") else "Unknown")
            print("- Scene Loading: ", gsm.scene_loading if "scene_loading" in gsm else "Unknown")
            print("- Current Scene: ", gsm.current_scene.name if gsm.current_scene else "None")
        
        print("- All State Machines: ", StateManager.get_state_machine_names())
    else:
        print("StateManager: Not available!")
    
    # EventBus 信息  
    if EventBus:
        print("EventBus: Available")
        # 檢查信號連接
        if EventBus.has_signal("scene_transition_requested"):
            var connections = EventBus.get_signal_connection_list("scene_transition_requested")
            print("- scene_transition_requested connections: ", connections.size())
        else:
            print("- scene_transition_requested signal: Not found")
    else:
        print("EventBus: Not available!")
    
    # 當前場景信息
    var current_scene = get_tree().current_scene
    print("Current Scene: ", current_scene.name if current_scene else "None")
    print("Scene Tree Root Children: ")
    for child in get_tree().root.get_children():
        print("  - ", child.name, " (", child.get_class(), ")")
    
    print("=== END DEBUG INFO ===\n")