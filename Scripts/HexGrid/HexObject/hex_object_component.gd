@abstract
extends Resource
class_name HexObjectComponent

var parent : HexObject 

@abstract func get_component_name() -> String


func setup_call(parent : HexObject):
	self.parent = parent
	_setup()

@abstract func _setup()
