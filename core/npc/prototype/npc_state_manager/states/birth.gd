extends NpcsCombatState
@onready var create_character_box: Component = %CreateCharacterBox

func enter():
	npc.velocity=Vector2.ZERO
	create_character_box.create_character_box()
	npc.set_visible(true)
	super.enter()
	await npc.aniplayer.animation_finished
	if state_manager.current_state==self:
		return state_manager.running_state
	return
	
func exit(state:NpcsBaseState):
	return
