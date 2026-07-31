extends InteractiveState

func enter():
	super.enter()
	PlayerState.player_control_lock=true
	return
