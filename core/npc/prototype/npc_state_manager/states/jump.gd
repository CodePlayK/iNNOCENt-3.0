extends NpcsCombatState
## 跳跃水平速度（当前实现用 Tween 位移，此值作配置预留）
@export var speed_x: float
## 跳跃竖直速度（当前实现用 Tween 位移，此值作配置预留）
@export var speed_y: float
## 跳到目标巡逻点所用时间（秒）
@export var time: float


func enter():
	super.enter()
	if npc.patrol_area == null or npc.patrol_area.patrol_list.size() < 2:
		state_manager.state2state(chase_state, self)
		return
	var target = npc.patrol_area.patrol_list[1].patrol_left
	var tween = npc.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(npc, "global_position", Vector2(target.global_position.x, npc.global_position.y), time)
	tween.parallel().tween_property(npc, "global_position", Vector2(npc.global_position.x, target.global_position.y), time)
	await tween.finished
	tween.kill()
	state_manager.state2state(chase_state, self)
	return
