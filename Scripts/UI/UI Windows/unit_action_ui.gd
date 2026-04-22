extends UIWindow
class_name UnitActionUI


@export var unit_name_label : Label
@export var unit_portait_rect : TextureRect
@export var unit_action_ui_holder : Control

var selected_unit : Unit

func get_ui_name() -> String: return "UnitActionUI"


func _setup(ui_manager : UIManager):
	
	var input_manager : InputManager = GameManager.get_manager("InputManager")
	if not input_manager:
		push_error("Could not Find input manager!")
		return
	
	if input_manager and not input_manager.selected_unit_changed.is_connected(input_manager_unit_selected):
		input_manager.selected_unit_changed.connect(input_manager_unit_selected)
	
	refresh_ui_call()

func _show():
	pass

func _hide():
	pass


func _refresh_ui():
	print("RAH")
	if selected_unit:
		if unit_name_label:
			unit_name_label.text = selected_unit.unit_data.object_name
		
		if unit_portait_rect:
			unit_portait_rect.texture = selected_unit.unit_data.object_portrait
		

func input_manager_unit_selected(selected_unit : Unit):
	self.selected_unit = selected_unit
	refresh_ui_call()
