extends Manager
class_name TeamManager

@export var number_of_teams : int = 2
@export var player_team = 0

var _teams : Dictionary[int, TeamHolder]

func get_manager_name() -> String: return "TeamManager"


func _setup():
	for i in range(number_of_teams):
		create_team_holder("Team:" + str(i),i)
	pass


func _execute():
	pass


func create_team_holder( name : String,team_number : int  = -1) -> TeamHolder:
	
	if team_number == -1 or _teams.has(team_number):
		push_error("Team cnot created! Team number is invalid")
		return null
	
	
	var new_team_holder = TeamHolder.new(team_number, name)
	new_team_holder.name = name
	add_child(new_team_holder)
	_teams[team_number] = new_team_holder
	return new_team_holder


func get_team_holder(team_affiliation: int) -> TeamHolder:
	if not _teams.has(team_affiliation):
		return null
	return _teams[team_affiliation]
