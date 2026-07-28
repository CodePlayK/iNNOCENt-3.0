extends CombatState
class_name behit

func exit(state:BaseState):
	super.exit(state)
	PlayerState.player_be_hitting=false
	PlayerState.dense_success_flag=false


