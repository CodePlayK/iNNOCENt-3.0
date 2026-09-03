extends CombatAirState
@export_group("debug")
## 打印从顶点过渡切入下落的日志
@export var toptrans2fall: bool = false


func is_animation_play():
	return not player.is_on_floor()


func enter() -> BaseState:
	super.enter()
	if not player.is_on_floor():
		await player.aniplayer.animation_finished
		if state_manager.current_state == self:
			if toptrans2fall:
				Debug.dprintwarn(DebugCT.dp("[toptrans]切换[fall_state]", self))
			return combatfall_state
	else:
		return combatidle_state
	return null


func after_physics_process(_delta: float) -> BaseState:
	if player.is_on_floor():
		return combatlanding_state
	return null
