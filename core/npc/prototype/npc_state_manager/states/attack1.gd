extends NpcsAttackState
## 本段攻击变色/透明过渡的总时长（秒）
@export var colored_time: float
## 前半段变透明所占比例（0~1）；后半段用 1 - 该值恢复不透明
@export var transparent_ratio: float


func enter():
	super.enter()
	tween = npc.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(npc, "modulate", Color("ffffff2a"), colored_time * transparent_ratio)
	tween.tween_property(npc, "modulate", Color("ffffffff"), colored_time * (1 - transparent_ratio))
	await tween.finished
	if tween:
		tween.kill()
	return


func exit(state: NpcsBaseState):
	if tween:
		tween.kill()
	npc.modulate = Color("ffffffff")
	super.exit(state)
