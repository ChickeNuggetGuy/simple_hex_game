extends UIElement
class_name ActionButtonUI

@export var button : Button

var action : Action


func _setup( ui_manager :UIManager):
	
	if not button:
		push_error("Button not assigned in inspector!")
		return
	elif not button.pressed.is_connected(button_on_pressed):
		button.pressed.connect(button_on_pressed)


func set_action(action: Action):
	self.action = action
	button.text = action.get_action_name()


func button_on_pressed():
	if not action:
		push_error("action is null!")
		return
	
	var unit_action_manager : UnitActionManager = GameManager.get_manager("UnitActionManager")
	if not unit_action_manager:
		push_error("Could not find Unit action manager!")
		return
	
	unit_action_manager.set_selected_action(action)
