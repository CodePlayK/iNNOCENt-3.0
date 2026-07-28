extends NpcsCombatState

func enter():
	npc.set_visible(true)
	super.enter()
	await npc.aniplayer.animation_finished
	if state_manager.current_state==self:
		return state_manager.running_state
	return
