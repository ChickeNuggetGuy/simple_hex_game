@abstract
extends Control
class_name UIElement
var parent_ui_window : UIWindow


func setup_call(parent : UIWindow, ui_manager :UIManager):
	parent_ui_window = parent
	_setup(ui_manager)


@abstract func _setup( ui_manager :UIManager)
