extends Manager
class_name UIManager

@export var ui_root : Control

var top_most_ui_windows
var ui_windows : Dictionary [String, UIWindow]

func get_manager_name() -> String: return "UIManager"


func _setup():
	ui_windows.clear()
	

func _execute() -> void:
	if ui_root == null:
		push_warning("UIManager: ui_holder is null!")
		return
	await _setup_top_level_windows(ui_root)


func _setup_top_level_windows(node: Node) -> void:
	for child in node.get_children():
		if child is UIWindow:
			var window := child as UIWindow
			await window.setup_call(null, self)
			continue

		await _setup_top_level_windows(child)
