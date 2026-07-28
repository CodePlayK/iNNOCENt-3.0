extends behit
@export var stiff_time=.3
@onready var stiff_timer: Timer = $StiffTimer
@onready var player_dense_suc_time_event: Node = %PlayerDenseSucTimeEvent

func enter():
	super.enter()
	player_dense_suc_time_event.add_time(1)
	player.hit_fx.emit_fx()
	PlayerState.dense_success_flag=true
	stiff_timer.start(stiff_time)
	return

func _on_stiff_timer_timeout():
	if state_manager.current_state!=self:return
	state_manager.state2state(PlayerState.get_last_normal_state(),self)

func exit(state:BaseState):
	super.exit(state)
	stiff_timer.stop()
