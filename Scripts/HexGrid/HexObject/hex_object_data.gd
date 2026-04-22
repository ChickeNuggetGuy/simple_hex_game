extends Resource
class_name HexObjectData

@export var object_id : int
@export var object_name : String
@export var object_description : String
@export var object_portrait : Texture2D



@export var components : Array[HexObjectComponent]

func _init(n: String = "", d: String = "", p: Texture2D = null) -> void:
	object_name = n
	object_description = d
	object_portrait = p

func get_component(comp_name : String) -> HexObjectComponent:
	for comp in components:
		if comp.get_component_name() == comp_name:
			return comp
	return null
