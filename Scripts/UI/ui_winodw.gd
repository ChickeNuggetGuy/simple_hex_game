@abstract
extends UIElement
class_name UIWindow

@export var visual : Control
@export var start_hidden : bool = false

var ui_elements : Array[UIElement]
var _is_shown : bool
var is_shown : bool:
	get:
		return _is_shown
	set(value):
		_is_shown = value
		refresh_ui_call()
		



@abstract func get_ui_name() -> String

func setup_call(parent : UIWindow, ui_manager : UIManager) -> void:
	super.setup_call(parent, ui_manager)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if ui_manager == null:
		push_error("UI Manager reference is null!")
		return
	
	if  not ui_manager.ui_windows.has(get_ui_name()):
		ui_manager.ui_windows[get_ui_name()] = self
	
	print("setup: " + name)

	ui_elements.clear()
	_collect_owned_ui_elements(self)

	for element in ui_elements:
		if element != null:
			await element.setup_call(self, ui_manager)

	if start_hidden:
		hide_call()
	else:
		show_call()


func show_call():
	if not visual:
		push_error("Visual is null!")
		return
	
	refresh_ui_call()
	_show()
	visual.show()
	is_shown = true

@abstract func _show()

func refresh_ui_call():
	if is_shown:
		_refresh_ui()


@abstract func _refresh_ui()


func hide_call():
	if not visual:
		push_error("Visual is null!")
		return
	_hide()
	is_shown = false

@abstract func _hide()


func _collect_owned_ui_elements(node: Node) -> void:
	for child in node.get_children():
		if child is UIWindow:
			var child_window := child as UIWindow

			if not ui_elements.has(child_window):
				ui_elements.append(child_window)

			continue

		if child is UIElement:
			var child_element := child as UIElement

			if not ui_elements.has(child_element):
				ui_elements.append(child_element)

		_collect_owned_ui_elements(child)
