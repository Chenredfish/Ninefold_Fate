extends Node2D

func _ready():
	print("EventBus 可用: ", EventBus != null)
	print("ResourceManager 可用: ", ResourceManager != null)
	print("DebugManager 可用: ", DebugManager != null)
