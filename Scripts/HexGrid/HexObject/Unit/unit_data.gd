extends HexObjectData
class_name UnitData



@export var move_speed: int

@export var current_health : int
@export var max_health : int




func _init(u_name: String = "", d: String = "", p: Texture2D = null, m_speed: int = 0, m_health: int = 0) -> void:
	super._init(u_name, d, p)
	self.move_speed = m_speed
	self.max_health = m_health
	self.current_health = m_health

static func generate_random_unit_data() -> UnitData:
	var portrait : PlaceholderTexture2D = PlaceholderTexture2D.new()
	portrait.size = Vector2i(50,50)
	
	return UnitData.new(
		"John Doe", "Standard Settler Unit", portrait, randi_range(15, 35), randi_range(65, 100)
	)


func try_get_unit_action(action_name : String):
	var unit_action_holder : UnitActionHolder = get_component("UnitActionHolder")
	if not unit_action_holder:
		print("failed to find UnitActionHolder")
		return null
	
	for action in unit_action_holder.actions:
		if action.get_action_name() == action_name:
			return action
	
	return null
	
