extends HexObjectData
class_name UnitData



@export var move_speed: int

@export var current_health : int
@export var max_health : int

@export var components : Array[HexObjectComponent]


func _init(unit_name : String, desc: String,portrait : Texture2D, move_speed : int, max_health : int) -> void:
	super._init(unit_name, desc, portrait)
	self.move_speed = move_speed
	self.max_health = max_health
	current_health = max_health

static func generate_random_unit_data() -> UnitData:
	var portrait : PlaceholderTexture2D = PlaceholderTexture2D.new()
	portrait.size = Vector2i(50,50)
	
	return UnitData.new(
		"John Doe", "Standard Settler Unit", portrait, randi_range(15, 35), randi_range(65, 100)
	)
