extends NpcsCombatState
@export var speed_x:float
@export var speed_y:float
@export var time:float
func enter():
	super.enter()
	var tween = npc.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(npc,"global_position",Vector2(npc.patrol_area.patrol_list[1].patrol_left.global_position.x,npc.global_position.y),time)
	tween.parallel().tween_property(npc,"global_position",Vector2(npc.global_position.x,npc.patrol_area.patrol_list[1].patrol_left.global_position.y),time)
	await tween.finished
	tween.kill()
	state_manager.state2state(chase_state,self)
	return
