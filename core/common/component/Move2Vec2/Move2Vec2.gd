extends Component
var obj
var astar_move

func on_master_ready(master:Master):
	obj = master.obj
	astar_move = obj.astar_move
	EventBus.move_2_vec2.connect(move)
	
func move(n:String,target:Vector2,time):
	if n!=obj.obj_name:return
	obj.astar.set_taget_position_mode(true,target)
	obj.state_manager.string2state("move",self)
