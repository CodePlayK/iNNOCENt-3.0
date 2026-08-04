extends BaseState

func enter():
	super.enter()
	EventBus._player_into_lock_state()
	return
