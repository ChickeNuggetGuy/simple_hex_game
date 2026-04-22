extends Resource
class_name HexObjectData

@export var object_scene : PackedScene = preload("res://Data/Units/Test Unit/test_unit.tscn")
@export var object_name : String
@export var object_description : String
@export var object_portrait : Texture2D


func _init(name : String, desc: String, portrait : Texture2D) -> void:
	object_name = name
	object_description = desc
	object_portrait = portrait
