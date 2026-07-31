extends NpcsAttackState
@export var colored_time:float
@export var transparent_ratio:float
func enter():
	super.enter()
	tween = npc.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(npc,"modulate",Color("ffffff2a"),colored_time*transparent_ratio)
	tween.tween_property(npc,"modulate",Color("ffffffff"),colored_time*(1-transparent_ratio))
	await tween.finished
	tween.kill()
	return
