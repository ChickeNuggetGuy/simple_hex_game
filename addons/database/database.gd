@tool
extends EditorPlugin

var _window_instance: HexDBWindow

func _enter_tree() -> void:
	_window_instance = HexDBWindow.new()
	_window_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	EditorInterface.get_editor_main_screen().add_child(_window_instance)
	_make_visible(false)

func _exit_tree() -> void:
	if _window_instance:
		_window_instance.queue_free()

func _has_main_screen() -> bool: return true
func _make_visible(visible: bool) -> void:
	if _window_instance: _window_instance.visible = visible
func _get_plugin_name() -> String: return "Hex Database"
func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_base_control().get_theme_icon("Object", "EditorIcons")
