extends AirState
## 上升速度衰减到 max_velocity_y × 该比例时，切入顶点过渡（toptrans）
@export var toptrans_threshold: float = .1
@export_group("debug")
## 打印从上升切入顶点过渡的日志
@export var lift2toptrans: bool = false
## 打印从上升切入下落的日志
@export var lift2fall: bool = false


func is_animation_play():
	return player.velocity.y <= 0 and not player.is_on_floor()


func enter():
	if player.velocity.y <= 0 and not player.is_on_floor():
		PlayerState.max_height = 0
	elif player.velocity.y > -player.max_velocity_y * toptrans_threshold and not player.is_on_floor():
		return toptrans_state
	elif player.is_on_floor():
		return idle_state
	return


func after_physics_process(_delta: float) -> BaseState:
	if player.is_on_floor():
		return landing_state
	if player.velocity.y > -player.max_velocity_y * toptrans_threshold:
		if lift2toptrans:
			Debug.dprintwarn(DebugCT.dp("[lift]切换[toptrans_state]", self))
		return toptrans_state
	if player.velocity.y > 0:
		if lift2fall:
			Debug.dprintwarn(DebugCT.dp("[lift]切换[fallstate]", self))
		return fall_state
	return null
