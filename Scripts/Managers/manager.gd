@abstract 
extends Node
class_name Manager


func _init() -> void:
	add_to_group("managers")

func setup_call():
	_setup()



func execute_call():
	_execute()

@abstract func get_manager_name() -> String
@abstract func _setup()
@abstract func _execute()
