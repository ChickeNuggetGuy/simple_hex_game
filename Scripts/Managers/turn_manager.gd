extends Manager
class_name TurnManager

var turns : Dictionary[TeamHolder, Turn]
var current_team_turn : TeamHolder 
var current_overall_turn : int = 0


func get_manager_name() -> String: return "TurnManager"


func _setup():
	pass


func _execute():
	pass


func process_current_turn():
	if not current_team_turn:
		push_error("Current Team turn null")
		return
	
	if not turns.keys().has(current_team_turn):
		push_error("Current Team turn null")
		return
	
	turns[current_team_turn].process


func request_end_of_turn():
	#TODO: Implement turn system in its entirty
	pass
