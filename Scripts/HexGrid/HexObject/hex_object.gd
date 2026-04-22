@abstract
extends AnimatableBody3D
class_name HexObject

@export var visual : Node3D
@export var team_afliliation : int


var hex_cell : HexCell


func setup_call(team : TeamHolder):
	team.add_unit(self)
	_setup()


@abstract func _setup()
