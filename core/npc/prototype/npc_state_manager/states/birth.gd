extends NpcsCombatState


func enter():
	npc.velocity = Vector2.ZERO
	npc.set_visible(true)
	super.enter()
	await npc.aniplayer.animation_finished
	if state_manager.current_state == self:
		return state_manager.running_state
	return


func exit(_state: NpcsBaseState):
	return
