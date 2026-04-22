extends UIWindow
class_name UnitActionUI


@export var unit_name_label : Label
@export var unit_portait_rect : TextureRect
@export var unit_action_ui_holder : Control
@export var action_button_scene : PackedScene

var action_buttons : Array[ActionButtonUI] = []

var selected_unit : Unit

func get_ui_name() -> String: return "UnitActionUI"


func _setup(ui_manager : UIManager):
	
	var unit_manager : UnitManager = GameManager.get_manager("UnitManager")
	if not unit_manager:
		push_error("Could not Find unit manager!")
		return
	
	if unit_manager and not unit_manager.selected_unit_changed.is_connected(unit_manager_unit_selected):
		unit_manager.selected_unit_changed.connect(unit_manager_unit_selected)
	
	refresh_ui_call()

func _show():
	pass

func _hide():
	pass


func _refresh_ui():
	var ui_manager : UIManager = GameManager.get_manager("UIManager")
	if selected_unit:
		if unit_name_label:
			unit_name_label.text = selected_unit.object_data.object_name
		
		if unit_portait_rect:
			unit_portait_rect.texture = selected_unit.object_data.object_portrait
		
		var action_holder : UnitActionHolder = selected_unit.object_data.get_component("UnitActionHolder")
		
		if not action_holder:
			return
		
		for action_button in action_buttons:
			action_button.queue_free()
		
		action_buttons.clear()
		
		for action in action_holder.actions:
			if not action.show_in_ui:
				continue
			var action_button : ActionButtonUI = create_action_button(action, ui_manager)
			if action_button:
				action_buttons.append(action_button)


func create_action_button(action : Action, ui_manager : UIManager) -> ActionButtonUI:
	var action_ui = action_button_scene.instantiate()
	
	if not action_ui:
		return null
	
	var action_button : ActionButtonUI = action_ui as ActionButtonUI
	
	if not action_button:
		return null
	
	action_button.set_action(action)
	unit_action_ui_holder.add_child(action_button)
	action_button.setup_call(self, ui_manager )
	return action_button

func unit_manager_unit_selected(selected_unit : Unit, old_unit : Unit):
	self.selected_unit = selected_unit
	refresh_ui_call()
